import Flutter
import XCTest
@testable import appsflyer_sdk

/// Stands in for a separate `FlutterEngine` in the same process: each plugin instance built on its
/// own messenger models one engine registering `appsflyer_sdk`.
private final class FakeBinaryMessenger: NSObject, FlutterBinaryMessenger {
  private var nextConnection: FlutterBinaryMessengerConnection = 1

  func send(onChannel channel: String, message: Data?) {}

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {}

  func setMessageHandlerOnChannel(_ channel: String,
                                  binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil)
    -> FlutterBinaryMessengerConnection {
    nextConnection += 1
    return nextConnection
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

/// `AFRPCBridge` holds one process-wide event-handler slot while plugin instances are per engine.
/// A secondary engine (background engine reusing `GeneratedPluginRegistrant`, add-to-app) must not
/// take attribution and deep-link events away from the engine that owns them just by registering.
///
/// The test host app registers its own plugin instance first, so each test establishes its own
/// starting owner instead of assuming an empty slot.
@MainActor
final class MultiEngineEventHandlerTests: XCTestCase {

  private var engines: [(FakeBinaryMessenger, AppsflyerSdkPlugin)] = []

  override func tearDown() {
    engines.removeAll()
    super.tearDown()
  }

  private func registerEngine() -> AppsflyerSdkPlugin {
    let messenger = FakeBinaryMessenger()
    let plugin = AppsflyerSdkPlugin(messenger: messenger)
    engines.append((messenger, plugin))
    return plugin
  }

  private func releaseCurrentOwner() {
    if let owner = AFRPCBridge.eventHandlerOwner {
      AFRPCBridge.removeEventHandler(owner: owner)
    }
    XCTAssertNil(AFRPCBridge.eventHandlerOwner)
  }

  private func callInit(on plugin: AppsflyerSdkPlugin) {
    let call = FlutterMethodCall(methodName: "executeRpc",
                                 arguments: ["method": "init",
                                             "params": ["devKey": "test-dev-key", "appId": "123456789"]])
    plugin.handle(call) { _ in }
  }

  func testFirstRegistrationTakesFreeSlot() {
    releaseCurrentOwner()

    let main = registerEngine()

    XCTAssertTrue(AFRPCBridge.eventHandlerOwner === main)
  }

  func testSecondaryEngineRegistrationDoesNotStealSlot() {
    releaseCurrentOwner()
    let main = registerEngine()

    _ = registerEngine()

    XCTAssertTrue(AFRPCBridge.eventHandlerOwner === main)
  }

  func testInitClaimsSlotFromEarlierRegistration() {
    releaseCurrentOwner()
    _ = registerEngine()
    let initializing = registerEngine()

    callInit(on: initializing)

    XCTAssertTrue(AFRPCBridge.eventHandlerOwner === initializing)
  }

  func testSecondaryEngineDetachDoesNotReleaseOwnersSlot() {
    releaseCurrentOwner()
    let main = registerEngine()
    let secondary = registerEngine()

    AFRPCBridge.removeEventHandler(owner: secondary)

    XCTAssertTrue(AFRPCBridge.eventHandlerOwner === main)
  }

  func testRegistrationTakesSlotAfterOwnerIsReleased() {
    releaseCurrentOwner()
    autoreleasepool {
      let messenger = FakeBinaryMessenger()
      let released = AppsflyerSdkPlugin(messenger: messenger)
      XCTAssertTrue(AFRPCBridge.eventHandlerOwner === released)
    }
    XCTAssertNil(AFRPCBridge.eventHandlerOwner)

    let next = registerEngine()

    XCTAssertTrue(AFRPCBridge.eventHandlerOwner === next)
  }
}
