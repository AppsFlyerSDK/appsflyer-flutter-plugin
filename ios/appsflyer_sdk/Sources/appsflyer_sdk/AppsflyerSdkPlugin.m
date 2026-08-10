#import "AppsflyerSdkPlugin.h"
#import "AppsFlyerAttribution.h"

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

// RPC method names that need plugin-side orchestration (everything else is forwarded generically).
static NSString *const kRpcInit            = @"init";
static NSString *const kRpcLogAndOpenStore = @"logAndOpenStore";
static NSString *const kRpcSetPluginInfo   = @"setPluginInfo";

@interface AppsflyerSdkPlugin ()
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, copy) FlutterEventSink eventSink;
@property (nonatomic, strong) NSMutableArray<NSString *> *pendingEvents;
@property (nonatomic, assign) BOOL eventHandlerRegistered;
@property (nonatomic, strong) NSDictionary *pendingLaunchOptions;
- (void)tearDownForEngineDetach;
@end

@implementation AppsflyerSdkPlugin

// ============================================================================
// Plugin / channel lifecycle
// ============================================================================

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    if (self) {
        _pendingEvents = [NSMutableArray array];
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
    // publish: is required so FlutterEngine dealloc invokes detachFromEngineForRegistrar:.
    [registrar publish:instance];
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:afMethodChannel binaryMessenger:messenger];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
#if __has_include(<Flutter/FlutterSceneLifeCycle.h>)
    if (@available(iOS 13.0, *)) {
        [registrar addSceneDelegate:instance];
    }
#endif
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    (void)registrar;
    [self tearDownForEngineDetach];
}

- (void)tearDownForEngineDetach {
    self.eventSink = nil;
    [self.pendingEvents removeAllObjects];
    self.eventHandlerRegistered = NO;
    [[AppsFlyerRPCBridge shared] removeEventHandler];
    [self.eventChannel setStreamHandler:nil];
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

/// Single RPC entry point. Initialization and the cross-promotion URL side effect require
/// plugin orchestration; every other method is forwarded to AppsFlyerRPC as-is.
- (void)executeRpc:(FlutterMethodCall *)call result:(FlutterResult)result {
    // Parsing happens inside @try too: unlike Android, Flutter's iOS MethodChannel does not
    // catch NSException around handleMethodCall: itself, so a malformed call.arguments would
    // otherwise crash the app instead of being reported as a Flutter error.
    @try {
        NSDictionary *args = call.arguments;
        NSString *method = args[@"method"];
        NSDictionary *params = [args[@"params"] isKindOfClass:[NSDictionary class]] ? args[@"params"] : @{};

        if ([kRpcInit isEqualToString:method]) {
            [self initFromRpc:params result:result];
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

    NSString *devKey = [self stringParam:params key:@"devKey"];
    NSString *appId = [self stringParam:params key:@"appId"];

    // Ordered RPC sequence: initialize -> pending launch options. Listener registration
    // is explicit in Dart, so initialization has no hidden callback side effects.
    NSMutableArray<NSDictionary *> *sequence = [NSMutableArray array];
    [sequence addObject:@{@"method": @"initialize", @"params": @{@"devKey": devKey ?: @"", @"appId": appId ?: @""}}];
    if (self.pendingLaunchOptions) {
        [sequence addObject:@{
            @"method": @"handleLaunchOptions",
            @"params": @{@"launchOptions": self.pendingLaunchOptions}
        }];
    }

    // setPluginInfo runs ahead of the sequence rather than inside it: the plugin name must
    // reach the first session payload, but it only labels reporting, so its outcome must not
    // abort initialization.
    //
    // self is captured strongly here and in runSequence: executeJsonForMethod: already retains
    // self for the round trip, and messaging a nil weak self would silently skip the rest of
    // the chain, leaving the Flutter result — and the Dart Future awaiting it — unresolved.
    // No cycle is possible: the block is handed to the RPC bridge and never stored on self.
    [self executeJsonForMethod:kRpcSetPluginInfo
                        params:@{@"plugin": @"flutter", @"pluginVersion": kAppsFlyerPluginVersion}
                    completion:^(NSDictionary *resultObj, FlutterError *error) {
        [self runSequence:sequence index:0 completion:^(FlutterError *sequenceError) {
            if (sequenceError) {
                result(sequenceError);
                return;
            }
            self.pendingLaunchOptions = nil;
            [[AppsFlyerAttribution shared] markBridgeReady];
            result(nil);
        }];
    }];
}

/// Fires the RPC sequence one entry at a time, each in the previous call's completion handler.
- (void)runSequence:(NSArray<NSDictionary *> *)sequence
              index:(NSUInteger)index
         completion:(void (^)(FlutterError *error))completion {
    if (index >= sequence.count) {
        completion(nil);
        return;
    }
    NSDictionary *entry = sequence[index];
    [self executeJsonForMethod:entry[@"method"] params:entry[@"params"] completion:^(NSDictionary *resultObj, FlutterError *error) {
        if (error) {
            completion(error);
            return;
        }
        [self runSequence:sequence index:index + 1 completion:completion];
    }];
}

- (void)logAndOpenStoreFromRpc:(NSDictionary *)params result:(FlutterResult)result {
    [self executeJsonForMethod:kRpcLogAndOpenStore params:params completion:^(NSDictionary *resultObj, FlutterError *error) {
        if (error) {
            result(error);
            return;
        }
        NSDictionary *data = [resultObj[@"data"] isKindOfClass:[NSDictionary class]] ? resultObj[@"data"] : nil;
        NSString *clickURL = data[@"clickURL"];
        NSURL *url = clickURL.length > 0 ? [NSURL URLWithString:clickURL] : nil;
        if (url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:url
                                                     options:@{}
                                           completionHandler:^(__unused BOOL success) {
                    result(nil);
                }];
            });
            return;
        }
        result(nil);
    }];
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
            completion(nil, [FlutterError errorWithCode:code message:e[@"message"] details:e]);
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
            NSString *code = r[@"errorCode"] ? [NSString stringWithFormat:@"%@", r[@"errorCode"]] : @"SDK_ERROR";
            completion(nil, [FlutterError errorWithCode:code message:msg details:r]);
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
        // Read the current key and retain the bridge's alternate `ready` key.
        return data[@"isSessionReady"] ?: data[@"ready"];
    }
    if ([method isEqualToString:@"validateAndLogInAppPurchase"]) {
        return data ?: @{};
    }
    if ([method isEqualToString:@"generateInviteLink"]) {
        return data[@"url"];
    }
    return nil;
}

