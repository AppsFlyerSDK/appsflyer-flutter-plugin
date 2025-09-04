package com.appsflyer.appsflyersdk;

public final class AppsFlyerConstants {
    final static String PLUGIN_VERSION = "6.17.5";
    final static String AF_APP_INVITE_ONE_LINK = "appInviteOneLink";
    final static String AF_HOST_PREFIX = "hostPrefix";
    final static String AF_HOST_NAME = "hostName";
    final static String AF_IS_DEBUG = "isDebug";
    final static String AF_MANUAL_START = "manualStart";
    final static String AF_DEV_KEY = "afDevKey";
    final static String AF_EVENT_NAME = "eventName";
    final static String AF_EVENT_VALUES = "eventValues";
    final static String AF_ON_INSTALL_CONVERSION_DATA_LOADED = "onInstallConversionDataLoaded";
    final static String AF_ON_APP_OPEN_ATTRIBUTION = "onAppOpenAttribution";
    final static String AF_SUCCESS = "success";
    final static String AF_FAILURE = "failure";
    final static String AF_GCD = "GCD";
    final static String AF_UDL = "UDL";
    final static String AF_VALIDATE_PURCHASE = "validatePurchase";
    final static String AF_GCD_CALLBACK = "onInstallConversionData";
    final static String AF_OAOA_CALLBACK = "onAppOpenAttribution";
    final static String AF_UDL_CALLBACK = "onDeepLinking";
    final static String DISABLE_ADVERTISING_IDENTIFIER = "disableAdvertisingIdentifier";

    final static String AF_EVENTS_CHANNEL = "af-events";
    final static String AF_METHOD_CHANNEL = "af-api";
    final static String AF_CALLBACK_CHANNEL = "callbacks";

    final static String AF_BROADCAST_ACTION_NAME = "com.appsflyer.appsflyersdk";

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
