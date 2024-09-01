part of appsflyer_sdk;

enum EmailCryptType { EmailCryptTypeNone, EmailCryptTypeSHA256 }

class AppsflyerConstants {
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

  static const String AF_VALIDATE_PURCHASE = "validatePurchase";
  static const String APP_INVITE_ONE_LINK = "appInviteOneLink";

  static const String DISABLE_COLLECT_ASA = "disableCollectASA";
  static const String DISABLE_ADVERTISING_IDENTIFIER =
      "disableAdvertisingIdentifier";
}

enum MediationNetwork {
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
      case MediationNetwork.ironSource:
        return "ironsource";
      case MediationNetwork.applovinMax:
        return "applovinmax";
      case MediationNetwork.googleAdMob:
        return "googleadmob";
      case MediationNetwork.fyber:
        return "fyber";
      case MediationNetwork.appodeal:
        return "appodeal";
      case MediationNetwork.admost:
        return "Admost";
      case MediationNetwork.topon:
        return "Topon";
      case MediationNetwork.tradplus:
        return "Tradplus";
      case MediationNetwork.yandex:
        return "Yandex";
      case MediationNetwork.chartboost:
        return "chartboost";
      case MediationNetwork.unity:
        return "Unity";
      case MediationNetwork.toponPte:
        return "toponpte";
      case MediationNetwork.customMediation:
        return "customMediation";
      case MediationNetwork.directMonetizationNetwork:
        return "directMonetizationNetwork";
    }
  }
}
