package com.appsflyer.appsflyersdk;

public final class AppsFlyerConstants {
    final static String PLUGIN_VERSION = "7.0.0";
    final static String AF_APP_INVITE_ONE_LINK = "appInviteOneLink";
    final static String AF_IS_DEBUG = "isDebug";
    final static String AF_DEV_KEY = "afDevKey";
    final static String AF_SUCCESS = "success";
    final static String AF_FAILURE = "failure";
    final static String AF_GCD = "GCD";
    final static String AF_UDL = "UDL";
    final static String AF_GCD_CALLBACK = "onInstallConversionData";
    final static String AF_UDL_CALLBACK = "onDeepLinking";
    final static String AF_SESSION_READY_CALLBACK = "onSessionReady";
    final static String DISABLE_ADVERTISING_IDENTIFIER = "disableAdvertisingIdentifier";

    final static String AF_EVENTS_CHANNEL = "af-events";
    final static String AF_METHOD_CHANNEL = "af-api";

    // RPC bridge (com.appsflyer.pluginbridge) integration
    final static String AF_PLUGIN_NAME = "flutter";
    // Event names emitted by the RPC bridge notifier
    final static String RPC_EVENT_CONVERSION_SUCCESS = "onConversionDataSuccess";
    final static String RPC_EVENT_CONVERSION_FAIL = "onConversionDataFail";
    final static String RPC_EVENT_DEEP_LINK = "onDeepLinking";
    final static String RPC_EVENT_SESSION_READY = "onSessionReady";

    // RPC method names the NATIVE side types itself. Every other SDK method is forwarded to the
    // bridge generically (AppsflyerSdkPlugin#dispatchRpc) using the method-name string Dart sends,
    // so it needs no constant here. Names must match
    // com.appsflyer.pluginbridge.parser.JsonRpcRequestParser.
    final static String RPC_METHOD_INIT = "init";
    final static String RPC_METHOD_START = "start";
    final static String RPC_METHOD_GENERATE_INVITE_LINK = "generateInviteLink";
    final static String RPC_METHOD_SET_APP_INVITE_ONE_LINK = "setAppInviteOneLink";
    // Applied internally during init(), before start().
    final static String RPC_METHOD_SET_PLUGIN_INFO = "setPluginInfo";
    final static String RPC_METHOD_SET_DEBUG_LOG = "isDebug";
    final static String RPC_METHOD_SET_LOG_LEVEL = "setLogLevel";
    final static String RPC_METHOD_SET_DISABLE_ADVERTISING_IDENTIFIERS = "setDisableAdvertisingIdentifiers";
    final static String RPC_METHOD_REGISTER_CONVERSION_LISTENER = "registerConversionListener";
    final static String RPC_METHOD_SUBSCRIBE_FOR_DEEP_LINK = "subscribeForDeepLink";
    final static String RPC_METHOD_REGISTER_SESSION_READY_LISTENER = "registerSessionReadyListener";

    final static String AF_PLUGIN_TAG = "AppsFlyer_FlutterPlugin";

    // Purchase Connector constants
    final static String AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector";
    final static String CONFIGURE_KEY = "configure";
    final static String LOG_SUBS_KEY = "logSubscriptionPurchase";
    final static String LOG_IN_APP_KEY = "logInAppPurchase";
    final static String SANDBOX_KEY = "sandbox";
    final static String VALIDATION_INFO = "validationInfo";
    final static String ERROR = "error";
    final static String RESULT = "result";
    
    // Purchase Connector listeners
    final static String SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE = "SubscriptionPurchaseValidationResultListener:onResponse";
    final static String SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE = "SubscriptionPurchaseValidationResultListener:onFailure";
    final static String IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE = "InAppValidationResultListener:onResponse";
    final static String IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE = "InAppValidationResultListener:onFailure";
    final static String DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO = "didReceivePurchaseRevenueValidationInfo";
    
    // Purchase Connector error messages
    final static String MISSING_CONFIGURATION_EXCEPTION_MSG = "Configuration is missing. Call PurchaseConnector.configure() first.";
    final static String RE_CONFIGURE_ERROR_MSG = "PurchaseConnector already configured.";
}
