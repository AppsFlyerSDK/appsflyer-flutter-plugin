part of appsflyer_sdk;

/// Enum representing the type of purchase for AppsFlyer validation.
enum AFPurchaseType {
  oneTimePurchase,
  subscription,
}

/// Data class representing purchase details for AppsFlyer validation.
///
/// This class encapsulates the essential information needed to validate
/// in-app purchases with AppsFlyer's validation API.
@immutable
class AFPurchaseDetails {
  final AFPurchaseType purchaseType;
  final String purchaseToken;
  final String productId;

  /// Creates an [AFPurchaseDetails] instance.
  ///
  /// All parameters are required:
  /// - [purchaseType]: The type of purchase being validated
  /// - [purchaseToken]: The token provided by the app store for this purchase
  /// - [productId]: The identifier of the product that was purchased
  const AFPurchaseDetails({
    required this.purchaseType,
    required this.purchaseToken,
    required this.productId,
  });

  /// Converts the purchase details to a map for method channel communication.
  Map<String, dynamic> toMap() {
    return {
      'purchaseType': purchaseType == AFPurchaseType.oneTimePurchase
          ? 'one_time_purchase'
          : 'subscription',
      'purchaseToken': purchaseToken,
      'productId': productId,
    };
  }
}
