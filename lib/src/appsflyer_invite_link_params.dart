part of appsflyer_sdk;

/// This class represents parameters that are used to generate a user invite link.
@immutable
class AppsFlyerInviteLinkParams {
  /// The channel through which the invite is shared.
  final String? channel;

  /// The campaign associated with the invite link.
  final String? campaign;

  /// The name of the user who generated the invite.
  final String? referrerName;

  /// The URL of the referrer's image.
  final String? referrerImageUrl;

  /// The customer ID of the user who generated the invite.
  final String? referrerCustomerId;

  /// The deep-link path opened by the invite link.
  final String? baseDeepLink;

  /// The branded domain used for the invite link.
  final String? brandDomain;

  /// Additional parameters to include in the invite link.
  final Map<String, String>? userParams;

  /// Creates an [AppsFlyerInviteLinkParams] instance.
  ///
  /// All parameters are optional, allowing greater flexibility when
  /// invoking the constructor.
  const AppsFlyerInviteLinkParams({
    this.channel,
    this.campaign,
    this.referrerName,
    this.referrerImageUrl,
    this.referrerCustomerId,
    this.baseDeepLink,
    this.brandDomain,
    this.userParams,
  });

  /// Converts these parameters to the platform-specific request map.
  ///
  /// Set [isIOS] to `true` for the iOS request format. Android and iOS use
  /// different request keys for [referrerCustomerId].
  Map<String, dynamic> toRpcMap({required bool isIOS}) => {
    'channel': channel,
    'campaign': campaign,
    'referrerName': referrerName,
    'referrerImageUrl': referrerImageUrl,
    isIOS ? 'referrerCustomerId' : 'customerId': referrerCustomerId,
    'baseDeepLink': baseDeepLink,
    'brandDomain': brandDomain,
    'userParams': userParams,
  };
}
