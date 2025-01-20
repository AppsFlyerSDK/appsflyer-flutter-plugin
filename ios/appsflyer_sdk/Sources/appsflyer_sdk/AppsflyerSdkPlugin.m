#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerStreamHandler.h"
#import <objc/message.h>


typedef void (*bypassDidFinishLaunchingWithOption)(id, SEL, NSInteger);
typedef void (*bypassDisableAdvertisingIdentifier)(id, SEL, BOOL);
typedef void (*bypassWaitForATTUserAuthorization)(id, SEL, NSTimeInterval);


@implementation AppsflyerSdkPlugin {
    FlutterEventChannel *_eventChannel;
    AppsFlyerStreamHandler *_streamHandler;
    
}
static NSMutableArray* _callbackById;
static FlutterMethodChannel* _callbackChannel;
static FlutterMethodChannel* _methodChannel;
static BOOL _gcdCallback = false;
static BOOL _oaoaCallback = false;
static BOOL _udpCallback = false;
static BOOL _isPushNotificationEnabled = false;
static BOOL _isSandboxEnabled = false;
static BOOL _isSKADEnabled = false;


+ (FlutterMethodChannel*)callbackChannel{
    return _callbackChannel;
}

+ (FlutterMethodChannel*)methodChannel{
    return _methodChannel;
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
        _methodChannel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
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
    [registrar addApplicationDelegate:instance];
    
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if([@"initSdk" isEqualToString:call.method]){
        [self initSdkWithCall:call result:result];
    }else if([@"getSDKVersion" isEqualToString:call.method]){
        [self getSDKVersion:result];
    }else if([@"startSDK" isEqualToString:call.method]){
        [self startSDK:call result:result];
    }else if([@"startSDKwithHandler" isEqualToString:call.method]){
        [self startSDKwithHandler:call result:result];
    } else if([@"logEvent" isEqualToString:call.method]){
        [self logEventWithCall:call result:result];
    }else if([@"waitForCustomerUserId" isEqualToString:call.method]){
        [self waitForCustomerId:call result:result];
    }else if([@"setUserEmails" isEqualToString:call.method]){
        [self setUserEmails:call result:result];
    }else if([@"updateServerUninstallToken" isEqualToString:call.method]){
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
    }else if([@"setCustomerIdAndLogSession" isEqualToString:call.method]){
        [self setCustomerUserId:call result:result];
    }else if([@"setCurrencyCode" isEqualToString:call.method ]){
        [self setCurrencyCode:call result:result];
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
    }else if([@"sendPushNotificationData" isEqualToString:call.method]){
        [self sendPushNotificationData:call result:result];
    }else if([@"useReceiptValidationSandbox" isEqualToString:call.method]){
        [self useReceiptValidationSandbox:call result:result];
    }else if([@"enableFacebookDeferredApplinks" isEqualToString:call.method]){
        [self enableFacebookDeferredApplinks:call result:result];
    }else if([@"anonymizeUser" isEqualToString:call.method]){
        [self anonymizeUser:call result:result];
    }else if([@"disableSKAdNetwork" isEqualToString:call.method]){
        [self disableSKAdNetwork:call result:result];
    }else if([@"setCurrentDeviceLanguage" isEqualToString:call.method]){
        [self setCurrentDeviceLanguage:call result:result];
    }else if([@"setSharingFilterForPartners" isEqualToString:call.method]){
        [self setSharingFilterForPartners:call result:result];
    }else if([@"setDisableAdvertisingIdentifiers" isEqualToString:call.method]){
        [self setDisableAdvertisingIdentifiers:call result:result];
    }else if([@"setPartnerData" isEqualToString:call.method]){
        [self setPartnerData:call result:result];
    }else if([@"setResolveDeepLinkURLs" isEqualToString:call.method]){
        [self setResolveDeepLinkURLs:call result:result];
    }else if([@"addPushNotificationDeepLinkPath" isEqualToString:call.method]){
        [self addPushNotificationDeepLinkPath:call result:result];
    }else if([@"enableTCFDataCollection" isEqualToString:call.method]){
        [self enableTCFDataCollection:call result:result];
    }else if([@"setConsentData" isEqualToString:call.method]){
        [self setConsentData:call result:result];
    }else if([@"logAdRevenue" isEqualToString:call.method]){
        [self logAdRevenue:call result:result];
    }
    else{
        result(FlutterMethodNotImplemented);
    }
}

