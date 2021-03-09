#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerStreamHandler.h"

@implementation AppsflyerSdkPlugin {
    FlutterEventChannel *_eventChannel;
    AppsFlyerStreamHandler *_streamHandler;
}
static NSMutableArray* _callbackById;
static FlutterMethodChannel* _callbackChannel;
static BOOL _gcdCallback = false;
static BOOL _oaoaCallback = false;
static BOOL _udpCallback = false;
static BOOL _isPushNotificationEnabled = false;
static BOOL _isSandboxEnabled = false;

+ (FlutterMethodChannel*)callbackChannel{
    return _callbackChannel;
}

+ (BOOL)gcdCallback{
    return _gcdCallback;
}

+ (BOOL)oaoaCallback{
    return _oaoaCallback;
}

+ (BOOL)udpCallback{
    return _udpCallback;
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
    }else if([@"validateAndLogInAppIosPurchase" isEqualToString:call.method]){
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
    }else if([@"setOneLinkCustomDomain" isEqualToString:call.method]){
        [self setOneLinkCustomDomain:call result:result];
    }else if([@"setPushNotification" isEqualToString:call.method]){
        [self setPushNotification:call result:result];
    }else if([@"useReceiptValidationSandbox" isEqualToString:call.method]){
        [self useReceiptValidationSandbox:call result:result];
    }
    else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)useReceiptValidationSandbox:(FlutterMethodCall*)call result:(FlutterResult)result{
    bool isSandboxEnabled = call.arguments;
    _isSandboxEnabled = isSandboxEnabled;
    [AppsFlyerLib shared].useReceiptValidationSandbox = _isSandboxEnabled;
    result(nil);
}

- (void)setPushNotification:(FlutterMethodCall*)call result:(FlutterResult)result{
    bool isPushNotificationEnabled = call.arguments;
    _isPushNotificationEnabled = isPushNotificationEnabled;
    result(nil);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if(_isPushNotificationEnabled){
        [[AppsFlyerLib shared] handlePushNotification:userInfo];
    }
}

- (void)setOneLinkCustomDomain:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSArray* brandDomains = call.arguments;
    [[AppsFlyerLib shared] setOneLinkCustomDomains:brandDomains];
    result(nil);
}

- (void)startListening:(FlutterMethodCall*)call result:(FlutterResult)result{
    // Prepare callback dictionary
    if (_callbackById == nil) _callbackById = [NSMutableArray array];

    NSString* callbackId = call.arguments;
    if ([callbackId isEqualToString:afGCDCallback]){
        _gcdCallback = true;
    }
    if ([callbackId isEqualToString:afOAOACallback]){
        _oaoaCallback = true;
    }
    if ([callbackId isEqualToString:afUDPCallback]){
        _udpCallback = true;
    }
    [_callbackById addObject:callbackId];
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
        NSDictionary* resultURLObject;
                    if(resultURL != nil){
                        resultURLObject = @{
                            @"userInviteURL": resultURL
                        };
                        if([_callbackById containsObject:afGenerateInviteLinkSuccess]){
                            [_streamHandler sendResponseToFlutter:afGenerateInviteLinkSuccess status:afSuccess data:resultURLObject];
                        }
                    }else{
                        resultURLObject = @{
                            @"error": @"The URL wasn't generated!"
                        };
                        if([_callbackById containsObject:afGenerateInviteLinkFailure]){
                            [_streamHandler sendResponseToFlutter:afGenerateInviteLinkFailure status:afFailure data:resultURLObject];
                        }
                    }
    }];
    
    result(nil);
}

