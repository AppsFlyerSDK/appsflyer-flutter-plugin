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

    private val uiThreadHandler = Handler(Looper.getMainLooper())
    private var rpcExecutor: ExecutorService? = null

    private var applicationContext: Context? = null
    private var activity: Activity? = null

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private var rpcHandler: AppsFlyerRpcHandler? = null

    private var eventSink: EventChannel.EventSink? = null

    // RD-65582: buffer events that arrive before Dart subscribes (onListen), then replay on
    // attach. Main-thread only.
    private val pendingEvents: MutableList<String> = ArrayList()

    private val onNewIntentListener = PluginRegistry.NewIntentListener { intent ->
        val currentActivity = activity
        if (currentActivity != null) {
            currentActivity.intent = intent
        }
        false
    }

    private val eventStreamHandler: EventChannel.StreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
            flushPendingEvents()
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
        this.applicationContext = applicationContext
        this.rpcExecutor = Executors.newSingleThreadExecutor()

        methodChannel = MethodChannel(messenger, AF_METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, AF_EVENTS_CHANNEL)
        eventChannel?.setStreamHandler(eventStreamHandler)
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
        AppsFlyerPurchaseConnector.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
        pendingEvents.clear()
        AppsFlyerPurchaseConnector.onDetachedFromEngine(binding)
        rpcExecutor?.shutdown()
        rpcExecutor = null
        rpcHandler = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(onNewIntentListener)
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
        val arguments = call.arguments as Map<String, Any?>?
        val method = arguments!!["method"] as String?

        var params = JSONObject()
        val rawParams = arguments["params"]
        if (rawParams is Map<*, *>) {
            params = JSONObject(rawParams)
        }

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

    @Synchronized
    private fun getOrCreateRpcHandler(): AppsFlyerRpcHandler {
        var handler = rpcHandler
        if (handler == null) {
            // Prefer the Activity context: SDK 7 only replays the cold-start launch intent for
            // deep linking when init() receives an Activity (see
            // AndroidLifecycleManagerImpl.registerLifecycleListener). Fall back to the app context
            // if none is attached yet.
            val rpcContext: Context? = if (activity != null) activity else applicationContext
            handler = AppsFlyerRpcHandler(
                rpcContext!!,
                createRpcEventNotifier(),
                AppsFlyerLib.getInstance(),
                JsonRpcRequestParser()
            )
            rpcHandler = handler
        }
        return handler
    }

    /**
     * Bridge notifier. Events fire on the SDK's callback thread, so we hop to the main thread before
     * touching the Flutter channels.
     */
    private fun createRpcEventNotifier(): (String) -> Unit {
        return { eventJson ->
            uiThreadHandler.post { deliverEvent(eventJson) }
        }
    }

    private fun deliverEvent(callListenerArgs: String) {
        val sink = eventSink
        if (sink != null) {
            sink.success(callListenerArgs)
        } else {
            pendingEvents.add(callListenerArgs)
        }
    }

    private fun flushPendingEvents() {
        val sink = eventSink
        if (pendingEvents.isEmpty() || sink == null) {
            return
        }
        val pending: List<String> = ArrayList(pendingEvents)
        pendingEvents.clear()
        for (args in pending) {
            sink.success(args)
        }
    }

    private fun initFromRpc(params: JSONObject, result: Result) {
        val afDevKey = params.optString("devKey", "")

        rpcExecutor!!.execute {
            try {
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
                    jsonOf("devKey", afDevKey)
                )
                if (init is RpcResponse.Error) {
                    uiThreadHandler.post { deliverRpcResult(init, result, null) }
                    return@execute
                }

                uiThreadHandler.post { result.success(null) }
            } catch (t: Throwable) {
                Log.e(AF_PLUGIN_TAG, "init failed: ${t.message}", t)
                uiThreadHandler.post { result.error("INIT_ERROR", t.message, null) }
            }
        }
    }

    private fun dispatchRpc(method: String?, params: JSONObject?, result: Result, voidValue: Any?) {
        rpcExecutor!!.execute {
            val response = executeRpcSync(method, params)
            uiThreadHandler.post { deliverRpcResult(response, result, voidValue) }
        }
    }

    private fun executeRpcSync(method: String?, params: JSONObject?): RpcResponse {
        return try {
            val request = JSONObject()
            request.put("method", method)
            request.put("params", params ?: JSONObject())
            getOrCreateRpcHandler().execute(request.toString())
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
    }
}
