#import <XCTest/XCTest.h>
#import <Flutter/Flutter.h>
#import <appsflyer_sdk/AppsflyerSdkPlugin.h>

@interface AppsflyerSdkPlugin (Testing)
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result;
+ (void)invokeCallbackWithId:(NSString *)callbackId arguments:(id)arguments;
@end

@interface RecordingBinaryMessenger : NSObject <FlutterBinaryMessenger>
@property(nonatomic, strong) NSMutableArray<NSString *> *sentChannels;
@property(nonatomic, strong) NSMutableArray<FlutterMethodCall *> *sentMethodCalls;
@end

@implementation RecordingBinaryMessenger

- (instancetype)init {
    self = [super init];
    if (self) {
        _sentChannels = [NSMutableArray array];
        _sentMethodCalls = [NSMutableArray array];
    }
    return self;
}

- (void)sendOnChannel:(NSString *)channel message:(NSData *)message {
    [self recordChannel:channel message:message];
}

- (void)sendOnChannel:(NSString *)channel
              message:(NSData *)message
          binaryReply:(FlutterBinaryReply)callback {
    [self recordChannel:channel message:message];
    if (callback) {
        callback(nil);
    }
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString *)channel
                                          binaryMessageHandler:(FlutterBinaryMessageHandler)handler {
    return 0;
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString *)channel
                                          binaryMessageHandler:(FlutterBinaryMessageHandler)handler
                                                     taskQueue:(NSObject<FlutterTaskQueue> *)taskQueue {
    return 0;
}

- (void)cleanUpConnection:(FlutterBinaryMessengerConnection)connection {
}

- (void)recordChannel:(NSString *)channel message:(NSData *)message {
    [self.sentChannels addObject:channel];
    if (message == nil) {
        return;
    }

    FlutterMethodCall *methodCall = [[FlutterStandardMethodCodec sharedInstance] decodeMethodCall:message];
    if (methodCall != nil) {
        [self.sentMethodCalls addObject:methodCall];
    }
}

@end

@interface AppsflyerSdkPluginMultiEngineTests : XCTestCase
@property(nonatomic, strong) NSMutableArray<AppsflyerSdkPlugin *> *pluginsToCancel;
@property(nonatomic, strong) NSMutableSet<NSString *> *callbackIdsToCancel;
@end

@implementation AppsflyerSdkPluginMultiEngineTests

- (void)setUp {
    [super setUp];
    self.pluginsToCancel = [NSMutableArray array];
    self.callbackIdsToCancel = [NSMutableSet set];
}

- (void)tearDown {
    for (AppsflyerSdkPlugin *plugin in self.pluginsToCancel) {
        for (NSString *callbackId in self.callbackIdsToCancel) {
            [self cancelListeningWithPlugin:plugin callbackId:callbackId];
        }
    }
    self.pluginsToCancel = nil;
    self.callbackIdsToCancel = nil;
    [super tearDown];
}

- (void)testDeepLinkCallbackOwnerSurvivesSecondaryEngineRegistration {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    (void)[self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afUDPCallback];

    NSString *payload = @"{\"id\":\"onDeepLinking\",\"deepLinkStatus\":\"FOUND\",\"deepLinkObj\":{}}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afUDPCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(mainMessenger.sentChannels.firstObject, afCallbacksMethodChannel);
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.arguments, payload);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 0);
}

- (void)testSecondaryEngineCannotStealExistingDeepLinkListener {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afUDPCallback];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afUDPCallback];

    NSString *payload = @"{\"id\":\"onDeepLinking\",\"deepLinkStatus\":\"FOUND\",\"deepLinkObj\":{}}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afUDPCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.arguments, payload);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 0);
}

- (void)testCallbackOwnerCanMoveAfterOwnerCancelsListening {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afUDPCallback];
    [self cancelListeningWithPlugin:mainPlugin callbackId:afUDPCallback];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afUDPCallback];

    NSString *payload = @"{\"id\":\"onDeepLinking\",\"deepLinkStatus\":\"FOUND\",\"deepLinkObj\":{}}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afUDPCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 0);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.arguments, payload);
}

