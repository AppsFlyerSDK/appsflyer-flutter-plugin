part of appsflyer_sdk;

enum EmailCryptType { EmailCryptTypeNone, EmailCryptTypeSHA256 }

class AppsflyerConstants {
  static const String PLUGIN_VERSION = "6.17.1";
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
  static const String AF_CALLBACK_CHANNEL = "callbacks";

  static const String AF_VALIDATE_PURCHASE = "validatePurchase";
  static const String APP_INVITE_ONE_LINK = "appInviteOneLink";

  static const String DISABLE_COLLECT_ASA = "disableCollectASA";
  static const String DISABLE_ADVERTISING_IDENTIFIER =
      "disableAdvertisingIdentifier";

  // Purchase Connector constants
  static const String AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector";
  static const String CONFIGURE_KEY = "configure";
  static const String LOG_SUBS_KEY = "logSubscriptionPurchase";
  static const String LOG_IN_APP_KEY = "logInAppPurchase";
  static const String SANDBOX_KEY = "sandbox";
  static const String VALIDATION_INFO = "validationInfo";
  static const String ERROR = "error";
  static const String RESULT = "result";

  // Purchase Connector listeners
  static const String
      SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "SubscriptionPurchaseValidationResultListener#onResponse";
  static const String
      SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "SubscriptionPurchaseValidationResultListener#onFailure";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "InAppValidationResultListener#onResponse";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "InAppValidationResultListener#onFailure";
  static const String DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO =
      "didReceivePurchaseRevenueValidationInfo";

  // Purchase Connector error messages
  static const String MISSING_CONFIGURATION_EXCEPTION_MSG =
      "Configuration is missing. Call PurchaseConnector.configure() first.";
  static const String RE_CONFIGURE_ERROR_MSG =
      "PurchaseConnector already configured.";
}

enum AFMediationNetwork {
  ironSource,
  applovinMax,
  googleAdMob,
  fyber,
  appodeal,
  admost,
  topon,
  tradplus,
  yandex,
  chartboost,
  unity,
  toponPte,
  customMediation,
  directMonetizationNetwork;

  String get value {
    switch (this) {
      case AFMediationNetwork.ironSource:
        return "ironsource";
      case AFMediationNetwork.applovinMax:
        return "applovin_max";
      case AFMediationNetwork.googleAdMob:
        return "google_admob";
      case AFMediationNetwork.fyber:
        return "fyber";
      case AFMediationNetwork.appodeal:
        return "appodeal";
      case AFMediationNetwork.admost:
        return "admost";
      case AFMediationNetwork.topon:
        return "topon";
      case AFMediationNetwork.tradplus:
        return "tradplus";
      case AFMediationNetwork.yandex:
        return "yandex";
      case AFMediationNetwork.chartboost:
        return "chartboost";
      case AFMediationNetwork.unity:
        return "unity";
      case AFMediationNetwork.toponPte:
        return "topon_pte";
      case AFMediationNetwork.customMediation:
        return "custom_mediation";
      case AFMediationNetwork.directMonetizationNetwork:
        return "direct_monetization_network";
    }
  }
}
