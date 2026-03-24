import Flutter
import UIKit

/// Custom scene delegate that explicitly forwards URL contexts to AppDelegate.
/// FlutterSceneDelegate.scene(_:openURLContexts:) does not reliably reach
/// registered plugins (e.g. AppsFlyer) on iOS 18. Forwarding via
/// application(_:open:url:options:) in FlutterAppDelegate guarantees
/// the URL reaches all plugin handlers.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      _ = UIApplication.shared.delegate?.application?(
        UIApplication.shared,
        open: context.url,
        options: [:]
      )
    }
  }
}
