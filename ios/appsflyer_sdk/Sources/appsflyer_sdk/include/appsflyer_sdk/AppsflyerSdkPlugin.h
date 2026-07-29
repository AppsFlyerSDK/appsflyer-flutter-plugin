#import <Flutter/Flutter.h>
#import "AppsFlyerAttribution.h"

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
#import <Flutter/FlutterSceneLifeCycle.h>
#endif

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
@interface AppsflyerSdkPlugin: NSObject<FlutterPlugin, FlutterStreamHandler, FlutterSceneLifeCycleDelegate>
#else
@interface AppsflyerSdkPlugin: NSObject<FlutterPlugin, FlutterStreamHandler>
#endif

@end

// Plugin version
#define kAppsFlyerPluginVersion             @"7.0.0"

// initSdk option keys (sent from Dart in the `init` RPC params map)
#define afDevKey                            @"afDevKey"
#define afAppId                             @"afAppId"
#define afIsDebug                           @"isDebug"
#define afTimeToWaitForATTUserAuthorization @"timeToWaitForATTUserAuthorization"
#define afConversionData                    @"GCD"
#define afUDL                               @"UDL"
#define afInviteOneLink                     @"appInviteOneLink"
#define afDisableCollectASA                 @"disableCollectASA"
#define afDisableAdvertisingIdentifier      @"disableAdvertisingIdentifier"

// Flutter channels
#define afMethodChannel                 @"af-api"
#define afEventChannel                  @"af-events"
