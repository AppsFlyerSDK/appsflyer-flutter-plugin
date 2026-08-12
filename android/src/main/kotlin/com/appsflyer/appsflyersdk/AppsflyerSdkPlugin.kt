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
 */
open class AppsflyerSdkPlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    private var blockingRpcExecutor: ExecutorService? = null

    @Volatile
    private var applicationContext: Context? = null

    @Volatile
    private var activity: Activity? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private val rpcHandlerLock = Any()

    @Volatile
    private var rpcHandler: AppsFlyerRpcHandler? = null

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
            try {
                events.success(eventJson)
                true
            } catch (t: Throwable) {
                // Reached when the engine behind this sink is already gone. Reporting the refusal
                // lets the bus keep the event for the next subscriber instead of losing it.
                Log.w(AF_PLUGIN_TAG, "af-events sink refused an event: ${t.message}")
                false
            }
        }

    private fun releaseEventSink() {
        eventSink?.let { sink -> AppsFlyerEventBus.detach(sink) }
        eventSink = null
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
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
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        // The buffer in AppsFlyerEventBus is intentionally left untouched: events emitted while no
        // engine is attached have to survive until the next subscriber replays them.
        releaseEventSink()
        AppsFlyerPurchaseConnector.onDetachedFromEngine(binding)
        blockingRpcExecutor?.shutdown()
        blockingRpcExecutor = null
        synchronized(rpcHandlerLock) {
            rpcHandler = null
        }
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

    @Suppress("UNCHECKED_CAST")
    private fun executeRpc(call: MethodCall, result: Result) {
        // Internal transport contract (_invokeRpc): {method: String, params: Map}. Apps must not
        // call this channel directly; a malformed envelope is an integration error and throws here.
        val arguments = call.arguments as Map<String, Any?>
        val method = arguments["method"] as String
        val params = JSONObject(arguments["params"] as Map<*, *>)

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

    private fun getOrCreateRpcHandler(): AppsFlyerRpcHandler {
        synchronized(rpcHandlerLock) {
            var handler = rpcHandler
            if (handler == null) {
                val ctx = requireApplicationContext()
                handler = createRpcHandler(ctx.applicationContext)
                rpcHandler = handler
            }
            return handler
        }
    }

    /**
     * Ephemeral handler for [RPC_METHOD_INIT] only. SDK 7 replays the cold-start launch intent
     * when init() receives an [Activity] (see AndroidLifecycleManagerImpl.registerLifecycleListener).
     * The cached handler always uses [Context.getApplicationContext] so it survives rotation.
     */
    private fun createRpcHandler(context: Context): AppsFlyerRpcHandler {
        return AppsFlyerRpcHandler(
            context,
            rpcEventNotifier,
            AppsFlyerLib.getInstance(),
            JsonRpcRequestParser()
        )
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

        runRpc(result, "init failed", "INIT_ERROR") {
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
            if (init is RpcResponse.Error) {
                deliverRpcResult(init, result, null)
                return@runRpc
            }

            result.success(null)
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
                    uiThreadHandler.post { result.error(failureCode, t.message, null) }
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
            val handler = if (initContext != null) {
                createRpcHandler(initContext)
            } else {
                getOrCreateRpcHandler()
            }
            handler.execute(request.toString())
        } catch (e: JSONException) {
            RpcResponse.Error(RpcErrorCodes.INTERNAL_ERROR, e.message ?: "JSON error")
        }
    }

    private fun deliverRpcResult(response: RpcResponse, result: Result, voidValue: Any?) {
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