-(void)startSDKwithHandler:(FlutterMethodCall*)call result:(FlutterResult)result {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[AppsFlyerLib shared] startWithCompletionHandler:^(NSDictionary<NSString *,id> *dictionary, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [_methodChannel invokeMethod:@"onError" arguments:@{@"errorCode": @(error.code), @"errorMessage": error.localizedDescription ?: @"Unknown error"}];
            } else if (dictionary) {
                [_methodChannel invokeMethod:@"onSuccess" arguments:dictionary];
            } else {
                NSString *genericErrorMsg = @"SDK started without error or success data";
                [_methodChannel invokeMethod:@"onError" arguments:@{@"errorCode": @(0), @"errorMessage": genericErrorMsg}];
            }
            result(nil);
        });
    }];
}

- (void)startSDK:(FlutterMethodCall*)call result:(FlutterResult)result {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[AppsFlyerLib shared] start];
    result(nil);
}

- (void)setConsentData:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* consentDict = call.arguments[@"consentData"];
    
    BOOL isUserSubjectToGDPR = [consentDict[@"isUserSubjectToGDPR"] boolValue];
    BOOL hasConsentForDataUsage = [consentDict[@"hasConsentForDataUsage"] boolValue];
    BOOL hasConsentForAdsPersonalization = [consentDict[@"hasConsentForAdsPersonalization"] boolValue];
    
    AppsFlyerConsent *consentData;
    if(isUserSubjectToGDPR){
        consentData = [[AppsFlyerConsent alloc] initForGDPRUserWithHasConsentForDataUsage:hasConsentForDataUsage
                                                          hasConsentForAdsPersonalization:hasConsentForAdsPersonalization];
    }else{
        consentData = [[AppsFlyerConsent alloc] initNonGDPRUser];
    }
    
    [[AppsFlyerLib shared] setConsentData:consentData];
    result(nil);
}

- (void)logAdRevenue:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        NSString *monetizationNetwork = [self requireNonNullArgumentWithCall:call result:result argumentName:@"monetizationNetwork" errorCode:@"NULL_MONETIZATION_NETWORK"];
        if (monetizationNetwork == nil) return;
        
        NSString *currencyIso4217Code = [self requireNonNullArgumentWithCall:call result:result argumentName:@"currencyIso4217Code" errorCode:@"NULL_CURRENCY_CODE"];
        if (currencyIso4217Code == nil) return;
        
        NSNumber *revenueValue = [self requireNonNullArgumentWithCall:call result:result argumentName:@"revenue" errorCode:@"NULL_REVENUE"];
        if (revenueValue == nil) return;
        
        NSString *mediationNetworkString = [self requireNonNullArgumentWithCall:call result:result argumentName:@"mediationNetwork" errorCode:@"NULL_MEDIATION_NETWORK"];
        if (mediationNetworkString == nil) return;
        
        // Fetching the actual mediationNetwork Enum
        AppsFlyerAdRevenueMediationNetworkType mediationNetwork = [self getEnumValueFromString:mediationNetworkString];
        if (mediationNetwork == -1) { //mediation network not found.
            result([FlutterError errorWithCode:@"INVALID_MEDIATION_NETWORK"
                                       message:@"The provided mediation network is not supported."
                                       details:nil]);
            return;
        }
        
        NSDictionary *additionalParameters = call.arguments[@"additionalParameters"];
        if ([additionalParameters isEqual:[NSNull null]]) {
            additionalParameters = nil;  // Set to nil to avoid sending NSNull to the SDK which cannot be proseesed.
        }
        
        AFAdRevenueData *adRevenueData = [[AFAdRevenueData alloc]
                                          initWithMonetizationNetwork:monetizationNetwork
                                          mediationNetwork:mediationNetwork 
                                          currencyIso4217Code:currencyIso4217Code
                                          eventRevenue:revenueValue];
        
        [[AppsFlyerLib shared] logAdRevenue:adRevenueData additionalParameters:additionalParameters];
        
    } @catch (NSException *exception) {
        result([FlutterError errorWithCode:@"UNEXPECTED_ERROR"
                                   message:[NSString stringWithFormat:@"[logAdRevenue]: An error occurred retrieving method arguments: %@", exception.reason]
                                   details:nil]);
        NSLog(@"AppsFlyer, Exception occurred in [logAdRevenue]: %@", exception.reason);
    }
    
}

