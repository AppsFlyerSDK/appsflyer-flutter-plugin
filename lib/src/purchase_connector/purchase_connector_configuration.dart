part of appsflyer_sdk;

/// Contains the configuration settings for a `PurchaseConnector`.
///
/// This class controls automatic logging of In-App purchase and subscription events.
/// It also allows setting a sandbox environment for validation.
class PurchaseConnectorConfiguration {
  bool logSubscriptions;
  bool logInApps;
  bool sandbox;

  /// The StoreKit version to use on iOS.
  ///
  /// - [StoreKitVersion.SK1]: Use StoreKit 1 (legacy, compatible with all iOS versions)
  /// - [StoreKitVersion.SK2]: Use StoreKit 2 (modern, iOS 15+ only, better performance)
  StoreKitVersion storeKitVersion;

  PurchaseConnectorConfiguration({
    this.logSubscriptions = false,
    this.logInApps = false,
    this.sandbox = false,
    this.storeKitVersion =
        StoreKitVersion.SK1, // Default to SK1 for backwards compatibility
  });
}
