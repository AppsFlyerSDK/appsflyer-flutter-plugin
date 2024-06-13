part of appsflyer_sdk;

/// Contains the configuration settings for a `PurchaseConnector`.
///
/// This class controls automatic logging of In-App purchase and subscription events.
/// It also allows setting a sandbox environment for validation.
class PurchaseConnectorConfiguration {
  bool logSubscriptions;
  bool logInApps;
  bool sandbox;

  PurchaseConnectorConfiguration(
      {this.logSubscriptions = false,
        this.logInApps = false,
        this.sandbox = false});
}