- (AppsFlyerAdRevenueMediationNetworkType)getEnumValueFromString:(NSString *)mediationNetworkString {
    NSDictionary<NSString *, NSNumber *> *stringToEnumMap = @{
        @"google_admob": @(AppsFlyerAdRevenueMediationNetworkTypeGoogleAdMob),
        @"ironsource": @(AppsFlyerAdRevenueMediationNetworkTypeIronSource),
        @"applovin_max": @(AppsFlyerAdRevenueMediationNetworkTypeApplovinMax),
        @"fyber": @(AppsFlyerAdRevenueMediationNetworkTypeFyber),
        @"appodeal": @(AppsFlyerAdRevenueMediationNetworkTypeAppodeal),
        @"admost": @(AppsFlyerAdRevenueMediationNetworkTypeAdmost),
        @"topon": @(AppsFlyerAdRevenueMediationNetworkTypeTopon),
        @"tradplus": @(AppsFlyerAdRevenueMediationNetworkTypeTradplus),
        @"yandex": @(AppsFlyerAdRevenueMediationNetworkTypeYandex),
        @"chartboost": @(AppsFlyerAdRevenueMediationNetworkTypeChartBoost),
        @"unity": @(AppsFlyerAdRevenueMediationNetworkTypeUnity),
        @"topon_pte": @(AppsFlyerAdRevenueMediationNetworkTypeToponPte),
        @"custom_mediation": @(AppsFlyerAdRevenueMediationNetworkTypeCustom),
        @"direct_monetization_network": @(AppsFlyerAdRevenueMediationNetworkTypeDirectMonetization)
    };
    
    NSNumber *enumValueNumber = stringToEnumMap[mediationNetworkString];
    if (enumValueNumber) {
        return (AppsFlyerAdRevenueMediationNetworkType)[enumValueNumber integerValue];
    } else {
        return -1;
    }
}

- (id)requireNonNullArgumentWithCall:(FlutterMethodCall*)call result:(FlutterResult)result argumentName:(NSString *)argumentName errorCode:(NSString *)errorCode {
    id value = call.arguments[argumentName];
    if (value == nil) {
        result([FlutterError 
                errorWithCode:errorCode
                message:[NSString stringWithFormat:@"%@ must not be null", argumentName]
                details:nil]);
        NSLog(@"AppsFlyer, %@ must not be null", argumentName);
    }
    return value;
}

- (void)enableTCFDataCollection:(FlutterMethodCall*)call result:(FlutterResult)result {
    BOOL shouldCollect = [call.arguments[@"shouldCollect"] boolValue];
    [[AppsFlyerLib shared] enableTCFDataCollection:shouldCollect];
    result(nil);
}

- (void)addPushNotificationDeepLinkPath:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSArray* deeplinkPath = call.arguments;
    if(deeplinkPath != nil){
        [[AppsFlyerLib shared] addPushNotificationDeepLinkPath:deeplinkPath];
    }
    result(nil);
}

- (void)setResolveDeepLinkURLs:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSArray* urlsArr = call.arguments;
    if(urlsArr != nil){
        [[AppsFlyerLib shared] setResolveDeepLinkURLs:urlsArr];
    }
    result(nil);
}

- (void)setPartnerData:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* partnerId = call.arguments[@"partnerId"];
    NSDictionary* partnersData = call.arguments[@"partnersData"];
    if(partnersData == [NSNull null]){
       partnersData = nil;
    };
    [[AppsFlyerLib shared] setPartnerDataWithPartnerId:partnerId partnerInfo:partnersData];
    result(nil);
}

- (void)setDisableAdvertisingIdentifiers:(FlutterMethodCall*)call result:(FlutterResult)result{
    id isAdvertiserIdEnabled = call.arguments;
    if ([isAdvertiserIdEnabled isKindOfClass:[NSNumber class]]) {
        BOOL _isAdvertiserIdEnabled = [isAdvertiserIdEnabled boolValue];
        [[AppsFlyerLib shared] setDisableAdvertisingIdentifier: _isAdvertiserIdEnabled];
    }
    result(nil);
}

