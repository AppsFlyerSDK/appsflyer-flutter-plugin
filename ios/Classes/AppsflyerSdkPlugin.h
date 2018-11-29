#import <Flutter/Flutter.h>
#import <AppsFlyerFramework/AppsFlyerLib/AppsFlyerTracker.h>


@interface AppsflyerSdkPlugin : NSObject<FlutterPlugin, AppsFlyerTrackerDelegate>
- (void)onConversionDataReceived:(NSDictionary*) installData;
- (void)onConversionDataRequestFailure:(NSError *) error;
@end

// Appsflyer JS objects
#define afDevKey                        @"afDevKey"
#define afAppId                         @"afAppId"
#define afIsDebug                        @"isDebug"

// Appsflyer native objects
#define afConversionData                @"onInstallConversionDataListener"
#define afOnInstallConversionData       @"onInstallConversionData"
#define afSuccess                       @"success"
#define afFailure                       @"failure"
#define afOnAttributionFailure          @"onAttributionFailure"
#define afOnAppOpenAttribution          @"onAppOpenAttribution"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"
