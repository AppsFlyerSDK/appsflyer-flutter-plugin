part of appsflyer_sdk;

class AdRevenueData {
  final String monetizationNetwork;
  final String mediationNetwork;
  final String currencyIso4217Code;
  final double revenue;
  final Map<String, dynamic>? additionalParameters;

  AdRevenueData(
      {required this.monetizationNetwork,
      required this.mediationNetwork,
      required this.currencyIso4217Code,
      required this.revenue,
      this.additionalParameters});

  Map<String, dynamic> toMap() {
    return {
      'monetizationNetwork': monetizationNetwork,
      'mediationNetwork':
          mediationNetworkForPlatform(mediationNetwork, isIOS: Platform.isIOS),
      'currencyIso4217Code': currencyIso4217Code,
      'revenue': revenue,
      'additionalParameters': additionalParameters
    };
  }

  /// Maps an [AFMediationNetwork] value to the identifier the target platform's
  /// RPC bridge accepts.
  ///
  /// [AFMediationNetwork.customMediation] and
  /// [AFMediationNetwork.directMonetizationNetwork] serialize to
  /// `custom_mediation` / `direct_monetization_network`. Those resolve on Android
  /// (the bridge matches them by enum name) but are rejected by the iOS parser,
  /// which strips underscores and expects `custom` / `directmonetization`. Remap
  /// only those two for iOS so both platforms accept them; every other value
  /// passes through unchanged.
  @visibleForTesting
  static String mediationNetworkForPlatform(String value,
      {required bool isIOS}) {
    if (!isIOS) return value;
    switch (value) {
      case 'custom_mediation':
        return 'custom';
      case 'direct_monetization_network':
        return 'directmonetization';
      default:
        return value;
    }
  }
}
