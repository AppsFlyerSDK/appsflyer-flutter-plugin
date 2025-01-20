#import <Flutter/Flutter.h>
#import "AppsFlyerAttribution.h"
#if __has_include(<AppsFlyerLib/AppsFlyerLib.h>) // from Pod
#import <AppsFlyerLib/AppsFlyerLib.h>
#else
#import "AppsFlyerLib.h"
#endif

@interface AppsflyerSdkPlugin: NSObject<FlutterPlugin>

@property (readwrite, nonatomic) BOOL isManualStart;

+ (FlutterMethodChannel*)callbackChannel;
+ (BOOL)gcdCallback;
+ (BOOL)oaoaCallback;
+ (BOOL)udpCallback;

@end

// Appsflyer JS objects
#define kAppsFlyerPluginVersion             @"6.15.1"
#define afDevKey                            @"afDevKey"
#define afAppId                             @"afAppId"
#define afIsDebug                           @"isDebug"
#define afManualStart                       @"manualStart"
#define afTimeToWaitForATTUserAuthorization @"timeToWaitForATTUserAuthorization"
#define afEventName                         @"eventName"
#define afEventValues                       @"eventValues"
#define afConversionData                    @"GCD"
#define afUDL                               @"UDL"
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
#define afOnDeepLinking                 @"onDeepLinking"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"
#define afGCDCallback                   @"onInstallConversionData"
#define afOAOACallback                  @"onAppOpenAttribution"
#define afUDPCallback                   @"onDeepLinking"
#define afGenerateInviteLinkSuccess     @"generateInviteLinkSuccess"
#define afGenerateInviteLinkFailure     @"generateInviteLinkFailure"
#define afAppInviteOneLinkID            @"setAppInviteOneLinkIDCallback"

// Stream Channels
#define afMethodChannel                 @"af-api"
#define afCallbacksMethodChannel        @"callbacks"
#define afEventChannel                  @"af-events"
#define afValidatePurchaseChannel       @"af-validate-purchase"

