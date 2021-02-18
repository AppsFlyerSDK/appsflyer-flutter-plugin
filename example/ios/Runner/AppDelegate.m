#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "AppsflyerSdkPlugin.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

// Reports app open from a Universal Link for iOS 9 or above
- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
  }

//   Reports app open from deep link from apps which do not support Universal Links (Twitter) and for iOS8 and below
  - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
      [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    return YES;
  }

// Reports app open from deep link for iOS 10
  - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  options:(NSDictionary *) options {
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    return YES;
  }

@end
