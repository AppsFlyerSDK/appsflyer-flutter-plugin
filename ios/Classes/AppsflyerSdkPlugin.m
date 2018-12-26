#import "AppsflyerSdkPlugin.h"

@implementation AppsflyerSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:afMethodChannel
                                     binaryMessenger:[registrar messenger]];
    AppsflyerSdkPlugin* instance = [[AppsflyerSdkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if([@"initSdk" isEqualToString:call.method]){
        [self initSdkWithCall:call result:result];
    }else if([@"trackEvent" isEqualToString:call.method]){
        [self trackEventWithCall:call result:result];
    }else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)initSdkWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    
    NSString* devKey = nil;
    NSString* appId = nil;
    BOOL isDebug = NO;
    BOOL isConversionData = NO;
    
        id isDebugValue = nil;
        id isConversionDataValue = nil;
        devKey = call.arguments[afDevKey];
        appId = call.arguments[afAppId];
        
        isDebugValue = call.arguments[afIsDebug];
        if ([isDebugValue isKindOfClass:[NSNumber class]]) {
            // isDebug is a boolean that will come through as an NSNumber
            isDebug = [(NSNumber*)isDebugValue boolValue];
        }
        isConversionDataValue = call.arguments[afConversionData];
        if ([isConversionDataValue isKindOfClass:[NSNumber class]]) {
            isConversionData = [(NSNumber*)isConversionDataValue boolValue];
        }
    
    if(isConversionData == YES){
        [AppsFlyerTracker sharedTracker].delegate = self;
    }
    
    [AppsFlyerTracker sharedTracker].appleAppID = appId;
    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = devKey;
    [AppsFlyerTracker sharedTracker].isDebug = isDebug;
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    result(@"OK");
}

-(void)trackEventWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString *eventName =  call.arguments[afEventName];
    NSDictionary *eventValues = call.arguments[afEventValues];
    
    [[AppsFlyerTracker sharedTracker] trackEvent:eventName withValues:eventValues];
    result(@YES);
}

- (void)appDidBecomeActive {
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    NSLog(@"App Did Become Active");
}

-(void)onConversionDataReceived:(NSDictionary*) installData {
    
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnInstallConversionDataLoaded,
                              @"data": installData
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}

-(void)onConversionDataRequestFailure:(NSError *) _errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnInstallConversionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
}


- (void) onAppOpenAttribution:(NSDictionary*) attributionData {
    
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnAppOpenAttribution,
                              @"data": attributionData
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}

- (void) onAppOpenAttributionFailure:(NSError *)_errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnAttributionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
}


-(void) handleCallback:(NSDictionary *) message{
    
    UIViewController *topMostViewControllerObj =  [[[UIApplication sharedApplication] delegate] window].rootViewController;
    FlutterViewController *flutterViewController = (FlutterViewController *)topMostViewControllerObj;
    
    NSError *error;
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:message
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
    if(!error){
        [flutterViewController sendOnChannel:afEventChannel message:dataFromDict binaryReply:^(NSData * _Nullable reply) {
            //
        }];
    }
}
@end
