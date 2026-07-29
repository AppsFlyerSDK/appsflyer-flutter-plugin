#import "AppsflyerSdkPlugin.h"

#ifdef ENABLE_PURCHASE_CONNECTOR
#import "appsflyer_sdk/appsflyer_sdk-Swift.h"
#endif

// AppsFlyerRPC bridge (Swift, @objcMembers). Under use_frameworks!/modular headers the generated
// ObjC interface is exposed as <AppsFlyerRPC/AppsFlyerRPC-Swift.h>; fall back to a module import.
#if __has_include(<AppsFlyerRPC/AppsFlyerRPC-Swift.h>)
#import <AppsFlyerRPC/AppsFlyerRPC-Swift.h>
#else
@import AppsFlyerRPC;
#endif

// Canonical Flutter event ids/statuses. These MUST match callbacks.dart routing and the shapes the
// Android bridge already emits, so the Dart layer has a single, platform-agnostic decode path.
static NSString *const kEventInstallConversionData = @"onInstallConversionData";
static NSString *const kEventDeepLinking           = @"onDeepLinking";
static NSString *const kEventGenerateInviteSuccess = @"generateInviteLinkSuccess";
static NSString *const kEventGenerateInviteFailure = @"generateInviteLinkFailure";
static NSString *const kEventSetAppInviteOneLink   = @"setAppInviteOneLinkIDCallback";
static NSString *const kEventSessionReady          = @"onSessionReady";
static NSString *const kStatusSuccess              = @"success";
static NSString *const kStatusFailure              = @"failure";

// RPC method names that need plugin-side orchestration (everything else is forwarded generically).
static NSString *const kRpcInit                = @"init";
static NSString *const kRpcGenerateInviteLink  = @"generateInviteLink";
static NSString *const kRpcSetAppInviteOneLink = @"setAppInviteOneLink";
static NSString *const kRpcLogAndOpenStore     = @"logAndOpenStore";

@interface AppsflyerSdkPlugin ()
@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, copy) FlutterEventSink eventSink;
@property (nonatomic, strong) NSMutableArray<NSString *> *pendingEvents;
@property (nonatomic, assign) BOOL eventHandlerRegistered;
@end

@implementation AppsflyerSdkPlugin

// ============================================================================
// Plugin / channel lifecycle
// ============================================================================

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        _pendingEvents = [NSMutableArray array];
        _methodChannel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
        _eventChannel = [FlutterEventChannel eventChannelWithName:afEventChannel binaryMessenger:messenger];
        [_eventChannel setStreamHandler:self];
        // Wire the bridge event handler as early as possible: the RPC layer drops events emitted
        // before a handler is attached, so it must be set before start() and listener registration.
        [self registerEventHandler];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
#ifdef ENABLE_PURCHASE_CONNECTOR
    [PurchaseConnectorPlugin registerWithRegistrar:registrar];
#endif
    id<FlutterBinaryMessenger> messenger = [registrar messenger];
    AppsflyerSdkPlugin *instance = [[AppsflyerSdkPlugin alloc] initWithMessenger:messenger];
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
    if (@available(iOS 13.0, *)) {
        [registrar addSceneDelegate:instance];
    }
#endif
}

- (void)registerEventHandler {
    if (self.eventHandlerRegistered) {
        return;
    }
    self.eventHandlerRegistered = YES;
    __weak typeof(self) weakSelf = self;
    [[AppsFlyerRPCBridge shared] setEventHandler:^(NSString *jsonEvent) {
        [weakSelf handleBridgeEvent:jsonEvent];
    }];
}

#pragma mark - FlutterStreamHandler (af-events)

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    [self flushPendingEvents];
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

