package com.appsflyer.appsflyersdk

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log

import com.appsflyer.AppsFlyerLib
import com.appsflyer.pluginbridge.handler.AppsFlyerRpcHandler
import com.appsflyer.pluginbridge.model.RpcErrorCodes
import com.appsflyer.pluginbridge.model.RpcResponse
import com.appsflyer.pluginbridge.parser.JsonRpcRequestParser

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/**
 * AppsflyerSdkPlugin (Android)
 *
 * Bridges Dart's single `executeRpc` method call to [AppsFlyerRpcHandler]. `init` is handled
 * specially to set up the plugin and native SDK in order; every other call is forwarded as-is.
 * Native SDK callbacks flow back unchanged through `af-events`.
 *
 * ## State lifetimes
 *
 * Android destroys the Flutter engine on its own schedule — a back press, or a Flutter screen
 * leaving an add-to-app host — while the process, the Activity and `AppsFlyerLib` keep running.
 * A new instance of this class is built when the app comes back, so state is split by what that
 * boundary invalidates:
 *
 * - **Engine-scoped**, held here and released in [onDetachedFromEngine]: the channels, the
 *   `af-events` sink adapter, the blocking-RPC executor, and the Activity/Context references.
 * - **Process-scoped**, held in [AppsFlyerRpcBridge] and [AppsFlyerEventBus]: the RPC handler and
 *   the event buffer. Both outlive this instance on purpose, so a recreated engine reattaches to
 *   the already configured native bridge and still receives events emitted while no engine was
 *   attached (RD-65582).
 *
 * Dart state never survives: the application calls the `register*Listener` APIs again
 * after a new engine attaches. Reusing the handler only makes that
 * re-registration reuse the listeners already registered on `AppsFlyerLib`.
 *
 * ## Two executors
 *
 * [sharedRpcExecutor] serves every RPC but `init`. It resolves the one process-wide handler, built
 * with `applicationContext` so it retains neither an Activity nor an engine.
 *
 * Fast RPCs (setters, getters, and fire-and-forget calls) run inline on the platform thread.
 * `init` and awaited-callback RPCs (`start`, `logEvent`, purchase validation, invite links when
 * `awaitResponse` is true) run on [blockingRpcExecutor] so cold-start bootstrap and slow native
 * latch waits do not block the platform thread.
 *
 * `init` alone uses an ephemeral handler built around the current [Activity] when one is attached
 * ([createRpcExecutor] via [executeRpcSync]), because
 * `AndroidLifecycleManagerImpl.registerLifecycleListener` triggers `onActivityResumed` manually
 * when it receives an `Activity` — that is what lets SDK 7 inspect the launch intent of a cold
 * start, which is already resumed by the time Dart calls `init()`. That handler is deliberately
 * not cached: keeping it would pin the Activity for the lifetime of the process.
 */
