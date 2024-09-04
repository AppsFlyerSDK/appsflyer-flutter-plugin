part of appsflyer_sdk;

class AdRevenueData {
  final String monetizationNetwork;
  final String mediationNetwork;
  final String currencyIso4217Code;
  final double revenue;
  final Map<String, dynamic>? additionalParameters;

  AdRevenueData({
    required this.monetizationNetwork,
    required this.mediationNetwork,
    required this.currencyIso4217Code,
    required this.revenue,
    this.additionalParameters
  });

  Map<String, dynamic> toMap() {
    return {
      'monetizationNetwork': monetizationNetwork,
      'mediationNetwork': mediationNetwork,
      'currencyIso4217Code': currencyIso4217Code,
      'revenue': revenue,
      'additionalParameters': additionalParameters
    };
  }
}
