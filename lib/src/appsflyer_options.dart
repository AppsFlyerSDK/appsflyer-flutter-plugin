import '../appsflyer_sdk.dart';

class AppsFlyerOptions {
  final String afDevKey;
  final double? timeToWaitForATTUserAuthorization;
  final String? appInviteOneLink;
  final bool? disableAdvertisingIdentifier;
  final bool? disableCollectASA;
  final bool showDebug;
  final String appId;

  AppsFlyerOptions({
    required this.afDevKey,
    this.timeToWaitForATTUserAuthorization,
    this.appInviteOneLink,
    this.disableAdvertisingIdentifier,
    this.disableCollectASA,
    this.showDebug = false,
    this.appId = "",
  });

  Map<String, dynamic> toJson() {
    return {
      AppsflyerConstants.afDevKey: afDevKey,
      AppsflyerConstants.afTimeToWaitForAttUserAuthorization:
          timeToWaitForATTUserAuthorization,
      AppsflyerConstants.afInviteOneLink: appInviteOneLink,
      AppsflyerConstants.disableAdvertisingIdentifier:
          disableAdvertisingIdentifier,
      AppsflyerConstants.disableCollectASA: disableCollectASA,
      AppsflyerConstants.afIsDebug: showDebug,
      AppsflyerConstants.afAppId: appId,
    };
  }
}
