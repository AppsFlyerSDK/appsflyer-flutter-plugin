part of appsflyer_sdk;

/// This class represents parameters that are used to generate a user invite link.
class AppsFlyerInviteLinkParams {
  final String? channel;
  final String? campaign;
  final String? referrerName;
  final String? referrerImageUrl;
  final String? customerID;
  final String? baseDeepLink;
  final String? brandDomain;
  final Map<String?, String?>? customParams;

  /// Creates an [AppsFlyerInviteLinkParams] instance.
  /// All parameters are optional, allowing greater flexibility when
  /// invoking the constructor.
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
