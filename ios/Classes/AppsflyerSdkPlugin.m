#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerStreamHandler.h"

@implementation AppsflyerSdkPlugin {
    FlutterEventChannel *_eventChannel;
    AppsFlyerStreamHandler *_streamHandler;
}

- (instancetype)initWithMessenger:(nonnull NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        
        _streamHandler = [[AppsFlyerStreamHandler alloc] init];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:afEventChannel binaryMessenger:messenger];
        [_eventChannel setStreamHandler:_streamHandler];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    id<FlutterBinaryMessenger> messenger = [registrar messenger];
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
    AppsflyerSdkPlugin *instance = [[AppsflyerSdkPlugin alloc] initWithMessenger:messenger];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if([@"initSdk" isEqualToString:call.method]){
        [self initSdkWithCall:call result:result];
    }else if([@"getSDKVersion" isEqualToString:call.method]){
        [self getSDKVersion:result];
    }
    else if([@"logEvent" isEqualToString:call.method]){
        [self logEventWithCall:call result:result];
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
    }else if([@"stop" isEqualToString:call.method]){
        [self stop:call result:result];
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
    }else if([@"validateAndLogInAppPurchase" isEqualToString:call.method]){
        [self validateAndLogInAppPurchase:call result:result];
    }else if([@"getAppsFlyerUID" isEqualToString:call.method]){
        [self getAppsFlyerUID:result];
    }else if([@"setSharingFilter" isEqualToString:call.method]){
        [self setSharingFilter:call result:result];
    }else if([@"setSharingFilterForAllPartners" isEqualToString:call.method]){
        [self setSharingFilterForAllPartners:result];
    }
    else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)setSharingFilter:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSArray* filters = call.arguments;
    [[AppsFlyerLib shared] setSharingFilter:filters];
    result(nil);
}

- (void)setSharingFilterForAllPartners:(FlutterResult)result{
    [[AppsFlyerLib shared] setSharingFilterForAllPartners];
    result(nil);
}

- (void)getAppsFlyerUID:(FlutterResult)result{
    result([[AppsFlyerLib shared] getAppsFlyerUID]);
}

- (void)getHostPrefix:(FlutterResult)result{
    result([[AppsFlyerLib shared] hostPrefix]);
}

- (void)getHostName:(FlutterResult)result{
    result([[AppsFlyerLib shared] host]);
}

- (void)getSDKVersion:(FlutterResult)result{
    result([[AppsFlyerLib shared] getSDKVersion]);
}

- (void)setHost:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* hostName = call.arguments[@"hostName"];
    NSString* hostPrefix = call.arguments[@"hostPrefix"];
    [[AppsFlyerLib shared] setHost:hostName withHostPrefix:hostPrefix];
    result(nil);
}

- (void)validateAndLogInAppPurchase:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* publicKey = call.arguments[@"publicKey"];
    NSString* signature = call.arguments[@"signature"];
    NSString* price = call.arguments[@"price"];
    NSString* currency = call.arguments[@"currency"];
    NSDictionary* additionalParameters = call.arguments[@"additionalParameters"];
    [[AppsFlyerLib shared] validateAndLogInAppPurchase:publicKey price:price currency:currency transactionId:signature additionalParameters:additionalParameters
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
    
    [_streamHandler sendObject:message];
}

-(void)onValidateFail:(NSError*)error{
    NSDictionary* message = @{
                              @"type": afValidatePurchase,
                              @"status": afSuccess,
                              @"error": @"error connecting"
                              };
    [_streamHandler sendObject:message];
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[message,afValidatePurchaseChannel] waitUntilDone:NO];
}

- (void)setAdditionalData:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSDictionary* data = call.arguments[@"customData"];
    [[AppsFlyerLib shared] setAdditionalData:data];
    result(nil);
}

- (void)setCustomerUserId:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* userId = call.arguments[@"id"];
    [[AppsFlyerLib shared] setCustomerUserID:userId];
    result(nil);
}

- (void)stop:(FlutterMethodCall*)call result:(FlutterResult)result{
    BOOL stopTracking = call.arguments[@"isTrackingStopped"];
    [AppsFlyerLib shared].isStopped = stopTracking;
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
    [[AppsFlyerLib shared] setUserEmails:emaillsArray withCryptType:cryptType];
    result(nil);
}

- (void)setUserEmails:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSMutableArray *emails = call.arguments[@"emails"];
    NSArray *emailsArray = [emails copy];
    [[AppsFlyerLib shared] setUserEmails:emailsArray withCryptType:EmailCryptTypeNone];
    result(nil);
}

- (void)initSdkWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* devKey = nil;
    NSString* appId = nil;
    NSTimeInterval timeToWaitForAdvertiserID = 0;
    BOOL isDebug = NO;
    BOOL isConversionData = NO;
    
    id isDebugValue = nil;
    id isConversionDataValue = nil;

    devKey = call.arguments[afDevKey];
    appId = call.arguments[afAppId];
    timeToWaitForAdvertiserID = [(id)call.arguments[afTimeToWaitForAdvertiserID] doubleValue];

    isDebugValue = call.arguments[afIsDebug];
    if ([isDebugValue isKindOfClass:[NSNumber class]]) {
        // isDebug is a boolean that will come through as an NSNumber
        isDebug = [(NSNumber*)isDebugValue boolValue];
    }
    isConversionDataValue = call.arguments[afConversionData];
    if ([isConversionDataValue isKindOfClass:[NSNumber class]]) {
        isConversionData = [(NSNumber*)isConversionDataValue boolValue];
    }
    
    if (isConversionData == YES) {
        [[AppsFlyerLib shared] setDelegate:_streamHandler];
    }
    
    [AppsFlyerLib shared].appleAppID = appId;
    [AppsFlyerLib shared].appsFlyerDevKey = devKey;
    [AppsFlyerLib shared].isDebug = isDebug;
    if(timeToWaitForAdvertiserID > 0){
        if (@available(iOS 14, *)) {
            [[AppsFlyerLib shared] waitForAdvertisingIdentifierWithTimeoutInterval:timeToWaitForAdvertiserID];
        }
    }

    [[AppsFlyerLib shared] start];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    result(@{@"status": @"OK"});
}

-(void)logEventWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString *eventName =  call.arguments[afEventName];
    NSDictionary *eventValues = call.arguments[afEventValues];
    
    [[AppsFlyerLib shared] logEvent:eventName withValues:eventValues];
    //TODO: Add callback handler
    result(@YES);
}

- (void)setMinTimeBetweenSessions:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSInteger seconds = [(id)call.arguments[@"seconds"] integerValue];
    [AppsFlyerLib shared].minTimeBetweenSessions = seconds;
    result(nil);
}

- (void)appDidBecomeActive {
    [[AppsFlyerLib shared] start];
    NSLog(@"App Did Become Active");
}

+ (FlutterViewController*) getViewController{
    UIViewController *topMostViewControllerObj =  [[[UIApplication sharedApplication] delegate] window].rootViewController;
    FlutterViewController *flutterViewController = (FlutterViewController *)topMostViewControllerObj;
    
    return flutterViewController;
}

-(void) handleCallback:(NSArray *) objArray{
    NSDictionary* message = [objArray objectAtIndex:0];
    //NSString* channel = [objArray objectAtIndex:1];
    
    NSError *error;
    NSData *dataFromDict = [NSJSONSerialization dataWithJSONObject:message
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"af-events" object:dataFromDict];
    //if(!error){
        //[flutterViewController sendOnChannel:channel message:dataFromDict binaryReply:^(NSData * _Nullable reply) {
            //
        //}];
    //}
}


@end
