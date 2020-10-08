part of appsflyer_sdk;

class AppsFlyerOptions {
  final String afDevKey;
  final bool showDebug;
  final String appId;
  final double timeToWaitForATTUserAuthorization;
  final String appInviteOneLink;

  AppsFlyerOptions(
      {@required this.afDevKey,
      this.showDebug = false,
      this.appId = "",
      this.timeToWaitForATTUserAuthorization,
      this.appInviteOneLink});
}