// ============================================================================
// Method channel entry point
// ============================================================================

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"executeRpc" isEqualToString:call.method]) {
        [self executeRpc:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

/// Single RPC entry point. Unwraps {method, params} and routes it: init/start, the invite-link
/// methods and logAndOpenStore run plugin-side orchestration; everything else is forwarded to the
/// AppsFlyerRPC bridge as-is.
- (void)executeRpc:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
        result([FlutterError errorWithCode:@"INVALID_PARAMETERS" message:@"executeRpc requires a {method, params} map" details:nil]);
        return;
    }
    NSDictionary *args = call.arguments;
    NSString *method = args[@"method"];
    if (![method isKindOfClass:[NSString class]] || method.length == 0) {
        result([FlutterError errorWithCode:@"INVALID_PARAMETERS" message:@"executeRpc requires a 'method'" details:nil]);
        return;
    }
    NSDictionary *params = [args[@"params"] isKindOfClass:[NSDictionary class]] ? args[@"params"] : @{};

    @try {
        if ([kRpcInit isEqualToString:method]) {
            [self initFromRpc:params result:result];
        } else if ([kRpcGenerateInviteLink isEqualToString:method]) {
            [self generateInviteLinkFromRpc:params result:result];
        } else if ([kRpcSetAppInviteOneLink isEqualToString:method]) {
            [self setAppInviteOneLinkFromRpc:params result:result];
        } else if ([kRpcLogAndOpenStore isEqualToString:method]) {
            [self logAndOpenStoreFromRpc:params result:result];
        } else {
            [self dispatchRpc:method params:params result:result];
        }
    } @catch (NSException *exception) {
        result([FlutterError errorWithCode:@"UNEXPECTED_ERROR" message:exception.reason ?: @"RPC dispatch failed" details:nil]);
    }
}

// ============================================================================
// init (SDK 7 session model). start() is forwarded generically via dispatchRpc,
// like logEvent: its result returns on the per-call reply (params.awaitResponse).
// ============================================================================

- (void)initFromRpc:(NSDictionary *)params result:(FlutterResult)result {
    [self registerEventHandler];

    NSString *devKey = [self stringParam:params key:afDevKey];
    NSString *appId = [self stringParam:params key:afAppId];
    BOOL isDebug = [self boolParam:params key:afIsDebug];
    BOOL isGCD = [self boolParam:params key:afConversionData];
    BOOL isUDL = [self boolParam:params key:afUDL];
    BOOL disableCollectASA = [self boolParam:params key:afDisableCollectASA];
    BOOL disableAdvertisingIdentifier = [self boolParam:params key:afDisableAdvertisingIdentifier];
    NSString *inviteOneLink = [self stringParam:params key:afInviteOneLink];
    NSTimeInterval attTimeout = [params[afTimeToWaitForATTUserAuthorization] isKindOfClass:[NSNumber class]]
        ? [params[afTimeToWaitForATTUserAuthorization] doubleValue]
        : 0;

    // Ordered RPC sequence: setPluginInfo -> initialize -> config -> listeners. Order matters (SDK 7),
    // so the calls are chained through their completion handlers rather than fired concurrently.
    NSMutableArray<NSDictionary *> *sequence = [NSMutableArray array];
    [sequence addObject:@{@"method": @"setPluginInfo", @"params": @{@"plugin": @"flutter", @"pluginVersion": kAppsFlyerPluginVersion}}];
    [sequence addObject:@{@"method": @"initialize", @"params": @{@"devKey": devKey ?: @"", @"appId": appId ?: @""}}];
    [sequence addObject:@{@"method": @"isDebug", @"params": @{@"isDebug": @(isDebug)}}];
    if (disableCollectASA) {
        [sequence addObject:@{@"method": @"setDisableCollectASA", @"params": @{@"disable": @(YES)}}];
    }
    if (disableAdvertisingIdentifier) {
        [sequence addObject:@{@"method": @"setDisableAdvertisingIdentifiers", @"params": @{@"disable": @(YES)}}];
    }
    if (inviteOneLink.length > 0) {
        [sequence addObject:@{@"method": @"setAppInviteOneLink", @"params": @{@"oneLinkId": inviteOneLink}}];
    }
    if (isGCD) {
        [sequence addObject:@{@"method": @"registerConversionListener", @"params": @{}}];
    }
    if (isUDL) {
        [sequence addObject:@{@"method": @"registerDeeplinkListener", @"params": @{}}];
    }
    // SDK 7 session model: register the session-ready listener so the app can OBSERVE readiness via
    // registerSessionReadyListener()/onSessionReady (and isSessionReady()). It does NOT gate start():
    // the app issues startSDK() itself (from that callback), matching Android and the Cordova bridge. The
    // native SDK fires this listener independently of start(), once config is valid and any launch deep
    // link has resolved (see AFSDKSessionReadyService), so registering here never blocks the first session.
    [sequence addObject:@{@"method": @"registerSessionReadyListener", @"params": @{}}];

    __weak typeof(self) weakSelf = self;
    [self runSequence:sequence index:0 completion:^{
        // ATT wait is not exposed by the RPC layer, so it is set directly on the SDK singleton
        // (the same instance AppsFlyerRPC wraps) before the first session is sent.
        if (attTimeout > 0) {
            [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:attTimeout];
        }
        // The deep-link/attribution bridge is now ready; replay any launch URLs captured before init.
        [AppsFlyerAttribution shared].isBridgeReady = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:nil];
        (void)weakSelf;
        result(nil);
    }];
}

