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
  /// When [manualStart] is true the startSDK method must be called
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

enum AFMediationNetwork {
  ironSource,
  applovinMax,
  googleAdMob,
  fyber,
  appodeal,
  admost,
  topon,
  tradplus,
  yandex,
  chartboost,
  unity,
  toponPte,
  customMediation,
  directMonetizationNetwork;

  String get value {
    switch (this) {
      case AFMediationNetwork.ironSource:
        return "ironsource";
      case AFMediationNetwork.applovinMax:
        return "applovin_max";
      case AFMediationNetwork.googleAdMob:
        return "google_admob";
      case AFMediationNetwork.fyber:
        return "fyber";
      case AFMediationNetwork.appodeal:
        return "appodeal";
      case AFMediationNetwork.admost:
        return "admost";
      case AFMediationNetwork.topon:
        return "topon";
      case AFMediationNetwork.tradplus:
        return "tradplus";
      case AFMediationNetwork.yandex:
        return "yandex";
      case AFMediationNetwork.chartboost:
        return "chartboost";
      case AFMediationNetwork.unity:
        return "unity";
      case AFMediationNetwork.toponPte:
        return "topon_pte";
      case AFMediationNetwork.customMediation:
        return "custom_mediation";
      case AFMediationNetwork.directMonetizationNetwork:
        return "direct_monetization_network";
    }
  }
}
