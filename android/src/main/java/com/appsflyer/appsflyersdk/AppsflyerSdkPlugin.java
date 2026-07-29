package com.appsflyer.appsflyersdk;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.appsflyer.AppsFlyerLib;
import com.appsflyer.pluginbridge.handler.AppsFlyerRpcHandler;
import com.appsflyer.pluginbridge.model.RpcErrorCodes;
import com.appsflyer.pluginbridge.model.RpcResponse;
import com.appsflyer.pluginbridge.parser.JsonRpcRequestParser;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;

import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_FAILURE;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_PLUGIN_TAG;
import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_SUCCESS;

/**
 * AppsflyerSdkPlugin (Android)
 *
 * Full-RPC transport: the Dart layer sends a single {@code executeRpc} method call carrying
 * {@code {method, params}}, which is dispatched to {@link AppsFlyerRpcHandler} (from the
 * {@code com.appsflyer.pluginbridge} module). This mirrors the Cordova plugin's {@code executeRpc}
 * entry point.
 *
 * {@code init}, {@code start} and the invite-link methods are handled specially because the Flutter
 * public API bundles orchestration (SDK 7 session model, listener registration) that Cordova pushes
 * to app code. Every other method is forwarded generically to the bridge.
 *
 * SDK callbacks flow back through the bridge event notifier and are forwarded to the Dart
 * {@code callbacks} channel (Flutter's MethodChannel results cannot stream like Cordova's keepCallback).
 */
public class AppsflyerSdkPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {

    private static final String METHOD_EXECUTE_RPC = "executeRpc";