/// Fires the RPC sequence one entry at a time, each in the previous call's completion handler.
- (void)runSequence:(NSArray<NSDictionary *> *)sequence index:(NSUInteger)index completion:(void (^)(void))completion {
    if (index >= sequence.count) {
        completion();
        return;
    }
    NSDictionary *entry = sequence[index];
    NSString *json = [self jsonEnvelopeForMethod:entry[@"method"] params:entry[@"params"]];
    if (json == nil) {
        [self runSequence:sequence index:index + 1 completion:completion];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[AppsFlyerRPCBridge shared] executeJson:json completion:^(NSString *response) {
        [weakSelf runSequence:sequence index:index + 1 completion:completion];
    }];
}

// ============================================================================
// Invite links + cross-promotion (results delivered on the af-events stream)
// ============================================================================

- (void)generateInviteLinkFromRpc:(NSDictionary *)params result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;
    [self executeJsonForMethod:kRpcGenerateInviteLink params:params completion:^(NSDictionary *resultObj, FlutterError *error) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (error) {
            [strongSelf deliverEventWithId:kEventGenerateInviteFailure status:kStatusFailure dataJsonString:(error.message ?: @"The URL wasn't generated!")];
            return;
        }
        NSDictionary *data = [resultObj[@"data"] isKindOfClass:[NSDictionary class]] ? resultObj[@"data"] : nil;
        NSString *url = data[@"url"];
        if (url.length > 0) {
            [strongSelf deliverEventWithId:kEventGenerateInviteSuccess status:kStatusSuccess dataJsonString:[strongSelf jsonStringFromObject:@{@"userInviteURL": url}]];
        } else {
            [strongSelf deliverEventWithId:kEventGenerateInviteFailure status:kStatusFailure dataJsonString:@"The URL wasn't generated!"];
        }
    }];
    result(nil);
}

- (void)setAppInviteOneLinkFromRpc:(NSDictionary *)params result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;
    [self executeJsonForMethod:kRpcSetAppInviteOneLink params:params completion:^(NSDictionary *resultObj, FlutterError *error) {
        if (error == nil) {
            [weakSelf deliverEventWithId:kEventSetAppInviteOneLink status:kStatusSuccess dataJsonString:kStatusSuccess];
        }
    }];
    result(nil);
}

- (void)logAndOpenStoreFromRpc:(NSDictionary *)params result:(FlutterResult)result {
    [self executeJsonForMethod:kRpcLogAndOpenStore params:params completion:^(NSDictionary *resultObj, FlutterError *error) {
        if (error) {
            return;
        }
        NSDictionary *data = [resultObj[@"data"] isKindOfClass:[NSDictionary class]] ? resultObj[@"data"] : nil;
        NSString *clickURL = data[@"clickURL"];
        if (clickURL.length > 0) {
            NSURL *url = [NSURL URLWithString:clickURL];
            if (url) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                });
            }
        }
    }];
    result(nil);
}

// ============================================================================
// Generic RPC dispatch + response unwrapping
// ============================================================================

- (void)dispatchRpc:(NSString *)method params:(NSDictionary *)params result:(FlutterResult)result {
    [self executeJsonForMethod:method params:params completion:^(NSDictionary *resultObj, FlutterError *error) {
        if (error) {
            result(error);
            return;
        }
        result([self unwrapValueForMethod:method resultObj:resultObj]);
    }];
}

