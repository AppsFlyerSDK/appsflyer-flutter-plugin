//
//  PurchaseConnectorPlugin.swift
//  appsflyer_sdk
//
//  Created by Paz Lavi on 11/06/2024.
//
import Foundation
import PurchaseConnector
import Flutter

/// `PurchaseConnectorPlugin` is a `FlutterPlugin` implementation that acts as the bridge between Flutter and the PurchaseConnector iOS SDK.
/// This class is responsible for processing incoming method calls from the Dart layer (via a MethodChannel) and translating these calls to the appropriate tasks in the PurchaseConnector SDK.
@objc public class PurchaseConnectorPlugin : NSObject, FlutterPlugin {
    
    /// Methods channel name constant to be used across plugin.
    private static let  AF_PURCHASE_CONNECTOR_CHANNEL = "af-purchase-connector"
    
    /// Singleton instance of `PurchaseConnectorPlugin` ensures this plugin acts as a centralized point of contact for all method calls.
    internal static let shared = PurchaseConnectorPlugin()
    
    /// An instance of `PurchaseConnector`.
    /// This will be intentionally set to `nil` by default and will be initialized once we call the `configure` method via Flutter.
    private var connector: PurchaseConnector? = nil
    
    /// Instance of method channel providing a bridge to Dart code.
    private var methodChannel: FlutterMethodChannel? = nil

    /// Registrar whose engine installed the channel this singleton currently holds.
    ///
    /// This plugin keeps one channel per process while registration happens per engine, so a host
    /// running several engines hands the channel to whichever one registered last. Recording the
    /// registrar lets a detaching engine tell whether the channel is still its own before tearing
    /// anything down, the same guard `AFRPCBridge` applies to the RPC event handler.
    private weak var owningRegistrar: FlutterPluginRegistrar? = nil
    
    private var logOptions: AutoLogPurchaseRevenueOptions = []
    
    /// Constants used in method channel for Flutter calls.
    private let logSubscriptionsKey = "logSubscriptionPurchase"
    private let logInAppsKey = "logInAppPurchase"
    private let sandboxKey = "sandbox"
    private let storeKitVersionKey = "storeKitVersion"
    /// Private constructor, used to prevent direct instantiation of this class and ensure singleton behaviour.
    private override init() {}

    /// Mandatory method needed to register the plugin with iOS part of Flutter app.
    public static func register(with registrar: FlutterPluginRegistrar) {
        /// Release the previous engine first: a stale channel would keep driving this singleton, and
        /// its ownership-guarded `tearDown` would then skip clearing it. Per-engine state stays
        /// impossible while `PurchaseConnector.shared()` is process-scoped.
        shared.methodChannel?.setMethodCallHandler(nil)

        /// Create a new method channel with the registrar.
        shared.owningRegistrar = registrar
        shared.methodChannel =  FlutterMethodChannel(name: AF_PURCHASE_CONNECTOR_CHANNEL, binaryMessenger: registrar.messenger())
        shared.methodChannel!.setMethodCallHandler(shared.methodCallHandler)
    }

    /// Releases everything this engine's registration owns, mirroring `EngineAttachment.dispose()` in
    /// the Android connector: transaction observation stops, the delegate stops pointing at a channel
    /// whose engine is gone, and `configure` becomes available again for the next engine.
    ///
    /// Called by `AppsflyerSdkPlugin.detachFromEngineForRegistrar:` — this plugin publishes no
    /// instance of its own, so it has no detach callback to receive directly.
    internal static func tearDownForEngineDetach(registrar: FlutterPluginRegistrar) {
        onMain {
            shared.tearDown(registrar: registrar)
        }
    }

    private func tearDown(registrar: FlutterPluginRegistrar) {
        /// A stale engine must not stop observing transactions for an engine that registered after it.
        guard owningRegistrar === registrar else {
            return
        }
        owningRegistrar = nil
        connector?.stopObservingTransactions()
        connector?.purchaseRevenueDelegate = nil
        connector = nil
        logOptions = []
        methodChannel?.setMethodCallHandler(nil)
        methodChannel = nil
    }

    /// Engine detach is the one entry point that may run off the main thread, and both StoreKit
    /// observation and channel teardown belong on it.
    private static func onMain(_ body: @escaping () -> Void) {
        if Thread.isMainThread {
            body()
        } else {
            DispatchQueue.main.async(execute: body)
        }
    }

