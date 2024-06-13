part of appsflyer_sdk;

enum EmailCryptType {
  EmailCryptTypeNone,
  EmailCryptTypeSHA256
}

class AppsflyerConstants {

  static const String RE_CONFIGURE_ERROR_MSG = "[PurchaseConnector] Re configure instance is not permitted. Returned the existing instance";
  static const String   MISSING_CONFIGURATION_EXCEPTION_MSG = "Could not create an instance without configuration";

  static const String AF_DEV_KEY = "afDevKey";
  static const String AF_APP_Id = "afAppId";
  static const String AF_IS_DEBUG = "isDebug";
  static const String AF_MANUAL_START = "manualStart";
  static const String AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION =
      "timeToWaitForATTUserAuthorization";
  static const String AF_GCD = "GCD";
  static const String AF_UDL = "UDL";
  static const String AF_SUCCESS = "success";
  static const String AF_FAILURE = "failure";
  static const String AF_GET_CONVERSION_DATA = "onInstallConversionDataLoaded";
  static const String AF_ON_APP_OPEN_ATTRIBUTION = "onAppOpenAttribution";
  static const String AF_ON_DEEP_LINK = "onDeepLinking";

  static const String AF_EVENTS_CHANNEL = "af-events";
  static const String AF_METHOD_CHANNEL = "af-api";
  static const String AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector";

  static const String AF_VALIDATE_PURCHASE = "validatePurchase";
  static const String APP_INVITE_ONE_LINK = "appInviteOneLink";

  static const String DISABLE_COLLECT_ASA = "disableCollectASA";
  static const String DISABLE_ADVERTISING_IDENTIFIER =
      "disableAdvertisingIdentifier";

  // Adding method constants
  static const String SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "SubscriptionPurchaseValidationResultListener:onResponse";
  static const String SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "SubscriptionPurchaseValidationResultListener:onFailure";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "InAppValidationResultListener:onResponse";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "InAppValidationResultListener:onFailure";
  static const String DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO =
      "didReceivePurchaseRevenueValidationInfo";

// Adding key constants
  static const String RESULT = "result";
  static const String ERROR = "error";
  static const String VALIDATION_INFO = "validationInfo";
  static const String CONFIGURE_KEY = "configure";
  static const String LOG_SUBS_KEY = "logSubscriptions";
  static const String LOG_IN_APP_KEY = "logInApps";
  static const String SANDBOX_KEY = "sandbox";
}