    private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());
    private ExecutorService rpcExecutor;

    private Context mContext;
    private Activity activity;

    private MethodChannel mMethodChannel;
    private EventChannel mEventChannel;

    private AppsFlyerRpcHandler rpcHandler;

    // af-events EventChannel sink. All SDK events are forwarded here; the Dart side routes each event
    // to the app callback that registered for it, so no native per-callback forwarding gates are needed.
    private EventChannel.EventSink eventSink;

    // RD-65582: buffer events that arrive before Dart subscribes (onListen), then replay on attach, so
    // an install-conversion event emitted before the stream is attached is not lost. Touched only on
    // the main thread (processBridgeEvent is posted there by createRpcEventNotifier; StreamHandler
    // callbacks also run on the main thread).
    private final List<String> pendingEvents = new ArrayList<>();

    private final PluginRegistry.NewIntentListener onNewIntentListener = intent -> {
        if (activity != null) {
            activity.setIntent(intent);
        }
        // SDK 7 subscribes to the activity lifecycle from init(), so warm-start VIEW intents are
        // resolved automatically once subscribeForDeepLink has been called. No explicit call needed.
        return false;
    };

    private final EventChannel.StreamHandler eventStreamHandler = new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink events) {
            eventSink = events;
            flushPendingEvents();
        }

        @Override
        public void onCancel(Object arguments) {
            eventSink = null;
        }
    };

    // ============================================================================
    // Plugin / channel lifecycle
    // ============================================================================

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        this.mContext = applicationContext;
        this.rpcExecutor = Executors.newSingleThreadExecutor();

        mMethodChannel = new MethodChannel(messenger, AppsFlyerConstants.AF_METHOD_CHANNEL);
        mMethodChannel.setMethodCallHandler(this);

        mEventChannel = new EventChannel(messenger, AppsFlyerConstants.AF_EVENTS_CHANNEL);
        mEventChannel.setStreamHandler(eventStreamHandler);
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
        AppsFlyerPurchaseConnector.INSTANCE.onAttachedToEngine(binding);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        if (mMethodChannel != null) {
            mMethodChannel.setMethodCallHandler(null);
            mMethodChannel = null;
        }
        if (mEventChannel != null) {
            mEventChannel.setStreamHandler(null);
            mEventChannel = null;
        }
        eventSink = null;
        pendingEvents.clear();
        AppsFlyerPurchaseConnector.INSTANCE.onDetachedFromEngine(binding);
        if (rpcExecutor != null) {
            rpcExecutor.shutdown();
            rpcExecutor = null;
        }
        rpcHandler = null;
        mContext = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addOnNewIntentListener(onNewIntentListener);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addOnNewIntentListener(onNewIntentListener);
        // No cache replay needed: the FlutterEngine and the Dart af-events subscription survive
        // activity config changes, so the EventSink stays attached and events keep flowing.
    }

    @Override
    public void onDetachedFromActivity() {
        // SDK 7: the GCD/conversion listener is owned by the engine-scoped RPC handler and
        // registered only during init(); it is intentionally not unregistered on Activity detach
        // (there is no re-arm on re-attach, and iOS has no equivalent). Cleanup happens with the
        // engine in onDetachedFromEngine and at process teardown.
        activity = null;
    }

    // ============================================================================
    // MethodChannel entry point (af-api)
    // ============================================================================

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (mContext == null) {
            Log.d(AF_PLUGIN_TAG, LogMessages.ACTIVITY_NOT_ATTACHED_TO_ENGINE);
            result.error("NOT_ATTACHED", "The plugin is not attached to a Flutter engine", null);
            return;
        }
        if (METHOD_EXECUTE_RPC.equals(call.method)) {
            executeRpc(call, result);
        } else {
            result.notImplemented();
        }
    }

    /**
     * Single RPC entry point. Unwraps {@code {method, params}} and routes it: {@code init}/{@code start}
     * and the invite-link methods run the plugin-side orchestration; everything else is forwarded to
     * the bridge as-is.
     */
    @SuppressWarnings("unchecked")
    private void executeRpc(MethodCall call, Result result) {
        Object arguments = call.arguments;
        if (!(arguments instanceof Map)) {
            result.error("INVALID_PARAMETERS", "executeRpc requires a {method, params} map", null);
            return;
        }
        Map<String, Object> map = (Map<String, Object>) arguments;
        String method = (String) map.get("method");
        if (method == null || method.isEmpty()) {
            result.error("INVALID_PARAMETERS", "executeRpc requires a 'method'", null);
            return;
        }

        JSONObject params = new JSONObject();
        Object rawParams = map.get("params");
        if (rawParams instanceof Map) {
            params = new JSONObject((Map<String, Object>) rawParams);
        }

        try {
            switch (method) {
                case AppsFlyerConstants.RPC_METHOD_INIT:
                    initFromRpc(params, result);
                    break;
                case AppsFlyerConstants.RPC_METHOD_START:
                    // SDK 7: call start() directly (mirrors the Cordova bridge). The SDK handles
                    // session readiness internally; deferring start() until an onSessionReady signal
                    // deadlocks, because that signal only fires once start() has run. The result is
                    // returned on the per-call reply (same path as logEvent), driven by the
                    // params.awaitResponse flag the Dart layer sets when onSuccess/onError is passed.
                    dispatchRpc(AppsFlyerConstants.RPC_METHOD_START, params, result, null);
                    break;
                case AppsFlyerConstants.RPC_METHOD_GENERATE_INVITE_LINK:
                    generateInviteLinkFromRpc(params, result);
                    break;
                case AppsFlyerConstants.RPC_METHOD_SET_APP_INVITE_ONE_LINK:
                    setAppInviteOneLinkFromRpc(params, result);
                    break;
                default:
                    dispatchRpc(method, params, result, null);
                    break;
            }
        } catch (Throwable t) {
            Log.e(AF_PLUGIN_TAG, "executeRpc error for '" + method + "': " + t.getMessage(), t);
            result.error("UNEXPECTED_ERROR", t.getMessage(), null);
        }
    }

    // ============================================================================
    // RPC handler + notifier
    // ============================================================================

    private synchronized AppsFlyerRpcHandler getOrCreateRpcHandler() {
        if (rpcHandler == null) {
            // SDK 7 delivers Unified Deep Linking via its ActivityLifecycleCallbacks, registered
            // during init(). On a cold start the launcher Activity is already resumed by the time a
            // plugin calls init() from Dart, so the SDK only replays that first onResume (and thus
            // resolves the launch intent -> onDeepLinking) when init() receives an *Activity* context
            // (see AndroidLifecycleManagerImpl.registerLifecycleListener). Passing the Application
            // context skips that catch-up and cold-start deep links never fire. Prefer the Activity
            // (matching the Cordova bridge); fall back to the app context only if none is attached.
            Context rpcContext = (activity != null) ? activity : mContext;
            rpcHandler = new AppsFlyerRpcHandler(
                    rpcContext,
                    createRpcEventNotifier(),
                    AppsFlyerLib.getInstance(),
                    new JsonRpcRequestParser()
            );
        }
        return rpcHandler;
    }

    /**
     * Bridge notifier. Events fire on the SDK's callback thread, so we hop to the main thread before
     * touching the Flutter channels.
     */
    private Function1<String, Unit> createRpcEventNotifier() {
        return eventJson -> {
            uiThreadHandler.post(() -> processBridgeEvent(eventJson));
            return Unit.INSTANCE;
        };
    }

    private void processBridgeEvent(String eventJson) {
        try {
            JSONObject event = new JSONObject(eventJson);
            String name = event.optString("event", "");

            // All events are forwarded to the af-events stream; the Dart side routes each event by
            // its "id" to the app callback that registered for it (session-ready is observer-only:
            // start() is called directly, so readiness does not gate it).
            if (AppsFlyerConstants.RPC_EVENT_SESSION_READY.equals(name)) {
                deliverEvent(buildCallListenerArgs(AppsFlyerConstants.AF_SESSION_READY_CALLBACK,
                        AF_SUCCESS, dataAsJsonString(event)));
            } else if (AppsFlyerConstants.RPC_EVENT_CONVERSION_SUCCESS.equals(name)) {
                deliverEvent(buildCallListenerArgs(AppsFlyerConstants.AF_GCD_CALLBACK, AF_SUCCESS, dataAsJsonString(event)));
            } else if (AppsFlyerConstants.RPC_EVENT_CONVERSION_FAIL.equals(name)) {
                deliverEvent(buildCallListenerArgs(AppsFlyerConstants.AF_GCD_CALLBACK, AF_FAILURE, dataAsJsonString(event)));
            } else if (AppsFlyerConstants.RPC_EVENT_DEEP_LINK.equals(name)) {
                deliverEvent(buildDeepLinkArgs(event.optJSONObject("data")));
            }
        } catch (JSONException e) {
            Log.e(AF_PLUGIN_TAG, "Failed to process bridge event: " + e.getMessage(), e);
        }
    }

    private String dataAsJsonString(JSONObject event) {
        JSONObject data = event.optJSONObject("data");
        return data != null ? data.toString() : "{}";
    }

    /** GCD / OAOA shape expected by callbacks.dart: {id, status, data(json string)}. */
    private String buildCallListenerArgs(String id, String status, String dataJsonString) throws JSONException {
        JSONObject args = new JSONObject();
        args.put("id", id);
        args.put("status", status);
        args.put("data", dataJsonString);
        return args.toString();
    }

    /** onDeepLinking shape expected by callbacks.dart: {id, deepLinkStatus, deepLinkError?, deepLinkObj?}. */
    private String buildDeepLinkArgs(JSONObject data) throws JSONException {
        JSONObject args = new JSONObject();
        args.put("id", AppsFlyerConstants.AF_UDL_CALLBACK);
        if (data != null) {
            args.put("deepLinkStatus", data.optString("status"));
            if (data.has("error")) {
                args.put("deepLinkError", data.optString("error"));
            }
            if (data.has("deepLink")) {
                // The bridge serializes the click event as a JSON string; parse it back to an object.
                try {
                    args.put("deepLinkObj", new JSONObject(data.optString("deepLink")));
                } catch (JSONException ignore) {
                    // Non-JSON deep link payloads are dropped from deepLinkObj; status/error still flow.
                }
            }
        }
        return args.toString();
    }

    // Delivers an event to the af-events stream, or buffers it until Dart subscribes (onListen).
    // Runs on the main thread (processBridgeEvent is posted there by createRpcEventNotifier).
    private void deliverEvent(String callListenerArgs) {
        if (eventSink != null) {
            eventSink.success(callListenerArgs);
        } else {
            pendingEvents.add(callListenerArgs);
        }
    }

    private void flushPendingEvents() {
        if (pendingEvents.isEmpty() || eventSink == null) {
            return;
        }
        List<String> pending = new ArrayList<>(pendingEvents);
        pendingEvents.clear();
        for (String args : pending) {
            eventSink.success(args);
        }
    }

    // ============================================================================
    // init + start (SDK 7 session model)
    // ============================================================================

    private void initFromRpc(JSONObject params, final Result result) {
        final String afDevKey = params.optString(AppsFlyerConstants.AF_DEV_KEY, "");
        if (afDevKey.isEmpty()) {
            Log.e(AF_PLUGIN_TAG, LogMessages.AF_DEV_KEY_IS_EMPTY);
            result.error("INIT_ERROR", LogMessages.AF_DEV_KEY_IS_EMPTY, null);
            return;
        }

        final boolean advertiserIdDisabled = params.optBoolean(AppsFlyerConstants.DISABLE_ADVERTISING_IDENTIFIER, false);
        final boolean getGCD = params.optBoolean(AppsFlyerConstants.AF_GCD, false);
        final boolean getUdl = params.optBoolean(AppsFlyerConstants.AF_UDL, false);
        final boolean isDebug = params.optBoolean(AppsFlyerConstants.AF_IS_DEBUG, false);
        final String appInviteOneLink = params.optString(AppsFlyerConstants.AF_APP_INVITE_ONE_LINK, "");

        rpcExecutor.execute(() -> {
            try {
                // setPluginInfo and the config setters must be applied before init(): these config
                // values are consumed during init().
                executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_PLUGIN_INFO, jsonOf(
                        "plugin", AppsFlyerConstants.AF_PLUGIN_NAME,
                        "pluginVersion", AppsFlyerConstants.PLUGIN_VERSION));

                if (advertiserIdDisabled) {
                    executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_DISABLE_ADVERTISING_IDENTIFIERS,
                            jsonOf("isDisable", true));
                }
                if (isDebug) {
                    executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_LOG_LEVEL, jsonOf("logLevel", "DEBUG"));
                }
                executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_DEBUG_LOG, jsonOf("isDebug", isDebug));

                // init() must run before listeners are registered: registering earlier makes the SDK
                // log "SDK is not initialized" and silently drop the registration. Fail fast if init
                // itself errors.
                RpcResponse initResponse = executeRpcSync(AppsFlyerConstants.RPC_METHOD_INIT, jsonOf("devKey", afDevKey));
                if (initResponse instanceof RpcResponse.Error) {
                    RpcResponse.Error err = (RpcResponse.Error) initResponse;
                    uiThreadHandler.post(() -> result.error(String.valueOf(err.getCode()), err.getMessage(), null));
                    return;
                }

                if (getGCD) {
                    executeRpcSync(AppsFlyerConstants.RPC_METHOD_REGISTER_CONVERSION_LISTENER, new JSONObject());
                }
                if (getUdl) {
                    executeRpcSync(AppsFlyerConstants.RPC_METHOD_SUBSCRIBE_FOR_DEEP_LINK, new JSONObject());
                }
                // Register the session-ready listener so the app can OBSERVE readiness via the
                // Dart registerSessionReadyListener() callback. It does not gate start() -- the app
                // calls startSDK() itself (from that callback), matching the Cordova bridge.
                executeRpcSync(AppsFlyerConstants.RPC_METHOD_REGISTER_SESSION_READY_LISTENER, new JSONObject());

                // Runtime-only setter: re-applied after init(), before start().
                if (!appInviteOneLink.isEmpty()) {
                    executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_APP_INVITE_ONE_LINK,
                            jsonOf("oneLinkId", appInviteOneLink));
                }

                // SDK 7: init() never sends the first session. The app sends it explicitly by
                // calling startSDK() from Dart (dispatched to the "start" RPC -> dispatchRpc()).

                uiThreadHandler.post(() -> result.success("success"));
            } catch (Throwable t) {
                Log.e(AF_PLUGIN_TAG, "init failed: " + t.getMessage(), t);
                uiThreadHandler.post(() -> result.error("INIT_ERROR", t.getMessage(), null));
            }
        });
    }

    // ============================================================================
    // Invite links (results delivered on the af-events stream to match the Dart API)
    // ============================================================================

    private void generateInviteLinkFromRpc(JSONObject params, Result result) {
        putQuietly(params, "awaitResponse", true);
        rpcExecutor.execute(() -> {
            RpcResponse resp = executeRpcSync(AppsFlyerConstants.RPC_METHOD_GENERATE_INVITE_LINK, params);
            try {
                final String args;
                if (resp instanceof RpcResponse.Success) {
                    Object link = ((RpcResponse.Success<?>) resp).getResult();
                    JSONObject data = new JSONObject();
                    data.put("userInviteURL", link != null ? link.toString() : "");
                    args = buildCallListenerArgs("generateInviteLinkSuccess", AF_SUCCESS, data.toString());
                } else if (resp instanceof RpcResponse.Error) {
                    args = buildCallListenerArgs("generateInviteLinkFailure", AF_FAILURE,
                            ((RpcResponse.Error) resp).getMessage());
                } else {
                    args = null;
                }
                if (args != null) {
                    uiThreadHandler.post(() -> deliverEvent(args));
                }
            } catch (JSONException e) {
                Log.e(AF_PLUGIN_TAG, "generateInviteLink callback failed: " + e.getMessage(), e);
            }
        });
        result.success(null);
    }

    private void setAppInviteOneLinkFromRpc(JSONObject params, Result result) {
        rpcExecutor.execute(() -> {
            RpcResponse resp = executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_APP_INVITE_ONE_LINK, params);
            if (!(resp instanceof RpcResponse.Error)) {
                try {
                    final String args = buildCallListenerArgs("setAppInviteOneLinkIDCallback", AF_SUCCESS, "success");
                    uiThreadHandler.post(() -> deliverEvent(args));
                } catch (JSONException e) {
                    Log.e(AF_PLUGIN_TAG, "setAppInviteOneLinkID callback failed: " + e.getMessage(), e);
                }
            }
        });
        result.success(null);
    }

    // ============================================================================
    // Generic RPC dispatch
    // ============================================================================

    private void dispatchRpc(String method, JSONObject params, Result result, Object voidValue) {
        rpcExecutor.execute(() -> {
            RpcResponse resp = executeRpcSync(method, params);
            uiThreadHandler.post(() -> deliverRpcResult(resp, result, voidValue));
        });
    }

    private RpcResponse executeRpcSync(String method, JSONObject params) {
        try {
            JSONObject request = new JSONObject();
            request.put("method", method);
            request.put("params", params != null ? params : new JSONObject());
            return getOrCreateRpcHandler().execute(request.toString());
        } catch (JSONException e) {
            return new RpcResponse.Error(RpcErrorCodes.INTERNAL_ERROR, e.getMessage() != null ? e.getMessage() : "JSON error");
        }
    }

    private void deliverRpcResult(RpcResponse resp, Result result, Object voidValue) {
        if (resp instanceof RpcResponse.Success) {
            result.success(((RpcResponse.Success<?>) resp).getResult());
        } else if (resp instanceof RpcResponse.VoidSuccess) {
            result.success(voidValue);
        } else if (resp instanceof RpcResponse.Error) {
            RpcResponse.Error err = (RpcResponse.Error) resp;
            result.error(String.valueOf(err.getCode()), err.getMessage(), null);
        } else {
            result.success(voidValue);
        }
    }

    // ============================================================================
    // JSON helpers
    // ============================================================================

    /** Builds a JSONObject from alternating key/value pairs; null values are omitted. */
    private JSONObject jsonOf(Object... keyValues) {
        JSONObject json = new JSONObject();
        for (int i = 0; i + 1 < keyValues.length; i += 2) {
            putQuietly(json, (String) keyValues[i], toJsonValue(keyValues[i + 1]));
        }
        return json;
    }

    private void putQuietly(JSONObject json, String key, Object value) {
        if (value == null) {
            return;
        }
        try {
            json.put(key, value);
        } catch (JSONException e) {
            Log.e(AF_PLUGIN_TAG, "Failed to put '" + key + "' into RPC params: " + e.getMessage());
        }
    }

    @SuppressWarnings("unchecked")
    private Object toJsonValue(Object value) {
        if (value instanceof Map) {
            return new JSONObject((Map<String, Object>) value);
        }
        if (value instanceof List) {
            return new org.json.JSONArray((List<Object>) value);
        }
        return value;
    }
}
