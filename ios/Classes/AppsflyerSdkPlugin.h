#import <Flutter/Flutter.h>
#import <AppsFlyerLib/AppsFlyerLib.h>

@interface AppsflyerSdkPlugin: NSObject<FlutterPlugin>

+ (NSMutableArray*)callbackById;
+ (FlutterMethodChannel*)callbackChannel;

@end

// Appsflyer JS objects
#define afDevKey                            @"afDevKey"
#define afAppId                             @"afAppId"
#define afIsDebug                           @"isDebug"
#define afTimeToWaitForATTUserAuthorization @"timeToWaitForATTUserAuthorization"
#define afEventName                         @"eventName"
#define afEventValues                       @"eventValues"
#define afConversionData                    @"GCD"
#define afInviteOneLink                     @"appInviteOneLink"
#define afDisableCollectASA                 @"disableCollectASA"
#define afDisableAdvertisingIdentifier      @"disableAdvertisingIdentifier"

// Appsflyer native objects
#define afOnInstallConversionData       @"onInstallConversionData"
#define afSuccess                       @"success"
#define afFailure                       @"failure"
#define afOnAttributionFailure          @"onAttributionFailure"
#define afValidatePurchase              @"validatePurchase"
#define afOnAppOpenAttribution          @"onAppOpenAttribution"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"
#define afGCDCallback                   @"onInstallConversionData"
#define afOAOACallback                  @"onAppOpenAttribution"

// Stream Channels
#define afMethodChannel                 @"af-api"
#define afCallbacksMethodChannel        @"callbacks"
#define afEventChannel                  @"af-events"
#define afValidatePurchaseChannel       @"af-validate-purchase"
