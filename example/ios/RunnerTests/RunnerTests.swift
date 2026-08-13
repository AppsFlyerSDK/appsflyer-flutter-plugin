import XCTest

/// Pins the Foundation behavior the iOS plugin relies on instead of an Objective-C `@try`/`@catch`
/// boundary around RPC dispatch.
///
/// `JSONSerialization.data(withJSONObject:)` raises `NSInvalidArgumentException` — not a catchable
/// Swift error — for non-finite numbers, and Dart can send them (`logEvent` with `double.nan`).
/// `AFRPCBridge`-bound payloads reach Foundation only through `jsonString(from:)`, which calls
/// `isValidJSONObject` first, so these are rejected as a `SERIALIZATION_ERROR` before any write is
/// attempted. If a future OS stops rejecting them up front, this test fails and the exception
/// boundary has to come back.
class RPCPayloadSerializationTests: XCTestCase {

  /// Mirrors `jsonString(from:)` in `AppsflyerSdkPlugin.swift`.
  private func jsonString(from object: Any) -> String? {
    guard JSONSerialization.isValidJSONObject(object),
          let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func envelope(value: Any) -> [String: Any] {
    return ["method": "logEvent", "params": ["eventValues": ["revenue": value]]]
  }

  func testNonFiniteNumbersAreRejectedBeforeSerialization() {
    let nonFinite: [String: Any] = [
      "Double.nan": Double.nan,
      "Double.infinity": Double.infinity,
      "-Double.infinity": -Double.infinity,
      "Float.nan": Float.nan,
      "NSDecimalNumber.notANumber": NSDecimalNumber.notANumber
    ]
    for (name, value) in nonFinite {
      let object = envelope(value: value)
      XCTAssertFalse(JSONSerialization.isValidJSONObject(object),
                     "\(name) must be rejected before data(withJSONObject:) is reached")
      XCTAssertNil(jsonString(from: object), "\(name) must serialize to nil, not crash")
    }
  }

  func testFiniteNumbersStillSerialize() {
    XCTAssertNotNil(jsonString(from: envelope(value: 12.5)))
    XCTAssertNotNil(jsonString(from: envelope(value: 0)))
  }
}