- (void)setSharingFilterForPartners:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSArray* partners = call.arguments;
    [[AppsFlyerLib shared] setSharingFilterForPartners: partners];
    result(nil);
}

- (void)setCurrentDeviceLanguage:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* language = call.arguments;
    [[AppsFlyerLib shared] setCurrentDeviceLanguage: language];
    result(nil);
}

- (void)disableSKAdNetwork:(FlutterMethodCall*)call result:(FlutterResult)result{
    id isSKADEnabled = call.arguments;
    if ([isSKADEnabled isKindOfClass:[NSNumber class]]) {
        _isSKADEnabled = [(NSNumber*)isSKADEnabled boolValue];
        [AppsFlyerLib shared].disableSKAdNetwork = _isSKADEnabled;
    }
    result(nil);
}

- (void)useReceiptValidationSandbox:(FlutterMethodCall*)call result:(FlutterResult)result{
    id isSandboxEnabled = call.arguments;
    if ([isSandboxEnabled isKindOfClass:[NSNumber class]]) {
        _isSandboxEnabled = [(NSNumber*)isSandboxEnabled boolValue];
        [AppsFlyerLib shared].useReceiptValidationSandbox = _isSandboxEnabled;
    }
    result(nil);
}

- (void)enableFacebookDeferredApplinks:(FlutterMethodCall*)call result:(FlutterResult)result{
    id isFacebookDeferredApplinksEnabled = call.arguments[@"isFacebookDeferredApplinksEnabled"];
    if ([isFacebookDeferredApplinksEnabled isKindOfClass:[NSNumber class]]) {
        if([(NSNumber*)isFacebookDeferredApplinksEnabled boolValue]){
            [[AppsFlyerLib shared] enableFacebookDeferredApplinksWithClass:NSClassFromString(@"FBSDKAppLinkUtility")];
        }
    }
    result(nil);
}

- (void)anonymizeUser:(FlutterMethodCall*)call result:(FlutterResult)result {
    id shouldAnonymize = call.arguments[@"shouldAnonymize"];
    if ([shouldAnonymize isKindOfClass:[NSNumber class]]) {
        [AppsFlyerLib shared].anonymizeUser = [(NSNumber*)shouldAnonymize boolValue];
    }
    result(nil);
}

- (void)setPushNotification:(FlutterMethodCall*)call result:(FlutterResult)result{
    id isPushNotificationEnabled = call.arguments;
    if ([isPushNotificationEnabled isKindOfClass:[NSNumber class]]) {
        _isPushNotificationEnabled = [(NSNumber*)isPushNotificationEnabled boolValue];
    }
    result(nil);
}

- (void)sendPushNotificationData:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSDictionary* userInfo = call.arguments;
    [[AppsFlyerLib shared] handlePushNotification:userInfo];
    result(nil);
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
    NSDictionary* customParams = call.arguments[@"customParams"];

    //Explicitly setting the values of the parameters to be nil in case they are initially received as <null>. 
    if (customerID == [NSNull null]) {
        customerID = nil;
    }
    if (referrerImageUrl == [NSNull null]) {
        referrerImageUrl = nil;
    }
    if (brandDomain == [NSNull null]) {
        brandDomain = nil;
    }
    if (baseDeeplink == [NSNull null]) {
        baseDeeplink = nil;
    }
    if (referrerName == [NSNull null]) {
        referrerName = nil;
    }
    if (channel == [NSNull null]) {
        channel = nil;
    }
    if (campaign == [NSNull null]) {
        campaign = nil;
    }
    if(customParams == [NSNull null]){
       customParams = nil;
    };
    
    [AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:^AppsFlyerLinkGenerator * _Nonnull(AppsFlyerLinkGenerator * _Nonnull generator) {
        [generator setChannel:channel];
        [generator setCampaign:campaign];
        [generator setBrandDomain:brandDomain];
        [generator setBaseDeeplink:baseDeeplink];
        [generator setReferrerName:referrerName];
        [generator setReferrerImageURL:referrerImageUrl];
        [generator setReferrerCustomerId:customerID];
        [generator addParameters:customParams];
        
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
        @"error": @"error"
    };
    if(error != nil){
        errorObject = @{
            @"error": error.description
        };
    }
    
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

- (void)setCurrencyCode:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* currencyCode = call.arguments[@"currencyCode"];
    [[AppsFlyerLib shared] setCurrencyCode:currencyCode];
    result(nil);
}