/// Serializes the {id?, method, params} envelope, calls the bridge, and normalizes the JSON string
/// response into either (resultObj, nil) on success or (nil, FlutterError) on a protocol- or
/// SDK-level failure — matching the (value / error) contract the Android dispatcher exposes.
- (void)executeJsonForMethod:(NSString *)method params:(NSDictionary *)params completion:(void (^)(NSDictionary *resultObj, FlutterError *error))completion {
    NSString *json = [self jsonEnvelopeForMethod:method params:params];
    if (json == nil) {
        completion(nil, [FlutterError errorWithCode:@"SERIALIZATION_ERROR" message:[NSString stringWithFormat:@"Failed to serialize RPC request for %@", method] details:nil]);
        return;
    }
    [[AppsFlyerRPCBridge shared] executeJson:json completion:^(NSString *response) {
        NSError *parseErr = nil;
        NSDictionary *parsed = [self dictionaryFromJson:response error:&parseErr];
        if (parsed == nil) {
            completion(nil, [FlutterError errorWithCode:@"RPC_PARSE_ERROR" message:(parseErr.localizedDescription ?: @"Failed to parse RPC response") details:response]);
            return;
        }
        // Protocol-level error (bad JSON, unknown method, missing params).
        id envelopeError = parsed[@"error"];
        if ([envelopeError isKindOfClass:[NSDictionary class]]) {
            NSDictionary *e = envelopeError;
            NSString *code = e[@"code"] ? [NSString stringWithFormat:@"%@", e[@"code"]] : @"RPC_ERROR";
            completion(nil, [FlutterError errorWithCode:code message:e[@"message"] details:nil]);
            return;
        }
        id resultObj = parsed[@"result"];
        if (![resultObj isKindOfClass:[NSDictionary class]]) {
            completion(@{}, nil);
            return;
        }
        NSDictionary *r = resultObj;
        // Application-level failure is wrapped in the success envelope with success == false.
        id successVal = r[@"success"];
        BOOL success = [successVal isKindOfClass:[NSNumber class]] ? [successVal boolValue] : YES;
        if (!success) {
            NSString *msg = r[@"error"] ?: r[@"message"] ?: @"RPC operation failed";
            completion(nil, [FlutterError errorWithCode:@"SDK_ERROR" message:msg details:r[@"errorType"]]);
            return;
        }
        completion(r, nil);
    }];
}

/// Extracts the primitive/map value Dart expects from the RPC `result` object. The iOS RPC returns
/// data under nested keys (e.g. {data:{version}}); Android returns the bare value, so we unwrap here
/// to keep the Dart return shape identical across platforms. Setters/void calls return nil.
- (id)unwrapValueForMethod:(NSString *)method resultObj:(NSDictionary *)resultObj {
    NSDictionary *data = [resultObj[@"data"] isKindOfClass:[NSDictionary class]] ? resultObj[@"data"] : nil;
    if ([method isEqualToString:@"getSdkVersion"]) {
        return data[@"version"];
    }
    if ([method isEqualToString:@"getAppsFlyerUID"]) {
        return data[@"uid"];
    }
    if ([method isEqualToString:@"isSessionReady"]) {
        // AFRPCCoreHandler returns the flag under `isSessionReady` (the README's `ready` is stale).
        // Read the canonical key and fall back to `ready` for forward-compatibility.
        return data[@"isSessionReady"] ?: data[@"ready"];
    }
    if ([method isEqualToString:@"validateAndLogInAppPurchase"]) {
        return data ?: @{};
    }
    return nil;
}

// ============================================================================
// Event forwarding (bridge -> af-events stream)
// ============================================================================

/// Translates a raw AppsFlyerRPC event JSON string into the canonical Flutter event shape and
/// forwards it to the af-events stream. This is shape adaptation only; no SDK logic lives here.
- (void)handleBridgeEvent:(NSString *)jsonEvent {
    NSDictionary *event = [self dictionaryFromJson:jsonEvent error:nil];
    if (event == nil) {
        return;
    }
    NSString *name = event[@"event"];
    NSDictionary *data = [event[@"data"] isKindOfClass:[NSDictionary class]] ? event[@"data"] : @{};

    if ([name isEqualToString:@"onConversionDataSuccess"]) {
        [self deliverEventWithId:kEventInstallConversionData status:kStatusSuccess dataJsonString:[self jsonStringFromObject:data]];
    } else if ([name isEqualToString:@"onConversionDataFail"]) {
        [self deliverEventWithId:kEventInstallConversionData status:kStatusFailure dataJsonString:[self jsonStringFromObject:data]];
    } else if ([name isEqualToString:@"onDeepLinkReceived"]) {
        [self deliverDeepLinkEvent:data];
    } else if ([name isEqualToString:kEventSessionReady]) {
        // SDK 7 session-ready signal. Observational only (start() is issued directly). Delivered with
        // an empty JSON-object payload so the Dart onSessionReady route matches the Android shape.
        [self deliverEventWithId:kEventSessionReady status:kStatusSuccess dataJsonString:@"{}"];
    }
}