    /// Method called when a Flutter method call occurs. It handles and routes flutter method invocations.
    private func methodCallHandler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
        /// Match incoming flutter calls from Dart side to its corresponding native method.
        case "configure":
            configure(call: call, result: result)
        case "startObservingTransactions":
            startObservingTransactions(result: result)
        case "stopObservingTransactions":
            stopObservingTransactions(result: result)
        default:
            /// This condition handles an error scenario where the method call doesn't match any predefined cases.
            result(FlutterMethodNotImplemented)
        }
    }
  
    /// This method corresponds to the 'configure' call from Flutter and initiates the PurchaseConnector instance.
    private func configure(call: FlutterMethodCall, result: @escaping FlutterResult) {
        /// Perform a guard check to ensure that we do not reconfigure an existing connector.
        guard connector == nil else {
            result(FlutterError(code: "401", message: "Connector already configured", details: nil))
            return
        }
        
        /// Obtain a shared instance of PurchaseConnector
        connector = PurchaseConnector.shared()

        /// Extract all the required parameters from Flutter arguments
        let arguments = call.arguments as? [String: Any]
        let logSubscriptions = arguments?[logSubscriptionsKey] as? Bool ?? false
        let logInApps = arguments?[logInAppsKey] as? Bool ?? false
        let sandbox = arguments?[sandboxKey] as? Bool ?? false
        let storeKitVersion = arguments?[storeKitVersionKey] as? Int ?? 0   // 0 for StoreKit V1, 1 for StoreKit V2
        
        /// Define an options variable to manage enabled options.
        var options: AutoLogPurchaseRevenueOptions = []
        
        /// Based on the arguments, insert the corresponding options.
        if logSubscriptions {
            options.insert(.autoRenewableSubscriptions)
        }
        if logInApps {
            options.insert(.inAppPurchases)
        }
        
        /// Update the PurchaseConnector instance with these options.
        connector!.autoLogPurchaseRevenue = options
        logOptions = options
        connector!.isSandbox = sandbox
        connector!.purchaseRevenueDelegate = self
        // Set StoreKit version based on the configuration
        if storeKitVersion == 1 {
            if #available(iOS 15.0, *) {
                connector!.setStoreKitVersion(.SK2)
            } else {
                print("[AppsFlyer_purchase] iOS: StoreKit 2 requested but iOS < 15.0, falling back to StoreKit 1")
                connector!.setStoreKitVersion(.SK1)
            }
        } else {
            connector!.setStoreKitVersion(.SK1)
        }
        /// Report a successful operation back to Dart.
        result(nil)
    }

    /// This function starts the process of observing transactions in the iOS App Store.
    private  func startObservingTransactions(result: @escaping FlutterResult) {
        connectorOperation(result: result) { connector in
            // From the docs:  If you called stopObservingTransactions API, set the autoLogPurchaseRevenue value before you call startObservingTransactions next time.
            connector.autoLogPurchaseRevenue = self.logOptions
            connector.startObservingTransactions()
        }
    }

    /// This function stops the process of observing transactions in the iOS App Store.
    private func stopObservingTransactions(result: @escaping FlutterResult) {
        connectorOperation(result: result) { connector in
            connector.stopObservingTransactions()
        }
    }

    /// Helper function used to extract common logic for operations on the connector.
    private  func connectorOperation(result: @escaping FlutterResult, operation: @escaping ((PurchaseConnector) -> Void)) {
        guard connector != nil else {
            result(FlutterError(code: "404", message: "Connector not configured, did you called `configure` first?", details: nil))
            return
        }
        /// Perform the operation with the current connector
        operation(connector!)
        
        result(nil)
    }
}

/// Extension enabling `PurchaseConnectorPlugin` to conform to `PurchaseRevenueDelegate`
extension PurchaseConnectorPlugin: PurchaseRevenueDelegate {
    /// Implementation of the `didReceivePurchaseRevenueValidationInfo` delegate method.
    /// When the validation info comes back after a purchase, it is reported back to the Flutter via the method channel.
    public func didReceivePurchaseRevenueValidationInfo(_ validationInfo: [AnyHashable : Any]?, error: Error?) {
        let resMap: [AnyHashable : Any?] = [
            "validationInfo": validationInfo,
            "error" : error?.asDictionary
        ]
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("didReceivePurchaseRevenueValidationInfo", arguments: resMap.toJSONString())
        }
    }
}

/// Extending `Error` to have a dictionary representation function. `asDictionary` will turn the current error instance into a dictionary containing `localizedDescription`, `domain` and `code` properties.
extension Error {
    var asDictionary: [String: Any] {
        let nsError = self as NSError
        return [
            "localizedDescription": self.localizedDescription,
            "domain": nsError.domain,
            "code": nsError.code,
        ]
    }
}

extension Dictionary {
       
   var jsonData: Data? {
      return try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
   }
       
   func toJSONString() -> String? {
      if let jsonData = jsonData {
         let jsonString = String(data: jsonData, encoding: .utf8)
         return jsonString
      }
      return nil
   }
}
