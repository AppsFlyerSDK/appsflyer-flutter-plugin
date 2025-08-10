package com.appsflyer.appsflyersdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.lang.ref.WeakReference


/**
 * A Flutter plugin that establishes a bridge between the Flutter appsflyer SDK and the Native Android Purchase Connector.
 *
 * This plugin utilizes MethodChannels to communicate between Flutter and native Android,
 * passing method calls and event callbacks.
 *
 * @property methodChannel used to set up the communication channel between Flutter and Android.
 * @property contextRef a Weak Reference to the application context when the plugin is first attached. Used to build the Appsflyer's Purchase Connector.
 * @property connectorWrapper wraps the Appsflyer's Android purchase client and bridge map conversion methods. Used to perform various operations (configure, start/stop observing transactions).
 * @property arsListener an object of [MappedValidationResultListener] that handles SubscriptionPurchaseValidationResultListener responses and failures. Lazily initialized.
 * @property viapListener an object of [MappedValidationResultListener] that handles InAppValidationResultListener responses and failures. Lazily initialized.
 */
object AppsFlyerPurchaseConnector : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var methodChannel: MethodChannel? = null
    private var contextRef: WeakReference<Context>? = null
    private var connectorWrapper: ConnectorWrapper? = null
    private val handler by lazy { Handler(Looper.getMainLooper()) }

    private val arsListener: MappedValidationResultListener by lazy {
        object : MappedValidationResultListener {
            override fun onFailure(result: String, error: Throwable?) {
                val resMap = mapOf("result" to result, "error" to error?.toMap())
                methodChannel?.invokeMethodOnUI(
                    "SubscriptionPurchaseValidationResultListener:onFailure",
                    resMap
                )
            }

            override fun onResponse(p0: Map<String, Any>?) {
                methodChannel?.invokeMethodOnUI(
                    "SubscriptionPurchaseValidationResultListener:onResponse",
                    p0
                )
            }
        }
    }

    private val viapListener: MappedValidationResultListener by lazy {
        object : MappedValidationResultListener {
            override fun onFailure(result: String, error: Throwable?) {
                val resMap = mapOf("result" to result, "error" to error?.toMap())
                methodChannel?.invokeMethodOnUI("InAppValidationResultListener:onFailure", resMap)
            }

            override fun onResponse(p0: Map<String, Any>?) {
                methodChannel?.invokeMethodOnUI("InAppValidationResultListener:onResponse", p0)
            }
        }
    }

    private fun MethodChannel?.invokeMethodOnUI(method: String, args: Any?) = this?.let {
        handler.post {
            val data = if (args is Map<*, *>) {
                JSONObject(args).toString()
            } else {
                args
            }
            it.invokeMethod(method, data)
        }
    }


    /**
     * Called when the plugin is attached to the Flutter engine.
     *
     * It sets up the MethodChannel and retains the application context.
     *
     * @param binding The binding provides access to the binary messenger and application context.
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel =
            MethodChannel(
                binding.binaryMessenger,
                AppsFlyerConstants.AF_PURCHASE_CONNECTOR_CHANNEL
            ).also {
                it.setMethodCallHandler(this)
            }
        contextRef = WeakReference(binding.applicationContext)
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     *
     * @param binding The binding that was provided in [onAttachedToEngine].
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

    /**
     * Handles incoming method calls from Flutter.
     *
     * It either triggers a connector operation or returns an unimplemented error.
     * Supported operations are configuring, starting and stopping observing transactions.
     *
     * @param call The method call from Flutter.
     * @param result The result to be returned to Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startObservingTransactions" -> startObservingTransactions(result)
            "stopObservingTransactions" -> stopObservingTransactions(result)
            "configure" -> configure(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Configures the purchase connector with the parameters sent from Flutter.
     *
     * @param call The method call from Flutter.
     * @param result The result to be returned to Flutter.
     */
    private fun configure(call: MethodCall, result: MethodChannel.Result) {
        if (connectorWrapper == null) {
            contextRef?.get()?.let { ctx ->
                val logSubs = call.getBoolean(AppsFlyerConstants.LOG_SUBS_KEY)
                val logInApps = call.getBoolean(AppsFlyerConstants.LOG_IN_APP_KEY)
                val sandbox = call.getBoolean(AppsFlyerConstants.SANDBOX_KEY)
                
                android.util.Log.d("AppsFlyer_PC_Config", "Native received - logSubs: $logSubs, logInApps: $logInApps, sandbox: $sandbox")
                android.util.Log.d("AppsFlyer_PC_Config", "Arguments received: ${call.arguments}")
                
                connectorWrapper = ConnectorWrapper(
                    ctx, logSubs, logInApps, sandbox,
                    arsListener, viapListener
                )
                result.success(null)
            } ?: run {
                result.error("402", "Missing context. Is plugin attached to engine?", null)
            }

        } else {
            result.error("401", "Connector already configured", null)
        }
    }

    /**
     * Starts observing transactions.
     *
     * @param result The result to be returned to Flutter.
     */
    private fun startObservingTransactions(result: MethodChannel.Result) =
        connectorOperation(result) {
            it.startObservingTransactions()
        }

    /**
     * Stops observing transactions.
     *
     * @param result The result to be returned to Flutter.
     */
    private fun stopObservingTransactions(result: MethodChannel.Result) =
        connectorOperation(result) {
            it.stopObservingTransactions()
        }

    /**
     * Performs a specified operation on the connector after confirming that the connector has been configured.
     *
     * @param result The result to be returned to Flutter.
     * @param exc The operation to be performed on the connector.
     */
    private fun connectorOperation(
        result: MethodChannel.Result,
        exc: (connectorWrapper: ConnectorWrapper) -> Unit
    ) {
        if (connectorWrapper != null) {
            exc(connectorWrapper!!)
            result.success(null)
        } else {
            result.error("404", "Connector not configured, did you called `configure` first?", null)
        }
    }

    /**
     * Converts a [Throwable] to a Map that can be returned to Flutter.
     *
     * @return A map representing the [Throwable].
     */
    private fun Throwable.toMap(): Map<String, Any?> {
        return mapOf(
            "type" to this::class.simpleName,
            "message" to this.message,
            "stacktrace" to this.stackTrace.joinToString(separator = "\n") { it.toString() },
            "cause" to this.cause?.toMap()
        )
    }

    /**
     * Attempts to get a Boolean argument from the method call.
     *
     * If unsuccessful, it returns the default value.
     *
     * @param key The key for the argument.
     * @param defValue The default value to be returned if the argument does not exist.
     * @return The value of the argument or the default value if the argument does not exist.
     */
    private fun MethodCall.getBoolean(key: String, defValue: Boolean = false): Boolean {
        return try {
            val value = argument<Boolean>(key)
            android.util.Log.d("AppsFlyer_PC_Config", "Extracted $key = $value")
            value ?: defValue
        } catch (e: Exception) {
            android.util.Log.w("AppsFlyer_PC_Config", "Failed to extract $key, using default $defValue. Error: ${e.message}")
            defValue
        }
    }

}