// ============================================================================
// Event forwarding (bridge -> af-events stream)
// ============================================================================

/// Forwards the native AppsFlyerRPC envelope without changing event names or payloads.
- (void)handleBridgeEvent:(NSString *)jsonEvent {
    if ([jsonEvent isKindOfClass:[NSString class]]) {
        if ([NSThread isMainThread]) {
            [self deliverEvent:jsonEvent];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self deliverEvent:jsonEvent];
            });
        }
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

// ============================================================================
// Lifecycle forwarding (AppDelegate + UIScene). AppsFlyerAttribution queues early links and sends
// them through AppsFlyerRPC after initialize completes.
// ============================================================================

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions.count > 0) {
        NSMutableDictionary *jsonSafeOptions = [NSMutableDictionary dictionary];
        [launchOptions enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            NSString *stringKey = [key description];
            if ([value isKindOfClass:[NSURL class]]) {
                jsonSafeOptions[stringKey] = [value absoluteString];
            } else if ([NSJSONSerialization isValidJSONObject:@[value]]) {
                jsonSafeOptions[stringKey] = value;
            }
        }];
        self.pendingLaunchOptions = jsonSafeOptions;
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    return NO;
}

// UIApplicationDelegate requires restorationHandler; attribution only forwards webpageURL to RPC
// (AppsFlyer SDK ignores the handler too). Handoff/UI restoration stays with the host app.
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
    (void)restorationHandler;
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity];
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
            [[AppsFlyerAttribution shared] continueUserActivity:activity];
        }
    }
    return NO;
}

// UIScene-based Universal Links (iOS 13+)
- (BOOL)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity API_AVAILABLE(ios(13.0)) {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity];
    return NO;
}
#endif // __has_include(<Flutter/FlutterSceneLifeCycle.h>)

@end
