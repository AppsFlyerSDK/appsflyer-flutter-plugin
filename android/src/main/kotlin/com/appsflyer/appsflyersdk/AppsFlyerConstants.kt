package com.appsflyer.appsflyersdk

internal const val PLUGIN_VERSION = "7.0.1"
internal const val AF_PLUGIN_NAME = "flutter"

internal const val AF_EVENTS_CHANNEL = "af-events"
internal const val AF_METHOD_CHANNEL = "af-api"

internal const val RPC_METHOD_INIT = "init"
internal const val RPC_METHOD_SET_PLUGIN_INFO = "setPluginInfo"

internal const val AF_PLUGIN_TAG = "AppsFlyer_FlutterPlugin"

// Purchase Connector constants
internal const val ERROR = "error"
internal const val RESULT = "result"
internal const val SANDBOX_KEY = "sandbox"
internal const val CONFIGURE_KEY = "configure"
internal const val VALIDATION_INFO = "validationInfo"
internal const val LOG_IN_APP_KEY = "logInAppPurchase"
internal const val LOG_SUBS_KEY = "logSubscriptionPurchase"

internal const val AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector"

// Purchase Connector listeners
internal const val SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE = "SubscriptionPurchaseValidationResultListener:onResponse"
internal const val SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE = "SubscriptionPurchaseValidationResultListener:onFailure"
internal const val IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE = "InAppValidationResultListener:onResponse"
internal const val IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE = "InAppValidationResultListener:onFailure"
internal const val DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO = "didReceivePurchaseRevenueValidationInfo"

// Purchase Connector error messages
internal const val MISSING_CONFIGURATION_EXCEPTION_MSG = "Configuration is missing. Call PurchaseConnector.configure() first."
internal const val RE_CONFIGURE_ERROR_MSG = "PurchaseConnector already configured."
