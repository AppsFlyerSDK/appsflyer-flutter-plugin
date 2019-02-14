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
    }else if([@"waitForCustomerUserId" isEqualToString:call.method]){
        [self waitForCustomerId:call result:result];
    }else if([@"setUserEmails" isEqualToString:call.method]){
        [self setUserEmails:call result:result];
    }else if([ @"setUserEmailsWithCryptType" isEqualToString:call.method]){
        [self setUserEmailsWithCryptType:call result:result];
    }
    else if([@"updateServerUninstallToken" isEqualToString:call.method]){
        [self updateServerUninstallToken:call result:result];
    }else if([@"enableUninstallTracking" isEqualToString:call.method]){
        //
    }else if([@"enableLocationCollection" isEqualToString:call.method]){
        //
    }else if([@"stopTracking" isEqualToString:call.method]){
        [self stopTracking:call result:result];
    }else if([@"setIsUpdate" isEqualToString:call.method]){
        //
    }else if([@"setCustomerUserId" isEqualToString:call.method]){
        [self setCustomerUserId:call result:result];
    }else if([@"setCurrencyCode" isEqualToString:call.method ]){
        //
    }else if([@"setMinTimeBetweenSessions" isEqualToString:call.method]){
        [self setMinTimeBetweenSessions:call result:result];
    }else if([@"getHostPrefix" isEqualToString:call.method]){
        [self getHostPrefix:result];
    }else if([@"getHostName" isEqualToString:call.method]){
        [self getHostName:result];
    }else if([@"setHost" isEqualToString:call.method]){
        [self setHost:call result:result];
    }else if([@"setAdditionalData" isEqualToString:call.method]){
        [self setAdditionalData:call result:result];
    }else if([@"validateAndTrackInAppPurchase" isEqualToString:call.method]){
        [self validateAndTrackInAppPurchase:call result:result];
    }
    else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)getHostPrefix:(FlutterResult)result{
    result([[AppsFlyerTracker sharedTracker] hostPrefix]);
}

- (void)getHostName:(FlutterResult)result{
    result([[AppsFlyerTracker sharedTracker] host]);
}

- (void)setHost:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* hostName = call.arguments[@"hostName"];
    NSString* hostPrefix = call.arguments[@"hostPrefix"];
    [[AppsFlyerTracker sharedTracker] setHost:hostName withHostPrefix:hostPrefix];
    result(nil);
}

- (void)validateAndTrackInAppPurchase:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* publicKey = call.arguments[@"publicKey"];
    NSString* signature = call.arguments[@"signature"];
    NSString* price = call.arguments[@"price"];
    NSString* currency = call.arguments[@"currency"];
    NSDictionary* additionalParameters = call.arguments[@"additionalParameters"];
    [[AppsFlyerTracker sharedTracker] validateAndTrackInAppPurchase:publicKey price:price currency:currency transactionId:signature additionalParameters:additionalParameters
                                                            success:^(NSDictionary *response) {
                                                                NSLog(@"Success");
                                                                [self onValidateSuccess:response];
                                                            }
                                                            failure:^(NSError *error, id reponse) {
                                                                NSLog(@"Fail");
                                                                [self onValidateFail:error];
                                                            }];
    result(nil);
}

- (void)onValidateSuccess: (NSDictionary*) data{
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"data": data
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[message,afValidatePurchaseChannel] waitUntilDone:NO];
}

-(void)onValidateFail:(NSError*)error{
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"error": @"error connecting"
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[message,afValidatePurchaseChannel] waitUntilDone:NO];
}

- (void)setAdditionalData:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSDictionary* data = call.arguments[@"customData"];
    [[AppsFlyerTracker sharedTracker] setAdditionalData:data];
    result(nil);
}

- (void)setCustomerUserId:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* userId = call.arguments[@"id"];
    [[AppsFlyerTracker sharedTracker] setCustomerUserID:userId];
    result(nil);
}

- (void)stopTracking:(FlutterMethodCall*)call result:(FlutterResult)result{
    BOOL stopTracking = call.arguments[@"isTrackingStopped"];
    [[AppsFlyerTracker sharedTracker] setIsStopTracking:stopTracking];
    result(nil);
}

- (void)updateServerUninstallToken:(FlutterMethodCall*)call result:(FlutterResult)result{
    result(nil);
}

- (void)waitForCustomerId:(FlutterMethodCall*)call result:(FlutterResult)result{
    result(nil);
}

- (void)setUserEmailsWithCryptType:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSMutableArray *emails = call.arguments[@"emails"];
    NSArray *emaillsArray = [emails copy];
    NSNumber* cryptTypeInt = (id)call.arguments[@"cryptType"];
    EmailCryptType cryptType = (EmailCryptType)[cryptTypeInt integerValue];
    [[AppsFlyerTracker sharedTracker] setUserEmails:emaillsArray withCryptType:cryptType];
    result(nil);
}

- (void)setUserEmails:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSMutableArray *emails = call.arguments[@"emails"];
    NSArray *emailsArray = [emails copy];
    [[AppsFlyerTracker sharedTracker] setUserEmails:emailsArray withCryptType:EmailCryptTypeNone];
    result(nil);
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

- (void)setMinTimeBetweenSessions:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSInteger seconds = [(id)call.arguments[@"seconds"] integerValue];
    [AppsFlyerTracker sharedTracker].minTimeBetweenSessions = seconds;
    result(nil);
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
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[message,afEventChannel] waitUntilDone:NO];
}

-(void)onConversionDataRequestFailure:(NSError *) _errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnInstallConversionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[errorMessage,afEventChannel] waitUntilDone:NO];
}


- (void) onAppOpenAttribution:(NSDictionary*) attributionData {
    
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnAppOpenAttribution,
                              @"data": attributionData
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[message,afEventChannel] waitUntilDone:NO];
}

- (void) onAppOpenAttributionFailure:(NSError *)_errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnAttributionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[errorMessage,afEventChannel] waitUntilDone:NO];
}


-(void) handleCallback:(NSArray *) objArray{
    
    UIViewController *topMostViewControllerObj =  [[[UIApplication sharedApplication] delegate] window].rootViewController;
    FlutterViewController *flutterViewController = (FlutterViewController *)topMostViewControllerObj;
    
    NSDictionary* message = [objArray objectAtIndex:0];
    NSString* channel = [objArray objectAtIndex:1];
    
    NSError *error;
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:message
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
    if(!error){
        [flutterViewController sendOnChannel:channel message:dataFromDict binaryReply:^(NSData * _Nullable reply) {
            //
        }];
    }
}




@end

