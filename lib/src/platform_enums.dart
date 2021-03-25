import 'package:flutter/foundation.dart';

enum PlatformResponse {
  onAppOpenAttribution,
  onInstallConversionData,
  onDeepLinking,
  validatePurchase,
  generateInviteLinkSuccess,

  // Not handled explicitely in Callbacks._methodCallHandler
  setAppInviteOneLinkIDCallback,
  generateInviteLinkFailure,
}

enum PlatformMethod {
  initSdk,
  getSDKVersion,
  setCollectIMEI,
  setCollectAndroidId,
  getHostName,
  getHostPrefix,
  setAndroidIdData,
  setMinTimeBetweenSessions,
  setImeiData,
  setCurrencyCode,
  setCustomerUserId,
  setIsUpdate,
  stop,
  enableLocationCollection,
  updateServerUninstallToken,
  setUserEmailsWithCryptType,
  setUserEmails,
  getAppsFlyerUID,
  waitForCustomerUserId,
  validateAndLogInAppAndroidPurchase,
  validateAndLogInAppIosPurchase,
  setAdditionalData,
  setSharingFilter,
  setSharingFilterForAllPartners,
  generateInviteLink,
  setAppInviteOneLinkID,
  logCrossPromotionImpression,
  logCrossPromotionAndOpenStore,
  setOneLinkCustomDomain,
  setPushNotification,
  enableFacebookDeferredApplinks,
  disableSKAdNetwork,
}

extension PlatformMethodExtension on PlatformMethod {
  String asString() => describeEnum(this);
}

extension PlatformResponseExtension on PlatformResponse {
  String asString() => describeEnum(this);
}

extension MethodCallIdExtension on String {
  PlatformResponse toEnum() {
    // Throw if we don't find an enum to match on
    return PlatformResponse.values.firstWhere(_matchesEnum(this));
  }

  bool Function(PlatformResponse) _matchesEnum(String current) {
    return (e) {
      return describeEnum(e) == current;
    };
  }
}