- (void)stop:(FlutterMethodCall*)call result:(FlutterResult)result{
    BOOL stop = [[call.arguments objectForKey:@"isStopped"] boolValue];
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

- (void)setUserEmails:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSMutableArray *emails = call.arguments[@"emails"];
    NSArray *emaillsArray = [emails copy];
    NSNumber* cryptTypeInt = (id)call.arguments[@"cryptType"];
    
    EmailCryptType cryptType = EmailCryptTypeNone;
    if(1 == [cryptTypeInt doubleValue]){
        cryptType = EmailCryptTypeSHA256;
    }
    
    [[AppsFlyerLib shared] setUserEmails:emaillsArray withCryptType:cryptType];
    result(nil);
}

- (void)initSdkWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString* devKey = nil;
    NSString* appId = nil;
    NSString* appInviteOneLink = nil;
    BOOL manualStart = NO;
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
    id isManualStart = nil;
    
    devKey = call.arguments[afDevKey];
    appId = call.arguments[afAppId];
    timeToWaitForATTUserAuthorization = [(id)call.arguments[afTimeToWaitForATTUserAuthorization] doubleValue];
    
    isManualStart = call.arguments[afManualStart];
    if([isManualStart isKindOfClass:[NSNumber class]]){
        manualStart = [(NSNumber*)isManualStart boolValue];
        [self setIsManualStart:manualStart];
    }
    

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
    if (appInviteOneLink != nil && appInviteOneLink != [NSNull null]) {
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
    
    SEL DisableAdvertisingSel = NSSelectorFromString(@"setDisableAdvertisingIdentifier:");
    id AppsFlyer = [AppsFlyerLib shared];
    if ([AppsFlyer respondsToSelector:DisableAdvertisingSel] && disableAdvertisingIdentifier) {
        bypassDisableAdvertisingIdentifier msgSend = (bypassDisableAdvertisingIdentifier)objc_msgSend;
        msgSend(AppsFlyer, DisableAdvertisingSel, disableAdvertisingIdentifier);
    }
    
    [[AppsFlyerLib shared] setPluginInfoWith:AFSDKPluginFlutter pluginVersion:kAppsFlyerPluginVersion additionalParams:nil];
    
    [AppsFlyerLib shared].appleAppID = appId;
    [AppsFlyerLib shared].appsFlyerDevKey = devKey;
    [AppsFlyerLib shared].isDebug = isDebug;
    
    
    // SEL WaitForATTSel = NSSelectorFromString(@"waitForATTUserAuthorizationWithTimeoutInterval:");
    
    // if ([AppsFlyer respondsToSelector:WaitForATTSel] && timeToWaitForATTUserAuthorization != 0) {
    //     bypassWaitForATTUserAuthorization msgSend = (bypassWaitForATTUserAuthorization)objc_msgSend;
    //     msgSend(AppsFlyer, WaitForATTSel, timeToWaitForATTUserAuthorization);
    // }
    
    if (timeToWaitForATTUserAuthorization != 0) {
        [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:timeToWaitForATTUserAuthorization];
    }
    
    if (manualStart == NO){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[AppsFlyerLib shared] start];
    }
    
    //post notification for the deep link object that the bridge is set and he can handle deep link
    [AppsFlyerAttribution shared].isBridgeReady = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
    
    
    result(@{@"status": @"OK"});
}

-(void)logEventWithCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString *eventName =  call.arguments[afEventName];
    NSDictionary *eventValues = call.arguments[afEventValues];
    
    // Explicitily setting the values to be nil if call.arguments[afEventValues] returns <null>.
    if (eventValues == [NSNull null]) {
        eventValues = nil;
    }
    
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

# pragma mark - handle deep links
// Deep linking
// Open URI-scheme for iOS 9 and above
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *) options {
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    
    // Results of this are ORed and NO doesn't affect other delegate interceptors' result.
    return NO;
    
}
// Open URI-scheme for iOS 8 and below
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    
    // Results of this are ORed and NO doesn't affect other delegate interceptors' result.
    return NO;
    
}
// Open Universal Links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    
    // Results of this are ORed and NO doesn't affect other delegate interceptors' result.
    return NO;
}


@end
