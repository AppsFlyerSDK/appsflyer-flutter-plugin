part of appsflyer_sdk;

class _AppsFlyerConstants {
  static const String PLUGIN_VERSION = "7.0.2";
  static const String AF_EVENTS_CHANNEL = "af-events";
  static const String AF_METHOD_CHANNEL = "af-api";

  // Native RPC event names delivered on AF_EVENTS_CHANNEL.
  static const String EVENT_CONVERSION_DATA_SUCCESS = "onConversionDataSuccess";
  static const String EVENT_CONVERSION_DATA_FAIL = "onConversionDataFail";
  static const String EVENT_DEEP_LINKING = "onDeepLinking";
  static const String EVENT_DEEP_LINK_RECEIVED = "onDeepLinkReceived";
  static const String EVENT_SESSION_READY = "onSessionReady";

  // Purchase Connector constants
  static const String AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector";
  static const String CONFIGURE_KEY = "configure";
  static const String LOG_SUBS_KEY = "logSubscriptionPurchase";
  static const String LOG_IN_APP_KEY = "logInAppPurchase";
  static const String SANDBOX_KEY = "sandbox";
  static const String VALIDATION_INFO = "validationInfo";
  static const String ERROR = "error";
  static const String RESULT = "result";
  static const String STORE_KIT_VERSION_KEY = "storeKitVersion";
  // Purchase Connector listeners
  // These match the exact method names sent by the native Android channel.
  static const String
  SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "SubscriptionPurchaseValidationResultListener:onResponse";
  static const String
  SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "SubscriptionPurchaseValidationResultListener:onFailure";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE =
      "InAppValidationResultListener:onResponse";
  static const String IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE =
      "InAppValidationResultListener:onFailure";
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

  String rpcValue({required bool isIOS}) {
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
        return isIOS ? "custom" : "custom_mediation";
      case AFMediationNetwork.directMonetizationNetwork:
        return isIOS ? "directmonetization" : "direct_monetization_network";
    }
  }
}

/// Android SDK logging levels supported by [AppsFlyerSdk.setLogLevel].
enum AFLogLevel {
  none,
  error,
  warning,
  info,
  debug,
  verbose;

  String get rpcValue => name.toUpperCase();
}
