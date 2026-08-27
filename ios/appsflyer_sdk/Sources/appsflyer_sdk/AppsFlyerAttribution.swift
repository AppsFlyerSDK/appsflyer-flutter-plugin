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

        /// Identifies the *link*, not the delivery. Options and activity metadata are excluded so the
        /// two copies of one deep link — which differ in `sourceApplication` and nothing else — compare
        /// equal. See `isDuplicateDelivery(_:)`.
        var deepLinkIdentity: String {
            switch self {
            case let .openUrl(url, _):
                return "url\u{1}\(url.absoluteString)"
            case let .userActivity(activity):
                return "activity\u{1}\(activity.activityType)\u{1}\(activity.webpageURL?.absoluteString ?? "")"
            }
        }
    }

    /// How long after forwarding a link an identical one is treated as the UIScene duplicate rather
    /// than a new open. Flutter's replay lands in the same runloop turn, so this only has to be long
    /// enough to cover that hop; it is deliberately far shorter than any interval in which a person
    /// could open the same link twice on purpose.
    private static let duplicateDeliveryWindow: TimeInterval = 1

    private static let sharedInstance = AppsFlyerAttribution()

    private var isBridgeReady = false
    private var pendingRequests: [PendingRequest] = []
    /// Identity and monotonic timestamp of the last forwarded link — see `isDuplicateDelivery(_:)`.
    private var lastDelivery: (identity: String, at: TimeInterval)?
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
            lastDelivery = nil
        }
    }

    private func applyBridgeReady(owner: AnyObject) {
        bridgeReadyOwner = owner
        isBridgeReady = true
        let requests = pendingRequests
        pendingRequests.removeAll()
        requests.forEach(execute)
    }

    /// Whether this delivery is the second copy of a link the host already handed over.
    ///
    /// Under the UIScene lifecycle UIKit delivers deep links through the `scene:...` methods, but
    /// Flutter also replays every scene event through the `UIApplicationDelegate` methods so plugins
    /// predating the migration keep working. `AppsflyerSdkPlugin` implements both families, so one
    /// user action arrives here twice and Dart's `onDeepLinking` callback would run twice.
    ///
    /// Two properties keep this from suppressing anything real. It is scoped to hosts that declare
    /// `UIApplicationSceneManifest`, so an app on the application-delegate lifecycle — where no replay
    /// exists — is not affected at all. And it keys on the link itself rather than on which delegate
    /// method delivered it, so a host that forwards a URL manually from its own `AppDelegate` is still
    /// honored; only an identical link arriving twice in the same instant is dropped. Suppressing the
    /// application-delegate path wholesale would have broken exactly that manual forward.
    private func isDuplicateDelivery(_ request: PendingRequest) -> Bool {
        guard hostUsesSceneLifecycle else {
            return false
        }
        let identity = request.deepLinkIdentity
        // Monotonic: unaffected by wall-clock changes mid-session.
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastDelivery,
           last.identity == identity,
           now - last.at < Self.duplicateDeliveryWindow {
            return true
        }
        lastDelivery = (identity, now)
        return false
    }

    private func executeOrQueue(_ request: PendingRequest) {
        onMain { [self] in
            if isDuplicateDelivery(request) {
                return
            }
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

    /// Read once: the host's scene manifest cannot change during a process lifetime.
    private lazy var hostUsesSceneLifecycle: Bool =
        Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") != nil

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