- (void)setAppInviteOneLinkID:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* oneLinkID = call.arguments[@"oneLinkID"];
    [AppsFlyerLib shared].appInviteOneLinkID = oneLinkID;
    if([_callbackById containsObject:@"setAppInviteOneLinkIDCallback"]){
        NSDictionary* message = @{
          @"status": afSuccess
        };
        [_streamHandler sendResponseToFlutter:afAppInviteOneLinkID status:afSuccess data:message];
    }
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
    NSString* productIdentifier = call.arguments[@"productIdentifier"];
    NSString* price = call.arguments[@"price"];
    NSString* currency = call.arguments[@"currency"];
    NSString* transactionId = call.arguments[@"transactionId"];
    NSDictionary* additionalParameters = call.arguments[@"additionalParameters"];
    
    [[AppsFlyerLib shared] validateAndLogInAppPurchase:productIdentifier price:price currency:currency transactionId:transactionId additionalParameters:additionalParameters
                                                            success:^(NSDictionary *response) {
                                                                NSLog(@"AppsFlyer Debug: validateAndLogInAppIosPurchase Success!");
                                                                [self onValidateSuccess:response];
                                                            }
                                                            failure:^(NSError *error, id reponse) {
                                                                NSLog(@"AppsFlyer Debug: validateAndLogInAppIosPurchase failed with Error: %@", error);
                                                                [self onValidateFail:error];
                                                            }];
    
    result(nil);
}

- (void)onValidateSuccess: (NSDictionary*) data{
    [_streamHandler sendResponseToFlutter:afValidatePurchase status:afSuccess data:data];
}

-(void)onValidateFail:(NSError*)error{
    NSDictionary* errorObject = @{
                @"error": error.description
                };
    [_streamHandler sendResponseToFlutter:afValidatePurchase status:afFailure data:errorObject];
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:@[errorObject,afValidatePurchaseChannel] waitUntilDone:NO];
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
    NSString* deviceToken = call.arguments[@"token"];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *deviceTokenData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [deviceToken length]/2; i++) {
        byte_chars[0] = [deviceToken characterAtIndex:i*2];
        byte_chars[1] = [deviceToken characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [deviceTokenData appendBytes:&whole_byte length:1];
    }
    [[AppsFlyerLib shared] registerUninstall:deviceTokenData];
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
    NSString* appInviteOneLink = nil;
    BOOL disableCollectASA = NO;
    BOOL disableAdvertisingIdentifier = NO;
    NSTimeInterval timeToWaitForATTUserAuthorization = 0;
    BOOL isDebug = NO;
    BOOL isConversionData = NO;
    BOOL isUDP = NO;
    
    id isDebugValue = nil;
    id isConversionDataValue = nil;
    id isUDPValue = nil;
    id isDisableCollectASA = nil;
    id isDisableAdvertisingIdentifier = nil;

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

    isUDPValue = call.arguments[afUDL];
    if ([isUDPValue isKindOfClass:[NSNumber class]]) {
        isUDP = [(NSNumber*)isUDPValue boolValue];
        if(isUDP == YES){
            [AppsFlyerLib shared].deepLinkDelegate = _streamHandler;
        }
    }
    
    appInviteOneLink = call.arguments[afInviteOneLink];
    if(appInviteOneLink != nil){
        [AppsFlyerLib shared].appInviteOneLinkID = appInviteOneLink;
    }
    
    isDisableCollectASA = call.arguments[afDisableCollectASA];
    if ([isDisableCollectASA isKindOfClass:[NSNumber class]]) {
        // isDebug is a boolean that will come through as an NSNumber
        disableCollectASA = [(NSNumber*)isDisableCollectASA boolValue];
    }
    isDisableAdvertisingIdentifier = call.arguments[afDisableAdvertisingIdentifier];
    if ([isDisableAdvertisingIdentifier isKindOfClass:[NSNumber class]]) {
        // isDebug is a boolean that will come through as an NSNumber
        disableAdvertisingIdentifier = [(NSNumber*)isDisableAdvertisingIdentifier boolValue];
    }

    
    [AppsFlyerLib shared].disableCollectASA = disableCollectASA;
    [AppsFlyerLib shared].disableAdvertisingIdentifier = disableAdvertisingIdentifier;
    [AppsFlyerLib shared].appleAppID = appId;
    [AppsFlyerLib shared].appsFlyerDevKey = devKey;
    [AppsFlyerLib shared].isDebug = isDebug;
    [[AppsFlyerLib shared] start];

    //post notification for the deep link object that the bridge is set and he can handle deep link
    [AppsFlyerAttribution shared].isBridgeReady = YES;
   [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
    
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
