import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal `purchases.products.get` payload: every field the Google Play
/// Developer API documents as conditionally present is absent.
///
/// `purchaseToken` and `productId` are documented "May not be present",
/// `quantity` as "If not present, the quantity is 1", `purchaseType` as "only
/// set if this purchase was not made using the standard in-app billing flow",
/// and the obfuscated identifiers as "Only present if specified... when the
/// purchase was made". The remaining fields are proto3-serialized, so a field
/// left at its default value is omitted too.
const _minimalProductPurchase = <String, dynamic>{
  'kind': 'androidpublisher#productPurchase',
  'purchaseTimeMillis': '1712345678000',
  'purchaseState': 0,
  'consumptionState': 0,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('af-purchase-connector');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late PurchaseConnector connector;

  setUpAll(() {
    // The connector is a process-wide singleton, so it is built once. Outgoing
    // calls are mocked so `configure` does not throw MissingPluginException.
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    connector = PurchaseConnector(
      config: PurchaseConnectorConfiguration(
        logSubscriptions: true,
        logInApps: true,
        sandbox: true,
      ),
    );
  });

  tearDownAll(() => messenger.setMockMethodCallHandler(channel, null));

  /// Delivers [method] to the connector the way the native side does.
  ///
  /// Both natives serialize the payload before sending it — Android through
  /// `JSONObject(args).toString()` in `AppsFlyerPurchaseConnector.kt`, iOS
  /// through `toJSONString()` in `PurchaseConnectorPlugin.swift` — so the
  /// argument that arrives is a JSON string, not a map.
  Future<void> emit(String method, Object? payload) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        MethodCall(method, payload is String ? payload : jsonEncode(payload)),
      ),
      (_) {},
    );
  }

  setUp(() {
    connector.setInAppValidationResultListener(null, null);
    connector.setSubscriptionValidationResultListener(null, null);
    connector.setDidReceivePurchaseRevenueValidationInfo(null);
  });

  test('parses a Play payload that omits every conditionally present field',
      () {
    final purchase = ProductPurchase.fromJson(_minimalProductPurchase);

    expect(purchase.kind, 'androidpublisher#productPurchase');
    expect(purchase.purchaseState, 0);
    expect(purchase.developerPayload, isNull);
    expect(purchase.orderId, isNull);
    expect(purchase.quantity, isNull);
    expect(purchase.purchaseToken, isNull);
    expect(purchase.productId, isNull);
    expect(purchase.obfuscatedExternalAccountId, isNull);
    expect(purchase.regionCode, isNull);
  });

  test('delivers an in-app validation result built from a minimal payload',
      () async {
    Map<String, InAppPurchaseValidationResult>? delivered;
    String? failure;
    connector.setInAppValidationResultListener(
      (result) => delivered = result,
      (message, error) => failure = message,
    );

    await emit('InAppValidationResultListener:onResponse', {
      'token': {'success': true, 'productPurchase': _minimalProductPurchase},
    });

    expect(failure, isNull, reason: 'a well-formed payload is not a failure');
    expect(delivered!['token']!.success, isTrue);
    expect(delivered!['token']!.productPurchase!.orderId, isNull);
  });

  test('routes an unparseable in-app payload to onFailure', () async {
    Map<String, InAppPurchaseValidationResult>? delivered;
    String? failure;
    connector.setInAppValidationResultListener(
      (result) => delivered = result,
      (message, error) => failure = message,
    );

    // `success` is the one field the result envelope cannot do without.
    await emit('InAppValidationResultListener:onResponse', {
      'token': {'productPurchase': _minimalProductPurchase},
    });

    expect(delivered, isNull);
    expect(failure, contains('InAppValidationResultListener:onResponse'));
  });

  test('routes an unparseable subscription payload to onFailure', () async {
    Map<String, SubscriptionValidationResult>? delivered;
    String? failure;
    connector.setSubscriptionValidationResultListener(
      (result) => delivered = result,
      (message, error) => failure = message,
    );

    await emit('SubscriptionPurchaseValidationResultListener:onResponse', {
      'token': {'subscriptionPurchase': <String, dynamic>{}},
    });

    expect(delivered, isNull);
    expect(failure, isNotNull);
  });

  test('the parse-failure message carries no payload content', () async {
    String? failure;
    connector.setInAppValidationResultListener(null, (message, _) {
      failure = message;
    });

    await emit('InAppValidationResultListener:onResponse', {
      'token': {
        'productPurchase': {
          ..._minimalProductPurchase,
          'purchaseState': 'not-an-int',
          'obfuscatedExternalAccountId': 'account-4471',
        },
      },
    });

    expect(failure, isNotNull);
    expect(failure, isNot(contains('account-4471')));
    expect(failure, isNot(contains('not-an-int')));
  });

  test('reports a failure whose payload omits the result description',
      () async {
    String? failure;
    JVMThrowable? reported;
    connector.setInAppValidationResultListener(null, (message, error) {
      failure = message;
      reported = error;
    });

    await emit('InAppValidationResultListener:onFailure', {
      'error': {'type': 'java.io.IOException'},
    });

    expect(failure, isNotNull);
    expect(reported!.type, 'java.io.IOException');
    expect(reported!.message, isNull);
  });

  test('a malformed iOS validation payload still reaches the callback',
      () async {
    var called = false;
    Map<String, dynamic>? info;
    connector.setDidReceivePurchaseRevenueValidationInfo((i, error) {
      called = true;
      info = i;
    });

    await emit('didReceivePurchaseRevenueValidationInfo', '{ not json');

    expect(called, isTrue);
    expect(info, isNull);
  });
}
