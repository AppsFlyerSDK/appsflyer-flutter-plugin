part of appsflyer_sdk;

/// Enum representing StoreKit versions for iOS Purchase Connector configuration.
///
/// StoreKit is Apple's framework for handling in-app purchases and subscriptions.
/// Different versions offer different capabilities and performance characteristics.
enum StoreKitVersion {
  /// StoreKit 1 (Legacy)
  ///
  /// The original StoreKit framework, available on all iOS versions.
  /// Use this for compatibility with older iOS versions or when you need
  /// specific StoreKit 1 features.
  SK1,

  /// StoreKit 2 (Modern)
  ///
  /// The newer StoreKit framework, available on iOS 15.0 and later.
  /// Offers improved performance, better transaction handling, and
  /// more comprehensive purchase validation features.
  /// Recommended for apps targeting iOS 15+ for better automatic purchase tracking.
  SK2;

  /// Returns the integer value associated with this StoreKit version.
  ///
  /// This value is used internally by the native iOS implementation
  /// to configure the appropriate StoreKit version.
  int get value {
    switch (this) {
      case StoreKitVersion.SK1:
        return 0;
      case StoreKitVersion.SK2:
        return 1;
    }
  }

  /// Creates a StoreKitVersion from an integer value.
  ///
  /// Returns [StoreKitVersion.SK1] for value 0, [StoreKitVersion.SK2] for value 1.
  /// Defaults to [StoreKitVersion.SK1] for any other value.
  static StoreKitVersion fromValue(int value) {
    switch (value) {
      case 0:
        return StoreKitVersion.SK1;
      case 1:
        return StoreKitVersion.SK2;
      default:
        return StoreKitVersion
            .SK1; // Default to SK1 for backwards compatibility
    }
  }
}
