#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <AppsFlyerLib/AppsFlyerLib.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    
    // The following block is for applications wishing to collect IDFA.
        // for iOS 14 and above - The user will be prompted for permission to collect IDFA.
        //                        If permission granted, the IDFA will be collected by the SDK.
        // for iOS 13 and below - The IDFA will be collected by the SDK. The user will NOT be prompted for permission.
        if (@available(iOS 14, *)) {
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                //....
            }];
        }
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

// Reports app open from a Universal Link for iOS 9 or above
- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[AppsFlyerLib shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
  }

//   Reports app open from deep link from apps which do not support Universal Links (Twitter) and for iOS8 and below
  - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    [[AppsFlyerLib shared] handleOpenURL:url sourceApplication:sourceApplication withAnnotation:annotation];
    return YES;
  }

  // Reports app open from deep link for iOS 10
  - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  options:(NSDictionary *) options {
    [[AppsFlyerLib shared] handleOpenUrl:url options:options];
    return YES;
  }

@end
