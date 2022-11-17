part of appsflyer_sdk;

class AppsFlyerInviteLinkParams {
  final String? channel;
  final String? campaign;
  final String? referrerName;
  final String? referrerImageUrl;
  final String? customerID;
  final String? baseDeepLink;
  final String? brandDomain;
  final Map<String?, String?>? customParams;

  AppsFlyerInviteLinkParams({
    this.campaign,
    this.channel,
    this.referrerName,
    this.baseDeepLink,
    this.brandDomain,
    this.customerID,
    this.referrerImageUrl,
    this.customParams
  });
}
