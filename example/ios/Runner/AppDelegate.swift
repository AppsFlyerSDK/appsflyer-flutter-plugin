import UIKit
import Flutter
import AppsFlyerLib
import AppTrackingTransparency

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
      AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        if  #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status) in
              switch status {
              case .denied:
                  print("AuthorizationSatus is denied")
              case .notDetermined:
                  print("AuthorizationSatus is notDetermined")
              case .restricted:
                  print("AuthorizationSatus is restricted")
              case .authorized:
                  print("AuthorizationSatus is authorized")
              @unknown default:
                  fatalError("Invalid authorization status")
              }
            }
          }
        }
}
