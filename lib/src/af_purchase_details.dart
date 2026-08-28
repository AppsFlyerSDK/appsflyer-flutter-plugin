part of appsflyer_sdk;

/// The type of purchase submitted for AppsFlyer validation.
enum AFPurchaseType {
  /// A one-time in-app purchase.
  oneTimePurchase,

  /// A recurring subscription purchase.
  subscription,
}

/// Purchase details accepted by [AppsFlyerSdk.validateAndLogInAppPurchase].
///
/// Use [AFAndroidPurchaseDetails] for Google Play purchases and
/// [AFIOSPurchaseDetails] for App Store purchases.
@immutable
sealed class AFPurchaseDetails {
  /// The kind of purchase being validated.
  AFPurchaseType get purchaseType;

  /// The store product identifier.
  String get productId;

  /// Builds the platform-specific native validation parameters.
  ///
  /// This is normally called by [AppsFlyerSdk.validateAndLogInAppPurchase].
  /// Implementations throw [ArgumentError] when used with the wrong [platform].
  Map<String, dynamic> toRpcMap({
    required TargetPlatform platform,
    Map<String, String>? additionalParameters,
  });
}

/// Google Play purchase details.
@immutable
final class AFAndroidPurchaseDetails implements AFPurchaseDetails {
  @override
  final AFPurchaseType purchaseType;

  @override
  final String productId;

  /// The Google Play purchase token.
  final String purchaseToken;

  /// Creates Google Play purchase details.
  ///
  /// [productId] and [purchaseToken] must be non-empty.
  const AFAndroidPurchaseDetails({
    required this.purchaseType,
    required this.productId,
    required this.purchaseToken,
  });

  @override
  Map<String, dynamic> toRpcMap({
    required TargetPlatform platform,
    Map<String, String>? additionalParameters,
  }) {
    if (platform != TargetPlatform.android) {
      throw ArgumentError(
        'AFAndroidPurchaseDetails can only be used on Android',
      );
    }
    return {
      'purchaseType': purchaseType == AFPurchaseType.oneTimePurchase
          ? 'one_time_purchase'
          : 'subscription',
      'purchaseToken': purchaseToken,
      'productId': productId,
      'additionalParameters': additionalParameters,
    };
  }
}

/// App Store purchase details.
@immutable
final class AFIOSPurchaseDetails implements AFPurchaseDetails {
  @override
  final AFPurchaseType purchaseType;

  @override
  final String productId;

  /// The App Store transaction identifier.
  final String transactionId;

  /// Creates App Store purchase details.
  ///
  /// [productId] and [transactionId] must be non-empty.
  const AFIOSPurchaseDetails({
    required this.purchaseType,
    required this.productId,
    required this.transactionId,
  });

  @override
  Map<String, dynamic> toRpcMap({
    required TargetPlatform platform,
    Map<String, String>? additionalParameters,
  }) {
    if (platform != TargetPlatform.iOS) {
      throw ArgumentError('AFIOSPurchaseDetails can only be used on iOS');
    }
    return {
      'product': {'productId': productId},
      'transaction': {
        'transactionId': transactionId,
        'purchaseType': purchaseType == AFPurchaseType.subscription
            ? 'subscription'
            : 'oneTimePurchase',
      },
      'additionalParameters': additionalParameters,
    };
  }
}
