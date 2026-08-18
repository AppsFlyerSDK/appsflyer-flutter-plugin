package com.appsflyer.appsflyersdk

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject


/**
 * Bridges the optional Purchase Connector to Flutter over `af-purchase-connector`.
 *
 * Engine state is keyed by [FlutterPlugin.FlutterPluginBinding] so multiple Flutter engines
 * (add-to-app / [FlutterEngineGroup]) do not share one channel or connector instance.
 */
object AppsFlyerPurchaseConnector : FlutterPlugin {

    private val uiThreadHandler = Handler(Looper.getMainLooper())
    private val attachmentsLock = Any()
    private val attachments = mutableMapOf<FlutterPlugin.FlutterPluginBinding, EngineAttachment>()

    private class EngineAttachment(
        val binding: FlutterPlugin.FlutterPluginBinding,
    ) {
        val methodChannel: MethodChannel = MethodChannel(
            binding.binaryMessenger,
            AF_PURCHASE_CONNECTOR_CHANNEL
        )
        var connectorWrapper: ConnectorWrapper? = null

        val subscriptionListener: MappedValidationResultListener = createValidationListener(
            "SubscriptionPurchaseValidationResultListener:onFailure",
            "SubscriptionPurchaseValidationResultListener:onResponse"
        )
        val inAppListener: MappedValidationResultListener = createValidationListener(
            "InAppValidationResultListener:onFailure",
            "InAppValidationResultListener:onResponse"
        )

        private fun createValidationListener(
            failureMethod: String,
            responseMethod: String
        ): MappedValidationResultListener {
            return object : MappedValidationResultListener {
                override fun onFailure(result: String, error: Throwable?) {
                    val resMap = mapOf("result" to result, "error" to error?.toMap())
                    methodChannel.invokeMethodOnUI(failureMethod, resMap)
                }

                override fun onResponse(payload: Map<String, Any>?) {
                    methodChannel.invokeMethodOnUI(responseMethod, payload)
                }
            }
        }

        fun dispose() {
            runCatching { connectorWrapper?.stopObservingTransactions() }
            methodChannel.setMethodCallHandler(null)
            connectorWrapper = null
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val attachment = EngineAttachment(binding)
        attachment.methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(attachment, call, result)
        }
        val stale = synchronized(attachmentsLock) {
            val previous = attachments.remove(binding)
            attachments[binding] = attachment
            previous
        }
        stale?.dispose()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val attachment = synchronized(attachmentsLock) {
            attachments.remove(binding)
        } ?: return
        attachment.dispose()
    }

    private fun handleMethodCall(
        attachment: EngineAttachment,
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "startObservingTransactions" -> startObservingTransactions(attachment, result)
            "stopObservingTransactions" -> stopObservingTransactions(attachment, result)
            "configure" -> configure(attachment, call, result)
            else -> result.notImplemented()
        }
    }

    private fun configure(
        attachment: EngineAttachment,
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (attachment.connectorWrapper != null) {
            result.error("401", "Connector already configured", null)
            return
        }

        val context = attachment.binding.applicationContext
        val logSubs = call.getBoolean(LOG_SUBS_KEY)
        val logInApps = call.getBoolean(LOG_IN_APP_KEY)
        val sandbox = call.getBoolean(SANDBOX_KEY)

        attachment.connectorWrapper = ConnectorWrapper(
            context,
            logSubs,
            logInApps,
            sandbox,
            attachment.subscriptionListener,
            attachment.inAppListener
        )
        result.success(null)
    }

    private fun startObservingTransactions(
        attachment: EngineAttachment,
        result: MethodChannel.Result
    ) = connectorOperation(attachment, result) { it.startObservingTransactions() }

    private fun stopObservingTransactions(
        attachment: EngineAttachment,
        result: MethodChannel.Result
    ) = connectorOperation(attachment, result) { it.stopObservingTransactions() }

    private fun connectorOperation(
        attachment: EngineAttachment,
        result: MethodChannel.Result,
        operation: (ConnectorWrapper) -> Unit
    ) {
        val connector = attachment.connectorWrapper
        if (connector != null) {
            operation(connector)
            result.success(null)
        } else {
            result.error("404", "Connector not configured, did you called `configure` first?", null)
        }
    }

    private fun MethodChannel.invokeMethodOnUI(method: String, args: Any?) {
        uiThreadHandler.post {
            val data = if (args is Map<*, *>) {
                JSONObject(args).toString()
            } else {
                args
            }
            invokeMethod(method, data)
        }
    }

    private fun Throwable.toMap(): Map<String, Any?> {
        return mapOf(
            "type" to this::class.simpleName,
            "message" to this.message,
            "stacktrace" to this.stackTrace.joinToString(separator = "\n") { it.toString() },
            "cause" to this.cause?.toMap()
        )
    }

    private fun MethodCall.getBoolean(key: String, defValue: Boolean = false): Boolean {
        return try {
            argument<Boolean>(key) ?: defValue
        } catch (e: Exception) {
            android.util.Log.w(
                AF_PLUGIN_TAG,
                "Purchase Connector: failed to read '$key', using default $defValue: ${e.message}"
            )
            defValue
        }
    }
}