open class AppsflyerSdkPlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    private var blockingRpcExecutor: ExecutorService? = null

    @Volatile
    private var isEngineDetached = false

    @Volatile
    private var applicationContext: Context? = null

    @Volatile
    private var activity: Activity? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    // RD-65582: buffering and replay live in AppsFlyerEventBus so they survive engine teardown.
    // Only the adapter around this engine's EventSink is held here, so it can be detached again.
    private var eventSink: AppsFlyerEventSink? = null

    private val onNewIntentListener = PluginRegistry.NewIntentListener { intent ->
        val currentActivity = activity
        if (currentActivity != null) {
            currentActivity.intent = intent
        }
        false
    }

    private val eventStreamHandler: EventChannel.StreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                if (events == null) {
                    // Flutter does not do this in practice; without a destination the previous sink is
                    // no longer usable, so events go back to being buffered.
                    releaseEventSink()
                    return
                }
                val sink = createEventSink(events)
                eventSink = sink
                AppsFlyerEventBus.attach(sink)
            }

            override fun onCancel(arguments: Any?) {
                releaseEventSink()
            }
        }

    private fun createEventSink(events: EventChannel.EventSink): AppsFlyerEventSink =
        AppsFlyerEventSink { eventJson ->
            if (isEngineDetached) {
                // Stop using this sink while teardown is in progress. EventChannel.success() often
                // returns normally even when FlutterJNI is already detached, which would make the bus
                // pop the event as delivered while Dart never receives it.
                return@AppsFlyerEventSink EventSendResult.RETRY_LATER
            }
            try {
                events.success(eventJson)
                EventSendResult.DELIVERED
            } catch (e: RuntimeException) {
                // Flutter's EventSink.success() does not document throws for cancel/detach; inactive
                // sinks and detached JNI usually return silently. Log and buffer for the next attach
                // if the embedding does throw (for example off-main-thread RuntimeException).
                Log.e(AF_PLUGIN_TAG, "af-events delivery failed unexpectedly", e)
                EventSendResult.RETRY_LATER
            }
        }

    private fun releaseEventSink() {
        eventSink?.let { sink -> AppsFlyerEventBus.detach(sink) }
        eventSink = null
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
        isEngineDetached = false
        this.applicationContext = applicationContext
        this.blockingRpcExecutor = Executors.newSingleThreadExecutor()

        methodChannel = MethodChannel(messenger, AF_METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, AF_EVENTS_CHANNEL)
        eventChannel?.setStreamHandler(eventStreamHandler)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
        AppsFlyerPurchaseConnector.onAttachedToEngine(binding)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(onNewIntentListener)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Set first so in-flight blocking-RPC completions posted to the main looper drop their
        // Flutter Result instead of replying on a torn-down engine (mirrors iOS isEngineDetached).
        isEngineDetached = true
        // The buffer in AppsFlyerEventBus is intentionally left untouched: events emitted while no
        // engine is attached have to survive until the next subscriber replays them. The RPC
        // executor in AppsFlyerRpcBridge is left alone for the same reason: it belongs to the
        // process-wide native SDK, not to this engine.
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        releaseEventSink()
        AppsFlyerPurchaseConnector.onDetachedFromEngine(binding)
        blockingRpcExecutor?.shutdown()
        blockingRpcExecutor = null
        activity = null
        applicationContext = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(onNewIntentListener)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (METHOD_EXECUTE_RPC == call.method) {
            executeRpc(call, result)
        } else {
            result.notImplemented()
        }
    }

    private fun executeRpc(call: MethodCall, result: Result) {
        // Internal transport contract (_invokeRpc): {method: String, params: Map}. Apps must not
        // call this channel directly; a malformed envelope is an integration error and is rejected
        // by [RpcEnvelopeParser] before dispatch (fail-fast, not UNEXPECTED_ERROR).
        val (method, params) = RpcEnvelopeParser.parse(call)

        try {
            if (RPC_METHOD_INIT == method) {
                initFromRpc(params, result)
            } else {
                dispatchRpc(method, params, result, null)
            }
        } catch (t: Throwable) {
            Log.e(AF_PLUGIN_TAG, "executeRpc error for '$method': ${t.message}", t)
            result.error("UNEXPECTED_ERROR", t.message, null)
        }
    }

    /**
     * The process-wide executor, so a new engine reattaches to the already configured bridge
     * instead of building one that has no memory of the listeners registered on the native SDK.
     * It always uses [Context.getApplicationContext], which outlives both this engine and the
     * Activity.
     */
    private fun sharedRpcExecutor(): AppsFlyerRpcExecutor =
        AppsFlyerRpcBridge.shared { createRpcExecutor(requireApplicationContext().applicationContext) }

    /**
     * SDK 7 replays the cold-start launch intent when init() receives an [Activity] (see
     * AndroidLifecycleManagerImpl.registerLifecycleListener), so [RPC_METHOD_INIT] runs on an
     * ephemeral executor built around that Activity instead of the shared one.
     */
    private fun createRpcExecutor(context: Context): AppsFlyerRpcExecutor {
        val handler = AppsFlyerRpcHandler(
            context,
            rpcEventNotifier,
            AppsFlyerLib.getInstance(),
            JsonRpcRequestParser()
        )
        return AppsFlyerRpcExecutor { requestJson -> handler.execute(requestJson) }
    }

    private fun requireApplicationContext(): Context {
        return applicationContext
            ?: throw IllegalStateException("Plugin is not attached to a Flutter engine")
    }

    private fun initFromRpc(params: JSONObject, result: Result) {
        val afDevKey = params.optString("devKey", "")
        val initContext = activity ?: applicationContext
        if (initContext == null) {
            result.error("INIT_ERROR", "Plugin is not attached to a Flutter engine", null)
            return
        }

        runOnBlockingRpcExecutor(result, "init failed", "INIT_ERROR") {
            // Identify the Flutter integration before init so the plugin name reaches the
            // first session. Result ignored: the plugin name is a compile-time constant, so
            // this can't fail in practice.
            executeRpcSync(
                RPC_METHOD_SET_PLUGIN_INFO,
                jsonOf(
                    "plugin", AF_PLUGIN_NAME,
                    "pluginVersion", PLUGIN_VERSION
                )
            )

            val init = executeRpcSync(
                RPC_METHOD_INIT,
                jsonOf("devKey", afDevKey),
                initContext
            )
            uiThreadHandler.post {
                if (init is RpcResponse.Error) {
                    deliverRpcResult(init, result, null)
                } else {
                    deliverRpcResult(RpcResponse.VoidSuccess, result, null)
                }
            }
        }
    }

    private fun dispatchRpc(method: String, params: JSONObject, result: Result, voidValue: Any?) {
        if (isBlockingRpc(method, params)) {
            runOnBlockingRpcExecutor(
                result,
                "dispatchRpc('$method') failed",
                "UNEXPECTED_ERROR"
            ) {
                val response = executeRpcSync(method, params)
                uiThreadHandler.post { deliverRpcResult(response, result, voidValue) }
            }
            return
        }

        runRpc(result, "dispatchRpc('$method') failed", "UNEXPECTED_ERROR") {
            val response = executeRpcSync(method, params)
            deliverRpcResult(response, result, voidValue)
        }
    }

    /**
     * RPCs whose native handler blocks on a callback latch (see AppsFlyerRpcHandler.awaitCallback).
     * Everything else runs inline on the platform thread so setters/getters are not queued behind
     * a slow awaited call.
     */
    private fun isBlockingRpc(method: String, params: JSONObject): Boolean {
        return when (method) {
            RPC_METHOD_START, RPC_METHOD_LOG_EVENT ->
                params.optBoolean(RPC_PARAM_AWAIT_RESPONSE, false)
            RPC_METHOD_VALIDATE_AND_LOG_IN_APP_PURCHASE, RPC_METHOD_GENERATE_INVITE_LINK ->
                params.optBoolean(RPC_PARAM_AWAIT_RESPONSE, true)
            else -> false
        }
    }

    private inline fun runRpc(
        result: Result,
        failureLog: String,
        failureCode: String,
        crossinline block: () -> Unit
    ) {
        try {
            block()
        } catch (t: Throwable) {
            Log.e(AF_PLUGIN_TAG, "$failureLog: ${t.message}", t)
            result.error(failureCode, t.message, null)
        }
    }

    private inline fun runOnBlockingRpcExecutor(
        result: Result,
        failureLog: String,
        failureCode: String,
        crossinline block: () -> Unit
    ) {
        val executor = blockingRpcExecutor
        if (executor == null) {
            result.error(PLUGIN_DETACHED, RPC_EXECUTOR_UNAVAILABLE_MSG, null)
            return
        }
        try {
            executor.execute {
                try {
                    block()
                } catch (t: Throwable) {
                    Log.e(AF_PLUGIN_TAG, "$failureLog: ${t.message}", t)
                    uiThreadHandler.post {
                        if (!isEngineDetached) {
                            result.error(failureCode, t.message, null)
                        }
                    }
                }
            }
        } catch (t: RejectedExecutionException) {
            Log.e(AF_PLUGIN_TAG, "$failureLog: executor rejected task: ${t.message}", t)
            result.error(PLUGIN_DETACHED, RPC_EXECUTOR_UNAVAILABLE_MSG, null)
        }
    }

    private fun executeRpcSync(
        method: String,
        params: JSONObject,
        initContext: Context? = null
    ): RpcResponse {
        return try {
            val request = JSONObject()
            request.put("method", method)
            request.put("params", params)
            val executor = if (initContext != null) {
                createRpcExecutor(initContext)
            } else {
                sharedRpcExecutor()
            }
            executor.execute(request.toString())
        } catch (e: JSONException) {
            RpcResponse.Error(RpcErrorCodes.INTERNAL_ERROR, e.message ?: "JSON error")
        }
    }

    private fun deliverRpcResult(response: RpcResponse, result: Result, voidValue: Any?) {
        // Synchronous callers cannot observe a detach — they share the platform thread with
        // onDetachedFromEngine. Only awaited RPCs can: shutdown() lets the in-flight task run to
        // completion, so its latch can resolve after the engine is gone. Replying then is not fatal
        // — Flutter drops the response with a "FlutterJNI was detached" warning — but the warning is
        // misleading in customer bug reports, so the result is dropped here instead.
        if (isEngineDetached) {
            Log.d(AF_PLUGIN_TAG, "Dropping RPC result after engine detach")
            return
        }
        if (response is RpcResponse.Success<*>) {
            result.success(response.result)
        } else if (response is RpcResponse.VoidSuccess) {
            result.success(voidValue)
        } else if (response is RpcResponse.Error) {
            result.error(response.code.toString(), response.message, null)
        } else {
            result.success(voidValue)
        }
    }

    /** Builds a JSONObject from alternating key/value pairs; null values are omitted. */
    private fun jsonOf(vararg keyValues: Any?): JSONObject {
        val json = JSONObject()
        var i = 0
        while (i + 1 < keyValues.size) {
            putQuietly(json, keyValues[i] as String?, toJsonValue(keyValues[i + 1]))
            i += 2
        }
        return json
    }

    private fun putQuietly(json: JSONObject, key: String?, value: Any?) {
        if (value == null) {
            return
        }
        try {
            json.put(key, value)
        } catch (e: JSONException) {
            Log.e(AF_PLUGIN_TAG, "Failed to put '$key' into RPC params: ${e.message}")
        }
    }

    private fun toJsonValue(value: Any?): Any? {
        if (value is Map<*, *>) {
            return JSONObject(value)
        }
        if (value is List<*>) {
            return JSONArray(value)
        }
        return value
    }

    companion object {
        private const val METHOD_EXECUTE_RPC = "executeRpc"

        private const val RPC_METHOD_START = "start"
        private const val RPC_METHOD_LOG_EVENT = "logEvent"
        private const val RPC_METHOD_VALIDATE_AND_LOG_IN_APP_PURCHASE = "validateAndLogInAppPurchase"
        private const val RPC_METHOD_GENERATE_INVITE_LINK = "generateInviteLink"
        private const val RPC_PARAM_AWAIT_RESPONSE = "awaitResponse"

        private val uiThreadHandler = Handler(Looper.getMainLooper())

        /**
         * Bridge notifier. Events fire on the SDK's callback thread, so we hop to the main thread
         * before touching the Flutter channels.
         *
         * Deliberately declared on the companion: the native SDK keeps the listener that owns this
         * notifier registered after the engine is torn down, and capturing no plugin instance is
         * what stops that listener from pinning — and publishing into — a dead plugin.
         */
        private val rpcEventNotifier: (String) -> Unit = { eventJson ->
            uiThreadHandler.post { AppsFlyerEventBus.publish(eventJson) }
        }
    }
}
