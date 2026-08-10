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

import static com.appsflyer.appsflyersdk.AppsFlyerConstants.AF_PLUGIN_TAG;

/**
 * AppsflyerSdkPlugin (Android)
 *
 * Bridges Dart's single {@code executeRpc} method call to {@link AppsFlyerRpcHandler}. {@code
 * init} is handled specially to set up the plugin and native SDK in order; every other call is
 * forwarded as-is. Native SDK callbacks flow back unchanged through {@code af-events}.
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

    private EventChannel.EventSink eventSink;

    // RD-65582: buffer events that arrive before Dart subscribes (onListen), then replay on
    // attach. Main-thread only.
    private final List<String> pendingEvents = new ArrayList<>();

    private final PluginRegistry.NewIntentListener onNewIntentListener = intent -> {
        if (activity != null) {
            activity.setIntent(intent);
        }
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
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (METHOD_EXECUTE_RPC.equals(call.method)) {
            executeRpc(call, result);
        } else {
            result.notImplemented();
        }
    }

    @SuppressWarnings("unchecked")
    private void executeRpc(MethodCall call, Result result) {
        Map<String, Object> map = (Map<String, Object>) call.arguments;
        String method = (String) map.get("method");

        JSONObject params = new JSONObject();
        Object rawParams = map.get("params");
        if (rawParams instanceof Map) {
            params = new JSONObject((Map<String, Object>) rawParams);
        }

        try {
            if (AppsFlyerConstants.RPC_METHOD_INIT.equals(method)) {
                initFromRpc(params, result);
            } else {
                dispatchRpc(method, params, result, null);
            }
        } catch (Throwable t) {
            Log.e(AF_PLUGIN_TAG, "executeRpc error for '" + method + "': " + t.getMessage(), t);
            result.error("UNEXPECTED_ERROR", t.getMessage(), null);
        }
    }

    private synchronized AppsFlyerRpcHandler getOrCreateRpcHandler() {
        if (rpcHandler == null) {
            // Prefer the Activity context: SDK 7 only replays the cold-start launch intent for
            // deep linking when init() receives an Activity (see
            // AndroidLifecycleManagerImpl.registerLifecycleListener). Fall back to the app context
            // if none is attached yet.
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
            uiThreadHandler.post(() -> deliverEvent(eventJson));
            return Unit.INSTANCE;
        };
    }

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

    private void initFromRpc(JSONObject params, final Result result) {
        final String afDevKey = params.optString("devKey", "");

        rpcExecutor.execute(() -> {
            try {
                // Identify the Flutter integration before init so the plugin name reaches the
                // first session. Result ignored: the plugin name is a compile-time constant, so
                // this can't fail in practice.
                executeRpcSync(AppsFlyerConstants.RPC_METHOD_SET_PLUGIN_INFO, jsonOf(
                        "plugin", AppsFlyerConstants.AF_PLUGIN_NAME,
                        "pluginVersion", AppsFlyerConstants.PLUGIN_VERSION));

                RpcResponse init = executeRpcSync(
                        AppsFlyerConstants.RPC_METHOD_INIT,
                        jsonOf("devKey", afDevKey));
                if (init instanceof RpcResponse.Error) {
                    uiThreadHandler.post(() -> deliverRpcResult(init, result, null));
                    return;
                }

                uiThreadHandler.post(() -> result.success(null));
            } catch (Throwable t) {
                Log.e(AF_PLUGIN_TAG, "init failed: " + t.getMessage(), t);
                uiThreadHandler.post(() -> result.error("INIT_ERROR", t.getMessage(), null));
            }
        });
    }

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
