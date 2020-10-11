part of appsflyer_sdk;

class AppsFlyerInviteLinkParams {
  final String channel;
  final String campaign;
  final String referrerName;
  final String referreImageUrl;
  final String customerID;
  final String baseDeepLink;
  final String brandDomain;

  AppsFlyerInviteLinkParams({
    this.campaign,
    this.channel,
    this.referrerName,
    this.baseDeepLink,
    this.brandDomain,
    this.customerID,
    this.referreImageUrl,
  });
}
