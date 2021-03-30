class AppsFlyerInviteLinkParams {
  final String? channel;
  final String? campaign;
  final String? referrerName;
  final String? referrerImageUrl;
  final String? customerID;
  final String? baseDeepLink;
  final String? brandDomain;

  AppsFlyerInviteLinkParams({
    this.campaign,
    this.channel,
    this.referrerName,
    this.baseDeepLink,
    this.brandDomain,
    this.customerID,
    this.referrerImageUrl,
  });

  Map<String, String?> toJson() {
    return {
      'referrerImageUrl': referrerImageUrl,
      'customerID': customerID,
      'brandDomain': brandDomain,
      'baseDeeplink': baseDeepLink,
      'referrerName': referrerName,
      'channel': channel,
      'campaign': campaign,
    };
  }
}