- (void)deliverDeepLinkEvent:(NSDictionary *)data {
    // iOS RPC status (found/failure/notFound) -> the FOUND/NOT_FOUND/ERROR strings callbacks.dart parses.
    NSString *iosStatus = data[@"status"];
    NSString *deepLinkStatus = @"ERROR";
    if ([iosStatus isEqualToString:@"found"]) {
        deepLinkStatus = @"FOUND";
    } else if ([iosStatus isEqualToString:@"notFound"]) {
        deepLinkStatus = @"NOT_FOUND";
    }

    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    args[@"id"] = kEventDeepLinking;
    args[@"deepLinkStatus"] = deepLinkStatus;
    if ([data[@"deepLink"] isKindOfClass:[NSDictionary class]]) {
        args[@"deepLinkObj"] = data[@"deepLink"];
    }
    if ([data[@"error"] isKindOfClass:[NSString class]]) {
        args[@"deepLinkError"] = data[@"error"];
    }
    NSString *json = [self jsonStringFromObject:args];
    if (json) {
        [self deliverEvent:json];
    }
}

/// Builds the {id, status, data} envelope callbacks.dart expects. `dataJsonString` is forwarded as
/// the "data" field verbatim (a JSON-object string for structured payloads, or a plain string for
/// simple callbacks), matching the Android bridge output exactly.
- (void)deliverEventWithId:(NSString *)eventId status:(NSString *)status dataJsonString:(NSString *)dataJsonString {
    NSDictionary *envelope = @{@"id": eventId, @"status": status ?: kStatusSuccess, @"data": dataJsonString ?: @"{}"};
    NSString *json = [self jsonStringFromObject:envelope];
    if (json) {
        [self deliverEvent:json];
    }
}

// Delivers an event to the af-events stream, or buffers it until Dart subscribes (onListen). The
// bridge completion/event handler is invoked on the main thread, so no extra hop is required.
- (void)deliverEvent:(NSString *)argsJson {
    if (self.eventSink) {
        self.eventSink(argsJson);
    } else {
        [self.pendingEvents addObject:argsJson];
    }
}

- (void)flushPendingEvents {
    if (self.pendingEvents.count == 0 || self.eventSink == nil) {
        return;
    }
    NSArray<NSString *> *pending = [self.pendingEvents copy];
    [self.pendingEvents removeAllObjects];
    for (NSString *args in pending) {
        self.eventSink(args);
    }
}

// ============================================================================
// JSON helpers
// ============================================================================

- (NSString *)jsonEnvelopeForMethod:(NSString *)method params:(NSDictionary *)params {
    return [self jsonStringFromObject:@{@"method": method, @"params": (params ?: @{})}];
}

- (NSString *)jsonStringFromObject:(id)object {
    if (object == nil || ![NSJSONSerialization isValidJSONObject:object]) {
        return nil;
    }
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&err];
    if (data == nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSDictionary *)dictionaryFromJson:(NSString *)json error:(NSError **)error {
    if (![json isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) {
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    return [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
}

- (NSString *)stringParam:(NSDictionary *)params key:(NSString *)key {
    id value = params[key];
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

- (BOOL)boolParam:(NSDictionary *)params key:(NSString *)key {
    id value = params[key];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

// ============================================================================
// Deep links (AppDelegate + UIScene). These drive AppsFlyerLib.shared() directly — the same
// singleton AppsFlyerRPC wraps — so the resolved link surfaces through the RPC deep-link delegate.
// ============================================================================

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return NO;
}

#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
#pragma mark - FlutterSceneLifeCycleDelegate

// UIScene-based URI-scheme deep links (iOS 13+, Flutter 3.41+ UIScene migration)
- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    for (UIOpenURLContext *context in URLContexts) {
        NSDictionary *opts = @{};
        if (context.options.sourceApplication) {
            opts = @{UIApplicationOpenURLOptionsSourceApplicationKey: context.options.sourceApplication};
        }
        [[AppsFlyerAttribution shared] handleOpenUrl:context.URL options:opts];
    }
    return NO;
}

// Cold-start deep links delivered via UISceneConnectionOptions (iOS 13+)
- (BOOL)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    for (UIOpenURLContext *context in connectionOptions.URLContexts) {
        NSDictionary *opts = @{};
        if (context.options.sourceApplication) {
            opts = @{UIApplicationOpenURLOptionsSourceApplicationKey: context.options.sourceApplication};
        }
        [[AppsFlyerAttribution shared] handleOpenUrl:context.URL options:opts];
    }
    for (NSUserActivity *activity in connectionOptions.userActivities) {
        if ([activity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            [[AppsFlyerAttribution shared] continueUserActivity:activity restorationHandler:nil];
        }
    }
    return NO;
}

// UIScene-based Universal Links (iOS 13+)
- (BOOL)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(13.0)) {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:nil];
    return NO;
}
#endif // __has_include(<Flutter/FlutterSceneLifeCycle.h>)

@end
