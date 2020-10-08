#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerStreamHandler.h"

@implementation AppsflyerSdkPlugin {
    FlutterEventChannel *_eventChannel;
    FlutterMethodChannel *_callbackChannel;
    AppsFlyerStreamHandler *_streamHandler;
    // Callbacks
    NSMutableArray* callbackById;
}

- (instancetype)initWithMessenger:(nonnull NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        
        _streamHandler = [[AppsFlyerStreamHandler alloc] init];
        _callbackChannel = [FlutterMethodChannel methodChannelWithName:afCallbacksMethodChannel binaryMessenger:messenger];
        _eventChannel = [FlutterEventChannel eventChannelWithName:afEventChannel binaryMessenger:messenger];
        [_eventChannel setStreamHandler:_streamHandler];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    id<FlutterBinaryMessenger> messenger = [registrar messenger];
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
    FlutterMethodChannel *callbackChannel = [FlutterMethodChannel methodChannelWithName:afCallbacksMethodChannel binaryMessenger:messenger];
    AppsflyerSdkPlugin *instance = [[AppsflyerSdkPlugin alloc] initWithMessenger:messenger];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addMethodCallDelegate:instance channel:callbackChannel];
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
    }else if([@"generateInviteLink" isEqualToString:call.method]){
        [self generateInviteLink:call result:result];
    }else if([@"setAppInviteOneLinkID" isEqualToString:call.method]){
        [self setAppInviteOneLinkID:call result:result];
    }else if([@"logCrossPromotionImpression" isEqualToString:call.method]){
        [self logCrossPromotionImpression:call result:result];
    }else if([@"logCrossPromotionAndOpenStore" isEqualToString:call.method]){
        [self logCrossPromotionAndOpenStore:call result:result];
    }else if([@"startListening" isEqualToString:call.method]){
        [self startListening:call result:result];
    }
    else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)startListening:(FlutterMethodCall*)call result:(FlutterResult)result{
    // Prepare callback dictionary
    if (self->callbackById == nil) self->callbackById = [NSMutableArray array];

    NSString* callbackId = call.arguments;
    [self->callbackById addObject:callbackId];
}

- (void)generateInviteLink:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* customerID = call.arguments[@"customerID"];
    NSString* referrerImageUrl = call.arguments[@"referrerImageUrl"];
    NSString* brandDomain = call.arguments[@"brandDomain"];
    NSString* baseDeeplink = call.arguments[@"baseDeeplink"];
    NSString* referrerName = call.arguments[@"referrerName"];
    NSString* channel = call.arguments[@"channel"];
    NSString* campaign = call.arguments[@"campaign"];
    
    [AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:^AppsFlyerLinkGenerator * _Nonnull(AppsFlyerLinkGenerator * _Nonnull generator) {
        [generator setChannel:channel];
        [generator setCampaign:campaign];
        [generator setBrandDomain:brandDomain];
        [generator setBaseDeeplink:baseDeeplink];
        [generator setReferrerName:referrerName];
        [generator setReferrerImageURL:referrerImageUrl];
        [generator setReferrerCustomerId:customerID];
        
        return generator;
    } completionHandler:^(NSURL * _Nullable url) {
        NSString * resultURL = url.absoluteString;
                    if(resultURL != nil){
                        if([self->callbackById containsObject:@"successGenerateInviteLink"]){
                        [self->_callbackChannel invokeMethod:@"callListener" arguments:@{
                            @"id": @"generateInviteUrl",
                            @"data":resultURL
                        }];
                        }
                    }
    }];
    
    result(nil);
}

- (void)setAppInviteOneLinkID:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* oneLinkID = call.arguments[@"oneLinkID"];
    [AppsFlyerLib shared].appInviteOneLinkID = oneLinkID;
    result(nil);
}

- (void)logCrossPromotionImpression:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* appId = call.arguments[@"appId"];
    NSString* campaign = call.arguments[@"campaign"];
    NSDictionary* parameters = call.arguments[@"data"];
    
    [AppsFlyerCrossPromotionHelper logCrossPromoteImpression:appId campaign:campaign parameters:parameters];
}

- (void)logCrossPromotionAndOpenStore:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* campaign = call.arguments[@"campaign"];
    NSDictionary* customParams = call.arguments[@"params"];
    
    [AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:^AppsFlyerLinkGenerator * _Nonnull(AppsFlyerLinkGenerator * _Nonnull generator) {
                if (campaign != nil && ![campaign isEqualToString:@""]) {
                    [generator setCampaign:campaign];
                }
                if (![customParams isKindOfClass:[NSNull class]]) {
                    [generator addParameters:customParams];
                }

                return generator;
            } completionHandler: ^(NSURL * _Nullable url) {
                NSString *appLink = url.absoluteString;
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appLink] options:@{} completionHandler:^(BOOL success) {
                    }];
                } else {
                    // Fallback on earlier versions
                }
            }];
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
    BOOL stop = call.arguments[@"isStopped"];
    [AppsFlyerLib shared].isStopped = stop;
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
    NSTimeInterval timeToWaitForATTUserAuthorization = 0;
    BOOL isDebug = NO;
    BOOL isConversionData = NO;
    
    id isDebugValue = nil;
    id isConversionDataValue = nil;

    devKey = call.arguments[afDevKey];
    appId = call.arguments[afAppId];
    timeToWaitForATTUserAuthorization = [(id)call.arguments[afTimeToWaitForATTUserAuthorization] doubleValue];

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
    
    [AppsFlyerLib shared].appInviteOneLinkID = @"TS12";
    [AppsFlyerLib shared].appleAppID = appId;
    [AppsFlyerLib shared].appsFlyerDevKey = devKey;
    [AppsFlyerLib shared].isDebug = isDebug;
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
