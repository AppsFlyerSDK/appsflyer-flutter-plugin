part of appsflyer_sdk;

/// The options used to configure the AppsFlyer SDK.
class AppsFlyerOptions {
  final String afDevKey;
  final bool showDebug;
  final String appId;
  final double? timeToWaitForATTUserAuthorization;
  final String? appInviteOneLink;
  final bool? disableAdvertisingIdentifier;
  final bool? disableCollectASA;
  final bool? manualStart;

  /// Creates an [AppsFlyerOptions] instance.
  /// Requires [afDevKey] and [appId] as mandatory Named parameters.
  /// All other parameters are optional, it's allows greater flexibility
  /// when invoking the constructor.
  /// When manual start is true the startSDK must be called
  AppsFlyerOptions({
    required this.afDevKey,
    this.showDebug = false,
    this.appId = "",
    this.timeToWaitForATTUserAuthorization,
    this.appInviteOneLink,
    this.disableAdvertisingIdentifier,
    this.disableCollectASA,
    this.manualStart = false,
  });
}
