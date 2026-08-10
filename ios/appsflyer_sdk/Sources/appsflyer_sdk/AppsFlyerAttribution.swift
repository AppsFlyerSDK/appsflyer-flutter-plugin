//
//  AppsFlyerAttribution.swift
//  flutter-appsflyer
//
//  Created by Amit Kremer on 11/02/2021.
//

import Foundation
import UIKit

#if canImport(appsflyer_sdk_objc)
import appsflyer_sdk_objc
#endif

@objc(AppsFlyerAttribution)
public class AppsFlyerAttribution: NSObject {

    /// A deep-link RPC request captured before `initialize` completed. `params` holds the already
    /// JSON-safe Foundation payload that is handed to the RPC layer unchanged.
    private struct PendingRequest {
        let method: String
        let params: [String: Any]
    }

    private static let sharedInstance = AppsFlyerAttribution()

    private var isBridgeReady = false
    private var pendingRequests: [PendingRequest] = []

    @objc(shared)
    public class func shared() -> AppsFlyerAttribution {
        return sharedInstance
    }

    @objc(continueUserActivity:)
    public func continueUserActivity(_ userActivity: NSUserActivity?) {
        guard let userActivity = userActivity, let webpageURL = userActivity.webpageURL else {
            return
        }
        // UIKit annotates `activityType` as non-null, so the original `?: NSUserActivityTypeBrowsingWeb`
        // fallback survives only as an explicit Optional widening.
        let activityType = Optional(userActivity.activityType) ?? NSUserActivityTypeBrowsingWeb
        executeOrQueue(method: "continueUserActivity", params: [
            "url": webpageURL.absoluteString,
            "activityType": activityType
        ])
    }

    @objc(handleOpenUrl:options:)
    public func handleOpenUrl(_ url: URL?, options: [AnyHashable: Any]?) {
        guard let url = url else {
            return
        }
        executeOrQueue(method: "handleOpenUrl", params: [
            "url": url.absoluteString,
            "options": jsonSafeOptions(from: options)
        ])
    }

    @objc(handleOpenUrl:sourceApplication:annotation:)
    public func handleOpenUrl(_ url: URL?, sourceApplication: String?, annotation: Any?) {
        guard let url = url else {
            return
        }
        var rawOptions: [AnyHashable: Any] = [:]
        if let sourceApplication = sourceApplication {
            rawOptions[UIApplication.OpenURLOptionsKey.sourceApplication.rawValue] = sourceApplication
        }
        if let annotation = annotation {
            rawOptions[UIApplication.OpenURLOptionsKey.annotation.rawValue] = annotation
        }
        executeOrQueue(method: "handleOpenURL", params: [
            "url": url.absoluteString,
            "options": jsonSafeOptions(from: rawOptions)
        ])
    }

    @objc(markBridgeReady)
    public func markBridgeReady() {
        isBridgeReady = true
        let requests = pendingRequests
        pendingRequests.removeAll()
        for request in requests {
            execute(method: request.method, params: request.params)
        }
    }

    private func executeOrQueue(method: String, params: [String: Any]) {
        if isBridgeReady {
            execute(method: method, params: params)
        } else {
            pendingRequests.append(PendingRequest(method: method, params: params))
        }
    }

    private func jsonSafeOptions(from options: [AnyHashable: Any]?) -> [String: Any] {
        guard let options = options, !options.isEmpty else {
            return [:]
        }
        var safe: [String: Any] = [:]
        safe.reserveCapacity(options.count)
        for (key, value) in options {
            guard let stringKey = key as? String else {
                continue
            }
            if let safeValue = jsonSafeValue(value) {
                safe[stringKey] = safeValue
            }
        }
        return safe
    }

    private func jsonSafeValue(_ value: Any?) -> Any? {
        guard let value = value, !(value is NSNull) else {
            return nil
        }
        if value is String || value is NSNumber {
            return value
        }
        if value is NSDictionary || value is NSArray {
            return JSONSerialization.isValidJSONObject(value) ? value : nil
        }
        return JSONSerialization.isValidJSONObject([value]) ? value : nil
    }

    private func execute(method: String, params: [String: Any]) {
        let envelope: [String: Any] = ["method": method, "params": params]
        guard JSONSerialization.isValidJSONObject(envelope),
              let data = try? JSONSerialization.data(withJSONObject: envelope, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        AFFlutterRPCBridge.executeJson(json) { _ in }
    }
}
