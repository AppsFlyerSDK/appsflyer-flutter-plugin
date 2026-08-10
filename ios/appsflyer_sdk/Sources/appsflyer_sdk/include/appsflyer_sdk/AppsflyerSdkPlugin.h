#import <Flutter/Flutter.h>

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
#define kAppsFlyerPluginVersion             @"7.0.1"

// Flutter channels
#define afMethodChannel                 @"af-api"
#define afEventChannel                  @"af-events"