- (void)testSecondaryEngineCancelDoesNotRemoveDeepLinkListenerOwner {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afUDPCallback];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afUDPCallback];
    [self cancelListeningWithPlugin:backgroundPlugin callbackId:afUDPCallback];

    XCTAssertTrue([AppsflyerSdkPlugin udpCallback]);

    NSString *payload = @"{\"id\":\"onDeepLinking\",\"deepLinkStatus\":\"FOUND\",\"deepLinkObj\":{}}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afUDPCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.arguments, payload);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 0);
}

- (void)testCallbackOwnerCanMoveAfterOwnerIsDeallocated {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];
    __weak AppsflyerSdkPlugin *weakOwnerPlugin = nil;

    @autoreleasepool {
        AppsflyerSdkPlugin *ownerPlugin = [[AppsflyerSdkPlugin alloc] initWithMessenger:mainMessenger];
        weakOwnerPlugin = ownerPlugin;
        [self startListeningWithPlugin:ownerPlugin callbackId:afUDPCallback];
    }

    XCTAssertNil(weakOwnerPlugin);

    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afUDPCallback];

    NSString *payload = @"{\"id\":\"onDeepLinking\",\"deepLinkStatus\":\"FOUND\",\"deepLinkObj\":{}}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afUDPCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 0);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.arguments, payload);
}

- (void)testInstallConversionCallbackUsesOwningEngine {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afGCDCallback];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afGCDCallback];

    XCTAssertTrue([AppsflyerSdkPlugin gcdCallback]);

    NSString *payload = @"{\"id\":\"onInstallConversionData\",\"data\":\"{}\",\"status\":\"success\"}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afGCDCallback arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(mainMessenger.sentMethodCalls.firstObject.arguments, payload);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 0);
}

- (void)testRequestScopedCallbackUsesLatestEngine {
    RecordingBinaryMessenger *mainMessenger = [[RecordingBinaryMessenger alloc] init];
    RecordingBinaryMessenger *backgroundMessenger = [[RecordingBinaryMessenger alloc] init];

    AppsflyerSdkPlugin *mainPlugin = [self pluginWithMessenger:mainMessenger];
    AppsflyerSdkPlugin *backgroundPlugin = [self pluginWithMessenger:backgroundMessenger];

    [self startListeningWithPlugin:mainPlugin callbackId:afGenerateInviteLinkSuccess];
    [self startListeningWithPlugin:backgroundPlugin callbackId:afGenerateInviteLinkSuccess];

    NSString *payload = @"{\"id\":\"generateInviteLinkSuccess\",\"data\":\"{}\",\"status\":\"success\"}";
    [AppsflyerSdkPlugin invokeCallbackWithId:afGenerateInviteLinkSuccess arguments:payload];

    XCTAssertEqual(mainMessenger.sentMethodCalls.count, 0);
    XCTAssertEqual(backgroundMessenger.sentMethodCalls.count, 1);
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.method, @"callListener");
    XCTAssertEqualObjects(backgroundMessenger.sentMethodCalls.firstObject.arguments, payload);
}

- (AppsflyerSdkPlugin *)pluginWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    AppsflyerSdkPlugin *plugin = [[AppsflyerSdkPlugin alloc] initWithMessenger:messenger];
    [self.pluginsToCancel addObject:plugin];
    return plugin;
}

- (void)startListeningWithPlugin:(AppsflyerSdkPlugin *)plugin callbackId:(NSString *)callbackId {
    [self.callbackIdsToCancel addObject:callbackId];
    FlutterMethodCall *call = [FlutterMethodCall methodCallWithMethodName:@"startListening" arguments:callbackId];
    [plugin handleMethodCall:call result:^(id result) {}];
}

- (void)cancelListeningWithPlugin:(AppsflyerSdkPlugin *)plugin callbackId:(NSString *)callbackId {
    FlutterMethodCall *call = [FlutterMethodCall methodCallWithMethodName:@"cancelListening" arguments:callbackId];
    [plugin handleMethodCall:call result:^(id result) {}];
}

@end
