package com.appsflyer.appsflyersdk;

public final class AppsFlyerConstants {

    final static String PLUGIN_VERSION = "7.0.1";
    final static String AF_PLUGIN_NAME = "flutter";

    final static String AF_EVENTS_CHANNEL = "af-events";
    final static String AF_METHOD_CHANNEL = "af-api";

    final static String RPC_METHOD_INIT = "init";
    final static String RPC_METHOD_SET_PLUGIN_INFO = "setPluginInfo";

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
