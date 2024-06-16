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
    
    private var logOptions: AutoLogPurchaseRevenueOptions = []
    
    /// Constants used in method channel for Flutter calls.
    private let logSubscriptionsKey = "logSubscriptions"
    private let logInAppsKey = "logInApps"
    private let sandboxKey = "sandbox"
    
    /// Private constructor, used to prevent direct instantiation of this class and ensure singleton behaviour.
    private override init() {}

    /// Mandatory method needed to register the plugin with iOS part of Flutter app.
    public static func register(with registrar: FlutterPluginRegistrar) {
        /// Create a new method channel with the registrar.
            shared.methodChannel =  FlutterMethodChannel(name: AF_PURCHASE_CONNECTOR_CHANNEL, binaryMessenger: registrar.messenger())
            shared.methodChannel!.setMethodCallHandler(shared.methodCallHandler)
        
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
extension PurchaseConnectorPlugin:  PurchaseRevenueDelegate {
    /// Implementation of the `didReceivePurchaseRevenueValidationInfo` delegate method.
    /// When the validation info comes back after a purchase, it is reported back to the Flutter via the method channel.
    public func didReceivePurchaseRevenueValidationInfo(_ validationInfo: [AnyHashable : Any]?, error: Error?) {
        var resMap: [AnyHashable : Any?] = [
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
        var errorMap: [String: Any] = ["localizedDescription": self.localizedDescription]
        if let nsError = self as? NSError {
            errorMap["domain"] = nsError.domain
            errorMap["code"] = nsError.code
        }
        return errorMap
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
