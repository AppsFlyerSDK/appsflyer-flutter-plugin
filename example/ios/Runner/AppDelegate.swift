import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // QA: when launched via `simctl launch ... -deepLinkURL "<url>"`, replay
    // the URL through `application:openURL:options:` so the AppsFlyer plugin
    // sees it as a real custom-scheme open. Lets iOS-simulator CI bypass the
    // iOS 17/18 "Open in <App>?" confirmation prompt that `simctl openurl`
    // triggers and that nothing in a non-interactive run can dismiss. The
    // launch arg is only set by the e2e runner, so production launches and
    // real user URL schemes are unaffected.
    let args = ProcessInfo.processInfo.arguments
    let url: URL? = {
      if let idx = args.firstIndex(of: "-deepLinkURL"),
         idx + 1 < args.count,
         let u = URL(string: args[idx + 1]) {
        return u
      }
      // simctl launch also surfaces `-key value` pairs as transient
      // NSUserDefaults entries; read both for resilience.
      if let s = UserDefaults.standard.string(forKey: "deepLinkURL"),
         let u = URL(string: s) {
        return u
      }
      return nil
    }()
    if let url = url {
      // Delay long enough for the Flutter engine to spin up, MainPage to
      // initState, and AppsflyerSdk.initSdk + startSDK to complete on the
      // Dart side. The test plan's wait_after_trigger_sec is 12s, leaving
      // ample margin.
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self, weak application] in
        guard let self = self, let application = application else { return }
        _ = self.application(application, open: url, options: [:])
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
