enum EmailCryptType {
  emailCryptTypeNone,
  emailCryptTypeSHA1,
  emailCryptTypeMD5,
  emailCryptTypeSHA256
}

class AppsflyerConstants {
  static const String afDevKey = "afDevKey";
  static const String afAppId = "afAppId";
  static const String afIsDebug = "isDebug";
  static const String afTimeToWaitForAttUserAuthorization =
      "timeToWaitForATTUserAuthorization";
  static const String afGCD = "GCD";
  static const String afUDL = "UDL";
  static const String afSuccess = "success";
  static const String afFailure = "failure";
  static const String afGetConversionData = "onInstallConversionDataLoaded";
  static const String afOnAppOpenAttribution = "onAppOpenAttribution";
  static const String afOnDeepLink = "onDeepLinking";

  static const String afEventsChannel = "af-events";
  static const String afMethodChannel = "af-api";

  static const String afValidatePurchase = "validatePurchase";
  static const String afInviteOneLink = "appInviteOneLink";

  static const String disableCollectASA = "disableCollectASA";
  static const String disableAdvertisingIdentifier =
      "disableAdvertisingIdentifier";
}
