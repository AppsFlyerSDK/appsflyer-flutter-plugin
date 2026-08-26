//
//  AppsFlyerAttribution.swift
//  flutter-appsflyer
//
//  Created by Amit Kremer on 11/02/2021.
//
//  Queue-and-forward layer for UIKit deep-link entry points. UIKit can deliver a link before Dart
//  has called `init()`, so entries captured before the SDK is configured are replayed afterwards.

import AppsFlyerLib
import Foundation

@objc(AppsFlyerAttribution)
public class AppsFlyerAttribution: NSObject {

    /// A UIKit deep-link entry captured before `init()` completed, held as the original Foundation
    /// object: `NSUserActivity` and arbitrary option values do not survive a JSON round trip.
    private enum PendingRequest {
        case openUrl(URL, [AnyHashable: Any]?)
        case userActivity(NSUserActivity)
    }

    private static let sharedInstance = AppsFlyerAttribution()

    private var isBridgeReady = false
    private var pendingRequests: [PendingRequest] = []
    /// The plugin instance that last called `markBridgeReady(markedBy:)`. Used to reset queue state
    /// on engine detach without affecting a live second engine in multi-engine hosts.
    private weak var bridgeReadyOwner: AnyObject?

    @objc(shared)
    public class func shared() -> AppsFlyerAttribution {
        return sharedInstance
    }

    @objc(continueUserActivity:)
    public func continueUserActivity(_ userActivity: NSUserActivity?) {
        guard let userActivity = userActivity, userActivity.webpageURL != nil else {
            return
        }
        executeOrQueue(.userActivity(userActivity))
    }

    @objc(handleOpenUrl:options:)
    public func handleOpenUrl(_ url: URL?, options: [AnyHashable: Any]?) {
        guard let url = url else {
            return
        }
        executeOrQueue(.openUrl(url, options))
    }

    /// Called from `AppsflyerSdkPlugin` after `init()` completes so detach can reset this singleton
    /// only for the engine that marked it ready. Not exposed on the `@objc` surface: a parameterless
    /// variant would open the gate without recording an owner and `resetBridgeStateIfOwned(by:)` could
    /// not clear stale state on engine detach.
    func markBridgeReady(markedBy owner: AnyObject) {
        onMain { [self] in
            applyBridgeReady(owner: owner)
        }
    }

    /// Clears queue state when the owning Flutter engine detaches. No-op for other engines.
    func resetBridgeStateIfOwned(by owner: AnyObject) {
        onMain { [self] in
            guard bridgeReadyOwner === owner else {
                return
            }
            bridgeReadyOwner = nil
            isBridgeReady = false
            pendingRequests.removeAll()
        }
    }

    private func applyBridgeReady(owner: AnyObject) {
        bridgeReadyOwner = owner
        isBridgeReady = true
        let requests = pendingRequests
        pendingRequests.removeAll()
        requests.forEach(execute)
    }

    private func executeOrQueue(_ request: PendingRequest) {
        onMain { [self] in
            if isBridgeReady {
                execute(request)
            } else {
                pendingRequests.append(request)
            }
        }
    }

    private func execute(_ request: PendingRequest) {
        switch request {
        case let .openUrl(url, options):
            AppsFlyerLib.shared().handleOpen(url, options: options)
        case let .userActivity(userActivity):
            _ = AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        }
    }

    /// Serializes `isBridgeReady` / `pendingRequests` on the main queue. UIKit entry points are
    /// already main-thread; `markBridgeReady` is normalized there by `AFRPCBridge`, but the public
    /// `@objc` surface must not rely on caller thread affinity.
    private func onMain(_ body: @escaping () -> Void) {
        if Thread.isMainThread {
            body()
        } else {
            DispatchQueue.main.async(execute: body)
        }
    }
}
