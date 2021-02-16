part of appsflyer_sdk;

enum EmailCryptType {
  EmailCryptTypeNone,
  EmailCryptTypeSHA1,
  EmailCryptTypeMD5,
  EmailCryptTypeSHA256
}

class AppsflyerConstants {
  static const String AF_DEV_KEY = "afDevKey";
  static const String AF_APP_Id = "afAppId";
  static const String AF_IS_DEBUG = "isDebug";
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
