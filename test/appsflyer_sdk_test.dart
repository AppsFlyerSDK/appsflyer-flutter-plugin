import 'dart:async';
import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('af-api');
  const eventChannel = EventChannel('af-events');
  const eventMethodChannel = MethodChannel('af-events');

  late String? rpcMethod;
  late Map<String, dynamic>? rpcParams;
  late Object? rpcResult;
  late List<String> eventChannelCalls;
  late AppsFlyerSdk androidSdk;
  late AppsFlyerSdk iosSdk;

  setUp(() {
    rpcMethod = null;
    rpcParams = null;
    rpcResult = null;
    eventChannelCalls = <String>[];

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      expect(call.method, 'executeRpc');
      final args = Map<String, dynamic>.from(call.arguments as Map);
      rpcMethod = args['method'] as String;
      rpcParams = Map<String, dynamic>.from(args['params'] as Map);
      return rpcResult;
    });
    messenger.setMockMethodCallHandler(eventMethodChannel, (call) async {
      eventChannelCalls.add(call.method);
      return null;
    });

    androidSdk = AppsFlyerSdk.private(
      methodChannel,
      eventChannel,
      platform: TargetPlatform.android,
    );
    iosSdk = AppsFlyerSdk.private(
      methodChannel,
      eventChannel,
      platform: TargetPlatform.iOS,
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventMethodChannel, null);
  });

  group('lifecycle', () {
    test('init sends the iOS initialization parameters', () async {
      await iosSdk.init(
        devKey: 'ios-dev-key',
        appId: '123456789',
      );

      expect(rpcMethod, 'init');
      expect(rpcParams, {
        'devKey': 'ios-dev-key',
        'appId': '123456789',
      });
    });

    test('init does not send appId to Android', () async {
      await androidSdk.init(
        devKey: 'android-dev-key',
        appId: 'ignored-on-android',
      );

      expect(rpcMethod, 'init');
      expect(rpcParams, {'devKey': 'android-dev-key'});
    });

    test('init allows Android without appId', () async {
      await androidSdk.init(devKey: 'android-dev-key');

      expect(rpcMethod, 'init');
      expect(rpcParams, {'devKey': 'android-dev-key'});
    });

    test('init forwards invalid values to the native RPC layer', () async {
      await androidSdk.init(devKey: '');
      expect(rpcMethod, 'init');
      expect(rpcParams, {'devKey': ''});

      await iosSdk.init(devKey: 'ios-dev-key');
      expect(rpcMethod, 'init');
      expect(rpcParams, {'devKey': 'ios-dev-key', 'appId': null});

      await iosSdk.init(devKey: 'ios-dev-key', appId: '');
      expect(rpcMethod, 'init');
      expect(rpcParams, {'devKey': 'ios-dev-key', 'appId': ''});
    });

    test('the public SDK entry point is a singleton', () {
      expect(AppsFlyerSdk.instance, same(AppsFlyerSdk.instance));
    });

    test('pluginVersion exposes the compiled plugin version constant', () {
      expect(androidSdk.pluginVersion, '7.0.1');
      expect(iosSdk.pluginVersion, '7.0.1');
    });

    test('listeners are registered explicitly', () async {
      await androidSdk.registerConversionListener(onSuccess: (_) {});
      expect(rpcMethod, 'registerConversionListener');

      await androidSdk.registerDeepLinkListener((_) {});
      expect(rpcMethod, 'subscribeForDeepLink');

      await iosSdk.registerDeepLinkListener((_) {});
      expect(rpcMethod, 'registerDeeplinkListener');

      await iosSdk.registerSessionReadyListener(() {});
      expect(rpcMethod, 'registerSessionReadyListener');
    });

    test('start is fire-and-forget by default', () async {
      await androidSdk.start();
      expect(rpcMethod, 'start');
      expect(rpcParams, {'awaitResponse': false});
    });

    test('start can wait for the native request callback', () async {
      await androidSdk.start(awaitResponse: true);
      expect(rpcMethod, 'start');
      expect(rpcParams, {'awaitResponse': true});
    });

    test('start with awaitResponse throws AppsFlyerException on RPC failure',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (_) async {
        throw PlatformException(
          code: '500',
          message: 'Session launch failed',
        );
      });

      await expectLater(
        androidSdk.start(awaitResponse: true),
        throwsA(
          isA<AppsFlyerException>()
              .having((error) => error.code, 'code', 500)
              .having(
                (error) => error.message,
                'message',
                'Session launch failed',
              ),
        ),
      );
    });

    test('enableDebug maps to the isDebug RPC method', () async {
      await iosSdk.enableDebug(true);
      expect(rpcMethod, 'isDebug');
      expect(rpcParams, {'isDebug': true});
    });

    test('isSessionReady returns the native result', () async {
      rpcResult = true;
      expect(await iosSdk.isSessionReady(), isTrue);
      expect(rpcMethod, 'isSessionReady');
    });
  });

  group('requests and errors', () {
    test('void RPC calls always send an empty params map', () async {
      await androidSdk.disableAppSetId();

      expect(rpcMethod, 'disableAppSetId');
      expect(rpcParams, isNotNull);
      expect(rpcParams, isEmpty);
    });

    test('logEvent is fire-and-forget by default', () async {
      await androidSdk.logEvent(
        'af_purchase',
        eventValues: {'revenue': 4.2},
      );

      expect(rpcMethod, 'logEvent');
      expect(rpcParams, {
        'eventName': 'af_purchase',
        'eventValues': {'revenue': 4.2},
        'awaitResponse': false,
      });
    });

    test('logEvent can wait for the native request callback', () async {
      await androidSdk.logEvent(
        'af_purchase',
        eventValues: {'revenue': 4.2},
        awaitResponse: true,
      );

      expect(rpcMethod, 'logEvent');
      expect(rpcParams, {
        'eventName': 'af_purchase',
        'eventValues': {'revenue': 4.2},
        'awaitResponse': true,
      });
    });

    test(
        'PlatformException with a numeric RPC code becomes '
        'AppsFlyerException', () async {
      // Matches the real native shape: RpcResponse.Error/AFRPCError report a
      // numeric, HTTP-style code as a string, with no details map.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (_) async {
        throw PlatformException(
          code: '422',
          message: 'devKey cannot be empty',
        );
      });

      await expectLater(
        androidSdk.logEvent('', eventValues: null),
        throwsA(
          isA<AppsFlyerException>()
              .having((error) => error.code, 'code', 422)
              .having((error) => error.message, 'message',
                  'devKey cannot be empty'),
        ),
      );
    });

    test(
        'PlatformException with a non-numeric plugin-guard code leaves '
        'code null', () async {
      // Matches guards that fail before reaching the RPC layer (a malformed
      // channel call, a JSON parse failure) — these report a non-numeric
      // code, e.g. "INVALID_PARAMETERS", which has no HTTP-style equivalent.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (_) async {
        throw PlatformException(
          code: 'INVALID_PARAMETERS',
          message: "executeRpc requires a 'method'",
        );
      });

      await expectLater(
        androidSdk.logEvent('', eventValues: null),
        throwsA(
          isA<AppsFlyerException>()
              .having((error) => error.code, 'code', isNull)
              .having(
                (error) => error.message,
                'message',
                "executeRpc requires a 'method'",
              ),
        ),
      );
    });

    test('MissingPluginException is not converted to AppsFlyerException',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (_) async {
        throw MissingPluginException('No implementation found');
      });

      await expectLater(
        androidSdk.logEvent('', eventValues: null),
        throwsA(isA<MissingPluginException>()),
      );
    });

    test('unexpected RPC result type becomes AppsFlyerException', () async {
      rpcResult = 1;

      await expectLater(
        androidSdk.isSessionReady(),
        throwsA(
          isA<AppsFlyerException>().having(
            (error) => error.message,
            'message',
            'Unexpected RPC result type for isSessionReady: int',
          ),
        ),
      );
      expect(rpcMethod, 'isSessionReady');
    });

    test('unexpected null RPC result throws AppsFlyerException', () async {
      rpcResult = null;

      for (final call in <Future<Object?> Function()>[
        iosSdk.isSessionReady,
        androidSdk.isStopped,
        androidSdk.isPreInstalledApp,
        androidSdk.getHostName,
        androidSdk.getHostPrefix,
      ]) {
        await expectLater(
          call(),
          throwsA(
            isA<AppsFlyerException>().having(
              (error) => error.message,
              'message',
              '$rpcMethod returned no value',
            ),
          ),
        );
      }
    });

    test(
        'platform-only calls are forwarded to the native RPC instead of being '
        'swallowed in Dart', () async {
      // Which platform implements which method is the RPC contract's to know.
      // Mirroring that list in Dart would silently go stale the moment a
      // native SDK adds support, so every call is forwarded and the native
      // layer decides.
      final forwarded = <String, Future<void> Function()>{
        'setCollectAndroidID': () => iosSdk.setCollectAndroidID(true),
        'setLogLevel': () => iosSdk.setLogLevel(AFLogLevel.debug),
        'logSession': () => iosSdk.logSession(),
        'setOutOfStore': () => iosSdk.setOutOfStore('source'),
        'setIsUpdate': () => iosSdk.setIsUpdate(true),
        'setAppId': () => iosSdk.setAppId('123'),
        'disableAppSetId': () => iosSdk.disableAppSetId(),
        'setDisableSKAdNetwork': () => androidSdk.setDisableSKAdNetwork(true),
        'setDisableCollectASA': () => androidSdk.setDisableCollectASA(true),
        'setCurrentDeviceLanguage': () =>
            androidSdk.setCurrentDeviceLanguage('en'),
        'handlePushNotification': () =>
            androidSdk.handlePushNotification({'aps': {}}),
      };

      for (final entry in forwarded.entries) {
        rpcMethod = null;
        await entry.value();
        expect(rpcMethod, entry.key);
      }
    });

    test('an off-platform getter forwards rather than fabricating a value',
        () async {
      // Returning a plausible `false` here would be indistinguishable from a
      // genuine "not stopped" answer.
      rpcResult = true;

      expect(await iosSdk.isStopped(), isTrue);
      expect(rpcMethod, 'isStopped');
    });

    test('platform-only getters surface the native method-not-found error',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        rpcMethod = args['method'] as String;
        throw PlatformException(
          code: '404',
          message: 'Method not found: $rpcMethod',
        );
      });

      for (final getter in <Future<Object?> Function()>[
        iosSdk.getHostName,
        iosSdk.getHostPrefix,
        iosSdk.getOutOfStore,
        iosSdk.getAttributionId,
        () => iosSdk.isPreInstalledApp(),
        () => iosSdk.isStopped(),
      ]) {
        await expectLater(
          getter(),
          throwsA(
            isA<AppsFlyerException>()
                .having((error) => error.code, 'code', 404)
                .having(
                  (error) => error.message,
                  'message',
                  'Method not found: $rpcMethod',
                ),
          ),
        );
      }
    });

    test('platform-only setters surface the native error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        rpcMethod = args['method'] as String;
        throw PlatformException(
          code: '422',
          message: 'Unknown RPC method: $rpcMethod',
        );
      });

      for (final setter in <Future<void> Function()>[
        () => androidSdk.setUseReceiptValidationSandbox(true),
        () => androidSdk.setUseUninstallSandbox(true),
        () => androidSdk.setDisableIDFVCollection(true),
        () => iosSdk.setCollectAndroidID(true),
      ]) {
        await expectLater(
          setter(),
          throwsA(
            isA<AppsFlyerException>()
                .having((error) => error.code, 'code', 422)
                .having(
                  (error) => error.message,
                  'message',
                  'Unknown RPC method: $rpcMethod',
                ),
          ),
        );
      }
    });

    test('iOS ASA collection is configured through an explicit setter',
        () async {
      await iosSdk.setDisableCollectASA(true);
      expect(rpcMethod, 'setDisableCollectASA');
      expect(rpcParams, {'disable': true});
    });

    test('Android clear requests reach the native RPC layer', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        rpcMethod = args['method'] as String;
        rpcParams = Map<String, dynamic>.from(args['params'] as Map);
        throw PlatformException(
          code: '422',
          message: 'partners must not be empty',
        );
      });

      for (final partners in <List<String>?>[null, []]) {
        await expectLater(
          androidSdk.setSharingFilterForPartners(partners),
          throwsA(
            isA<AppsFlyerException>()
                .having((error) => error.code, 'code', 422)
                .having(
                  (error) => error.message,
                  'message',
                  'partners must not be empty',
                ),
          ),
        );
        expect(rpcMethod, 'setSharingFilterForPartners');
        expect(rpcParams, {'partners': null});
      }
    });
  });

  group('models and platform payloads', () {
    test('setConsentData forwards incomplete GDPR payloads to native RPC',
        () async {
      await androidSdk.setConsentData(isUserSubjectToGDPR: true);

      expect(rpcMethod, 'setConsentData');
      expect(rpcParams, {
        'isUserSubjectToGDPR': true,
        'hasConsentForDataUsage': null,
        'hasConsentForAdsPersonalization': null,
        'hasConsentForAdStorage': null,
      });
    });

    test('maps every mediation network to the native RPC string', () async {
      const androidMediationNetworks = {
        ..._sharedMediationNetworkRpcValues,
        AFMediationNetwork.customMediation: 'custom_mediation',
        AFMediationNetwork.directMonetizationNetwork:
            'direct_monetization_network',
      };
      const iosMediationNetworks = {
        ..._sharedMediationNetworkRpcValues,
        AFMediationNetwork.customMediation: 'custom',
        AFMediationNetwork.directMonetizationNetwork: 'directmonetization',
      };

      await _expectLogAdRevenueMediationNetworks(
        androidSdk,
        androidMediationNetworks,
        () => rpcParams,
      );
      await _expectLogAdRevenueMediationNetworks(
        iosSdk,
        iosMediationNetworks,
        () => rpcParams,
      );
    });

    test('purchase validation sends the Android contract', () async {
      rpcResult = {'status': 'verified'};
      const purchase = AFAndroidPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        productId: 'sku',
        purchaseToken: 'token',
      );

      expect(
        await androidSdk.validateAndLogInAppPurchase(purchase),
        {'status': 'verified'},
      );
      expect(rpcParams, {
        'purchaseType': 'one_time_purchase',
        'purchaseToken': 'token',
        'productId': 'sku',
        'additionalParameters': null,
        'awaitResponse': true,
      });
    });

    test('purchase validation sends the iOS contract', () async {
      rpcResult = <String, dynamic>{};
      const purchase = AFIOSPurchaseDetails(
        purchaseType: AFPurchaseType.subscription,
        productId: 'sku',
        transactionId: 'transaction',
      );

      await iosSdk.validateAndLogInAppPurchase(purchase);
      expect(rpcParams, {
        'product': {'productId': 'sku'},
        'transaction': {
          'transactionId': 'transaction',
          'purchaseType': 'subscription',
        },
        'additionalParameters': null,
      });
    });

    test('purchase validation returns an empty map when native result is null',
        () async {
      rpcResult = null;
      const purchase = AFAndroidPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        productId: 'sku',
        purchaseToken: 'token',
      );

      expect(
        await androidSdk.validateAndLogInAppPurchase(
          purchase,
          awaitResponse: false,
        ),
        isEmpty,
      );
    });

    test('purchase validation forwards awaitResponse only to Android',
        () async {
      rpcResult = <String, dynamic>{};

      await androidSdk.validateAndLogInAppPurchase(
        const AFAndroidPurchaseDetails(
          purchaseType: AFPurchaseType.oneTimePurchase,
          productId: 'android-sku',
          purchaseToken: 'token',
        ),
        awaitResponse: false,
      );
      expect(rpcParams!['awaitResponse'], isFalse);

      await iosSdk.validateAndLogInAppPurchase(
        const AFIOSPurchaseDetails(
          purchaseType: AFPurchaseType.subscription,
          productId: 'ios-sku',
          transactionId: 'transaction',
        ),
        awaitResponse: false,
      );
      expect(rpcParams, isNot(contains('awaitResponse')));
    });

    test('purchase details reject the wrong platform', () async {
      const androidPurchase = AFAndroidPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        productId: 'android-sku',
        purchaseToken: 'token',
      );
      const iosPurchase = AFIOSPurchaseDetails(
        purchaseType: AFPurchaseType.subscription,
        productId: 'ios-sku',
        transactionId: 'transaction',
      );

      await expectLater(
        iosSdk.validateAndLogInAppPurchase(androidPurchase),
        throwsArgumentError,
      );
      await expectLater(
        androidSdk.validateAndLogInAppPurchase(iosPurchase),
        throwsArgumentError,
      );

      // Neither details type is usable on a platform the plugin does not ship
      // a native bridge for.
      expect(
        () => androidPurchase.toRpcMap(platform: TargetPlatform.macOS),
        throwsArgumentError,
      );
      expect(
        () => iosPurchase.toRpcMap(platform: TargetPlatform.windows),
        throwsArgumentError,
      );
    });

    test('generateInviteLink returns its per-call result', () async {
      rpcResult = 'https://example.onelink.me/invite';

      final link = await androidSdk.generateInviteLink(
        parameters: const AppsFlyerInviteLinkParams(
          referrerCustomerId: 'customer',
          userParams: {'source': 'share'},
        ),
      );

      expect(link, 'https://example.onelink.me/invite');
      expect(rpcMethod, 'generateInviteLink');
      expect(rpcParams!['customerId'], 'customer');
      expect(rpcParams!['userParams'], {'source': 'share'});
      expect(rpcParams!['awaitResponse'], isTrue);
    });

    test('generateInviteLink forwards awaitResponse only to Android', () async {
      rpcResult = 'https://example.onelink.me/invite';

      await androidSdk.generateInviteLink(awaitResponse: false);
      expect(rpcParams!['awaitResponse'], isFalse);

      await iosSdk.generateInviteLink(awaitResponse: false);
      expect(rpcParams, isNot(contains('awaitResponse')));
    });

    test(
        'generateInviteLink throws AppsFlyerException when native returns null',
        () async {
      rpcResult = null;

      expect(
        () => androidSdk.generateInviteLink(),
        throwsA(
          isA<AppsFlyerException>().having(
            (error) => error.message,
            'message',
            'generateInviteLink returned no value',
          ),
        ),
      );
    });
  });

  group('complete RPC mapping', () {
    Future<void> expectVoidRpc(
      Future<void> Function() invoke,
      String method,
      Map<String, dynamic> params,
    ) async {
      rpcMethod = null;
      rpcParams = null;
      await invoke();
      expect(rpcMethod, method);
      expect(rpcParams, params);
    }

    test('maps cross-platform configuration and identity APIs', () async {
      await expectVoidRpc(
        () => androidSdk.setCustomerUserId('customer'),
        'setCustomerUserId',
        {'customerId': 'customer'},
      );
      await expectVoidRpc(
        () => androidSdk.setUserEmail('hash-me@example.com'),
        'setUserEmail',
        {'email': 'hash-me@example.com'},
      );
      await expectVoidRpc(
        () => androidSdk.setUserPhone('+1', '5551234'),
        'setUserPhone',
        {'countryCode': '+1', 'phoneNumber': '5551234'},
      );
      await expectVoidRpc(
        () => androidSdk.setUserFirstName('Ada'),
        'setUserFirstName',
        {'firstName': 'Ada'},
      );
      await expectVoidRpc(
        () => androidSdk.setUserLastName('Lovelace'),
        'setUserLastName',
        {'lastName': 'Lovelace'},
      );
      await expectVoidRpc(
        () => androidSdk.setUserFbLoginId(42),
        'setUserFbLoginId',
        {'fbLoginId': 42},
      );
      await expectVoidRpc(
        androidSdk.clearUserPii,
        'clearUserPii',
        {},
      );
      await expectVoidRpc(
        () => androidSdk.setCurrencyCode('USD'),
        'setCurrencyCode',
        {'currencyCode': 'USD'},
      );
      await expectVoidRpc(
        () => androidSdk.setMinTimeBetweenSessions(15),
        'setMinTimeBetweenSessions',
        {'seconds': 15},
      );
      await expectVoidRpc(
        () => androidSdk.setHost('prefix', 'example.com'),
        'setHost',
        {'hostPrefixName': 'prefix', 'hostName': 'example.com'},
      );
      await expectVoidRpc(
        () => androidSdk.setAdditionalData({'source': 'flutter'}),
        'setAdditionalData',
        {
          'customData': {'source': 'flutter'},
        },
      );
      await expectVoidRpc(
        () => androidSdk.setAppInviteOneLink('one-link'),
        'setAppInviteOneLink',
        {'oneLinkId': 'one-link'},
      );
      await expectVoidRpc(
        () => androidSdk.setPartnerData('partner', {'key': 'value'}),
        'setPartnerData',
        {
          'partnerId': 'partner',
          'data': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => androidSdk.setSharingFilterForPartners(['partner']),
        'setSharingFilterForPartners',
        {
          'partners': ['partner'],
        },
      );
      // An empty list means "clear", which the iOS RPC only honors for null.
      await expectVoidRpc(
        () => iosSdk.setSharingFilterForPartners([]),
        'setSharingFilterForPartners',
        {'partners': null},
      );
      await expectVoidRpc(
        () => iosSdk.setSharingFilterForPartners(null),
        'setSharingFilterForPartners',
        {'partners': null},
      );
      await expectVoidRpc(
        () => androidSdk.setInstallId('install-id'),
        'setInstallId',
        {'installId': 'install-id'},
      );
      await expectVoidRpc(
        () => androidSdk.setConsentData(
          isUserSubjectToGDPR: true,
          hasConsentForDataUsage: true,
          hasConsentForAdsPersonalization: false,
          hasConsentForAdStorage: true,
        ),
        'setConsentData',
        {
          'isUserSubjectToGDPR': true,
          'hasConsentForDataUsage': true,
          'hasConsentForAdsPersonalization': false,
          'hasConsentForAdStorage': true,
        },
      );
      await expectVoidRpc(
        () => androidSdk.enableTCFDataCollection(true),
        'enableTCFDataCollection',
        {'shouldCollect': true},
      );
      await expectVoidRpc(
        () => androidSdk.anonymizeUser(true),
        'anonymizeUser',
        {'shouldAnonymize': true},
      );
      await expectVoidRpc(
        () => androidSdk.stop(true),
        'stop',
        {'shouldStop': true},
      );
      await expectVoidRpc(
        () => androidSdk.setDisableAdvertisingIdentifiers(true),
        'setDisableAdvertisingIdentifiers',
        {'isDisable': true},
      );
      await expectVoidRpc(
        () => iosSdk.setDisableAdvertisingIdentifiers(true),
        'setDisableAdvertisingIdentifiers',
        {'disable': true},
      );
    });

    test('maps deep-link, sharing, push, and uninstall APIs', () async {
      await expectVoidRpc(
        () => androidSdk.logLocation(
          latitude: 1.5,
          longitude: -2.5,
        ),
        'logLocation',
        {'latitude': 1.5, 'longitude': -2.5},
      );
      await expectVoidRpc(
        () => androidSdk.logCrossPromoteImpression(
          'promoted',
          campaign: 'campaign',
          userParams: {'key': 'value'},
        ),
        'logCrossPromoteImpression',
        {
          'appId': 'promoted',
          'campaign': 'campaign',
          'userParams': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => iosSdk.logAndOpenStore(
          'promoted',
          campaign: 'campaign',
          userParams: {'key': 'value'},
        ),
        'logAndOpenStore',
        {
          'promotedAppId': 'promoted',
          'campaign': 'campaign',
          'userParams': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => androidSdk.logInvite('email', {'key': 'value'}),
        'logInvite',
        {
          'channel': 'email',
          'eventParameters': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => androidSdk.performDeepLinking(
          'https://example.com/path',
          shouldTriggerSession: true,
        ),
        'performDeepLinking',
        {
          'url': 'https://example.com/path',
          'shouldTriggerSession': true,
        },
      );
      await expectVoidRpc(
        () => iosSdk.performDeepLinking('https://example.com/path'),
        'performOnAppAttributionWithURL',
        {'url': 'https://example.com/path'},
      );
      await expectVoidRpc(
        () => androidSdk.setResolveDeepLinkURLs(['example.com']),
        'setResolveDeepLinkURLs',
        {
          'urls': ['example.com'],
        },
      );
      await expectVoidRpc(
        () => androidSdk.setOneLinkCustomDomain(['links.example.com']),
        'setOneLinkCustomDomain',
        {
          'domains': ['links.example.com'],
        },
      );
      await expectVoidRpc(
        () => androidSdk.setDeepLinkTimeout(3000),
        'setDeepLinkTimeout',
        {'timeout': 3000},
      );
      await expectVoidRpc(
        () => androidSdk.addPushNotificationDeepLinkPath(['data', 'link']),
        'addPushNotificationDeepLinkPath',
        {
          'deepLinkPath': ['data', 'link'],
        },
      );
      await expectVoidRpc(
        () => androidSdk.enableFacebookDeferredApplinks(true),
        'enableFacebookDeferredApplinks',
        {'isEnabled': true},
      );
      await expectVoidRpc(
        () => androidSdk.appendParametersToDeepLinkingURL(
          'example.com',
          {'key': 'value'},
        ),
        'appendParametersToDeepLinkingURL',
        {
          'contains': 'example.com',
          'parameters': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => iosSdk.setFacebookDeferredAppLink(null),
        'setFacebookDeferredAppLink',
        {'url': null},
      );
      await expectVoidRpc(
        () => androidSdk.sendPushNotificationData(
          campaign: 'campaign',
          pid: 'media-source',
          isRetargeting: true,
          additionalParameters: {'key': 'value'},
        ),
        'sendPushNotificationData',
        {
          'campaign': 'campaign',
          'pid': 'media-source',
          'isRetargeting': true,
          'additionalParameters': {'key': 'value'},
        },
      );
      await expectVoidRpc(
        () => iosSdk.handlePushNotification({'aps': {}}),
        'handlePushNotification',
        {
          'pushPayload': {'aps': {}},
        },
      );
      await expectVoidRpc(
        () => androidSdk.updateServerUninstallToken('fcm-token'),
        'updateServerUninstallToken',
        {'token': 'fcm-token'},
      );
      await expectVoidRpc(
        () => iosSdk.updateServerUninstallToken('0123456789abcdef'),
        'registerUninstall',
        {'deviceToken': '0123456789abcdef'},
      );
    });

    test('maps every Android-only API', () async {
      const logLevels = {
        AFLogLevel.none: 'NONE',
        AFLogLevel.error: 'ERROR',
        AFLogLevel.warning: 'WARNING',
        AFLogLevel.info: 'INFO',
        AFLogLevel.debug: 'DEBUG',
        AFLogLevel.verbose: 'VERBOSE',
      };

      for (final entry in logLevels.entries) {
        await expectVoidRpc(
          () => androidSdk.setLogLevel(entry.key),
          'setLogLevel',
          {'logLevel': entry.value},
        );
      }

      await expectVoidRpc(
        androidSdk.unregisterDeeplinkListener,
        'unsubscribeForDeepLink',
        {},
      );
      await expectVoidRpc(
        androidSdk.unregisterConversionListener,
        'unregisterConversionListener',
        {},
      );

      await expectVoidRpc(androidSdk.logSession, 'logSession', {});
      await expectVoidRpc(
        () => androidSdk.setOutOfStore('amazon'),
        'setOutOfStore',
        {'sourceName': 'amazon'},
      );
      await expectVoidRpc(
        () => androidSdk.setIsUpdate(true),
        'setIsUpdate',
        {'isUpdate': true},
      );
      await expectVoidRpc(
        () => androidSdk.setPreinstallAttribution(
          'media',
          campaign: 'campaign',
          siteId: 'site',
        ),
        'setPreinstallAttribution',
        {
          'mediaSource': 'media',
          'campaign': 'campaign',
          'siteId': 'site',
        },
      );
      await expectVoidRpc(
        () => androidSdk.setAppId('com.example.app'),
        'setAppId',
        {'appId': 'com.example.app'},
      );
      await expectVoidRpc(
        () => androidSdk.setCollectAndroidID(true),
        'setCollectAndroidID',
        {'isCollect': true},
      );
      await expectVoidRpc(
        () => androidSdk.setDisableNetworkData(true),
        'setDisableNetworkData',
        {'isDisable': true},
      );
      await expectVoidRpc(
        androidSdk.disableAppSetId,
        'disableAppSetId',
        {},
      );
    });

    test('maps every iOS-only API', () async {
      await expectVoidRpc(
        () => iosSdk.setCurrentDeviceLanguage('en'),
        'setCurrentDeviceLanguage',
        {'language': 'en'},
      );
      await expectVoidRpc(
        () => iosSdk.setDisableCollectASA(true),
        'setDisableCollectASA',
        {'disable': true},
      );
      await expectVoidRpc(
        () => iosSdk.setDisableSKAdNetwork(true),
        'setDisableSKAdNetwork',
        {'disable': true},
      );
      await expectVoidRpc(
        () => iosSdk.setDisableAppleAdsAttribution(true),
        'setDisableAppleAdsAttribution',
        {'disable': true},
      );
      await expectVoidRpc(
        () => iosSdk.setDisableIDFVCollection(true),
        'setDisableIDFVCollection',
        {'disable': true},
      );
      await expectVoidRpc(
        () => iosSdk.setShouldCollectDeviceName(true),
        'setShouldCollectDeviceName',
        {'collect': true},
      );
      await expectVoidRpc(
        () => iosSdk.setUseReceiptValidationSandbox(true),
        'setUseReceiptValidationSandbox',
        {'sandbox': true},
      );
      await expectVoidRpc(
        () => iosSdk.setUseUninstallSandbox(true),
        'setUseUninstallSandbox',
        {'sandbox': true},
      );
    });

    test('maps getters and native return values', () async {
      rpcResult = 'host.example.com';
      expect(await androidSdk.getHostName(), 'host.example.com');
      expect(rpcMethod, 'getHostName');
      expect(rpcParams, isEmpty);

      rpcResult = 'prefix';
      expect(await androidSdk.getHostPrefix(), 'prefix');
      expect(rpcMethod, 'getHostPrefix');

      rpcResult = 'amazon';
      expect(await androidSdk.getOutOfStore(), 'amazon');
      expect(rpcMethod, 'getOutOfStore');

      rpcResult = true;
      expect(await androidSdk.isStopped(), isTrue);
      expect(rpcMethod, 'isStopped');

      rpcResult = '7.0.1';
      expect(await iosSdk.getSdkVersion(), '7.0.1');
      expect(rpcMethod, 'getSdkVersion');
      expect(rpcParams, isEmpty);

      rpcResult = null;
      expect(
        () => iosSdk.getSdkVersion(),
        throwsA(
          isA<AppsFlyerException>().having(
            (error) => error.message,
            'message',
            'getSdkVersion returned no value',
          ),
        ),
      );

      rpcResult = 'uid';
      expect(await iosSdk.getAppsFlyerUID(), 'uid');
      expect(rpcMethod, 'getAppsFlyerUID');

      rpcResult = true;
      expect(await androidSdk.isPreInstalledApp(), isTrue);
      expect(rpcMethod, 'isPreInstalledApp');

      rpcResult = 'attribution';
      expect(await androidSdk.getAttributionId(), 'attribution');
      expect(rpcMethod, 'getAttributionId');
    });

    test('maps listener removal and iOS invite payload/result', () async {
      await expectVoidRpc(
        iosSdk.unregisterSessionReadyListener,
        'unregisterSessionReadyListener',
        {},
      );

      rpcResult = 'https://example.onelink.me/invite';
      final link = await iosSdk.generateInviteLink(
        parameters: const AppsFlyerInviteLinkParams(
          referrerCustomerId: 'customer',
          userParams: {'source': 'share'},
        ),
      );
      expect(link, 'https://example.onelink.me/invite');
      expect(rpcMethod, 'generateInviteLink');
      expect(rpcParams!['referrerCustomerId'], 'customer');
      expect(rpcParams!['userParams'], {'source': 'share'});
      expect(rpcParams, isNot(contains('awaitResponse')));
    });
  });

  group('event routing', () {
    test('subscribes to af-events only when the first listener is registered',
        () async {
      expect(eventChannelCalls, isEmpty);

      await androidSdk.registerSessionReadyListener(() {});
      await pumpEventQueue();

      expect(eventChannelCalls, ['listen']);

      await androidSdk.registerConversionListener(onSuccess: (_) {});
      await pumpEventQueue();

      // One transport subscription for the whole plugin, not one per listener.
      expect(eventChannelCalls, ['listen']);
    });

    test('rolls back Dart callbacks when native registration RPC fails',
        () async {
      Future<Object?> failingRegistrationHandler(MethodCall call) async {
        expect(call.method, 'executeRpc');
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final method = args['method'] as String;
        rpcMethod = method;
        rpcParams = Map<String, dynamic>.from(args['params'] as Map);
        if (method == 'registerConversionListener' ||
            method == 'subscribeForDeepLink' ||
            method == 'registerDeeplinkListener' ||
            method == 'registerSessionReadyListener') {
          throw PlatformException(
            code: '500',
            message: 'Listener registration failed',
          );
        }
        return rpcResult;
      }

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        methodChannel,
        failingRegistrationHandler,
      );

      final conversionData = <Map<String, dynamic>>[];
      await expectLater(
        androidSdk.registerConversionListener(onSuccess: conversionData.add),
        throwsA(
          isA<AppsFlyerException>().having(
            (error) => error.message,
            'message',
            'Listener registration failed',
          ),
        ),
      );
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();
      expect(conversionData, isEmpty);

      var deepLinkCount = 0;
      await expectLater(
        androidSdk.registerDeepLinkListener((_) => deepLinkCount++),
        throwsA(isA<AppsFlyerException>()),
      );
      await _emitEvent({
        'event': 'onDeepLinking',
        'data': {'status': 'FOUND'},
      });
      await pumpEventQueue();
      expect(deepLinkCount, 0);

      var sessionReadyCount = 0;
      await expectLater(
        androidSdk.registerSessionReadyListener(() => sessionReadyCount++),
        throwsA(isA<AppsFlyerException>()),
      );
      await _emitEvent({
        'event': 'onSessionReady',
        'data': null,
      });
      await pumpEventQueue();
      expect(sessionReadyCount, 0);
    });

    test('continues delivering events when a listener callback throws', () async {
      final received = <Map<String, dynamic>>[];
      var callCount = 0;
      await androidSdk.registerConversionListener(
        onSuccess: (data) {
          callCount++;
          if (callCount == 1) {
            throw StateError('listener failed');
          }
          received.add(data);
        },
      );

      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'id': 1},
      });
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'id': 2},
      });
      await pumpEventQueue();

      expect(callCount, 2);
      expect(received.single, {'id': 2});
    });

    test('continues replaying held events when a listener callback throws',
        () async {
      await androidSdk.registerDeepLinkListener((_) {});
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'id': 1},
      });
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'id': 2},
      });
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      var callCount = 0;
      await androidSdk.registerConversionListener(
        onSuccess: (data) {
          callCount++;
          if (callCount == 1) {
            throw StateError('listener failed');
          }
          received.add(data);
        },
      );
      await pumpEventQueue();

      expect(callCount, 2);
      expect(received.single, {'id': 2});
    });

    test('delivers conversion data to the registered success callback',
        () async {
      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
        'timestamp': 123,
        'origin': 'android',
      });
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
    });

    test(
        'the failure callback passes through the raw native payload '
        '(no synthesized RPC exception)', () async {
      final failures = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(
        onSuccess: (_) {},
        onFailure: failures.add,
      );
      await _emitEvent({
        'event': 'onConversionDataFail',
        'data': {'error': 'Network unavailable'},
        'timestamp': 123,
        'origin': 'android',
      });
      await pumpEventQueue();

      // Android never reports a numeric code — the payload is passed through
      // as-is rather than backfilled with a synthesized default.
      expect(failures.single, {'error': 'Network unavailable'});
    });

    test('a conversion failure without a failure callback is not an error',
        () async {
      await androidSdk.registerConversionListener(onSuccess: (_) {});
      await _emitEvent({
        'event': 'onConversionDataFail',
        'data': {'error': 'Network unavailable'},
      });
      await pumpEventQueue();
    });

    test('ignores transport-only envelope fields on conversion events',
        () async {
      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
        'timestamp': 999,
        'origin': 'android',
      });
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
    });

    test('re-registering replaces the callback instead of adding a second one',
        () async {
      final first = <Map<String, dynamic>>[];
      final second = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: first.add);
      await androidSdk.registerConversionListener(onSuccess: second.add);
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      expect(first, isEmpty);
      expect(second.single, {'media_source': 'organic'});
    });

    test('a session-ready event reaches the callback exactly once', () async {
      var readyCount = 0;
      await androidSdk.registerSessionReadyListener(() => readyCount++);
      await _emitEvent({
        'event': 'onSessionReady',
        'data': <String, dynamic>{},
        'timestamp': 123.9,
        'origin': 'ios',
      });
      await pumpEventQueue();

      expect(readyCount, 1);
    });

    test('re-registering the session-ready listener cannot double-start',
        () async {
      var startCount = 0;
      await androidSdk.registerSessionReadyListener(() => startCount++);
      await androidSdk.registerSessionReadyListener(() => startCount++);
      await _emitEvent({
        'event': 'onSessionReady',
        'data': <String, dynamic>{},
      });
      await pumpEventQueue();

      expect(startCount, 1);
    });

    test('unregistering the session-ready listener drops its callback',
        () async {
      var readyCount = 0;
      await androidSdk.registerSessionReadyListener(() => readyCount++);
      await androidSdk.unregisterSessionReadyListener();
      await _emitEvent({
        'event': 'onSessionReady',
        'data': <String, dynamic>{},
      });
      await pumpEventQueue();

      expect(readyCount, 0);
    });

    test(
        'an event replayed before its listener is registered is delivered '
        'once that listener registers', () async {
      // Both platforms flush their whole native buffer as soon as Dart
      // attaches, which the first register*Listener call triggers. The
      // documented startup order registers the deep-link listener first, so
      // every other buffered event arrives before its callback exists.
      await androidSdk.registerDeepLinkListener((_) {});
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
    });

    test('held events replay in arrival order', () async {
      await androidSdk.registerDeepLinkListener((_) {});
      for (var i = 0; i < 3; i++) {
        await _emitEvent({
          'event': 'onConversionDataSuccess',
          'data': {'index': i},
        });
      }
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);
      await pumpEventQueue();

      expect(received.map((data) => data['index']), [0, 1, 2]);
    });

    test('a held event is replayed before a live event that follows it',
        () async {
      await androidSdk.registerDeepLinkListener((_) {});
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'index': 0},
      });
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      // Not awaited: the live event is emitted while the replay is still
      // pending, so this pins the replay ahead of it.
      unawaited(androidSdk.registerConversionListener(onSuccess: received.add));
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'index': 1},
      });
      await pumpEventQueue();

      expect(received.map((data) => data['index']), [0, 1]);
    });

    test('re-registering before the replay runs does not deliver twice',
        () async {
      await androidSdk.registerDeepLinkListener((_) {});
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      unawaited(androidSdk.registerConversionListener(onSuccess: received.add));
      unawaited(androidSdk.registerConversionListener(onSuccess: received.add));
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
    });

    test('unregistering discards events held for that listener', () async {
      var readyCount = 0;
      await androidSdk.registerSessionReadyListener(() => readyCount++);
      await androidSdk.unregisterSessionReadyListener();
      await _emitEvent({
        'event': 'onSessionReady',
        'data': <String, dynamic>{},
      });
      await pumpEventQueue();

      // Re-registering resumes future events; it does not resurrect events
      // that arrived while the app had explicitly unregistered.
      await androidSdk.registerSessionReadyListener(() => readyCount++);
      await pumpEventQueue();

      expect(readyCount, 0);
    });

    test('holding is bounded and drops the oldest event first', () async {
      await androidSdk.registerDeepLinkListener((_) {});
      for (var i = 0; i < 65; i++) {
        await _emitEvent({
          'event': 'onConversionDataSuccess',
          'data': {'index': i},
        });
      }
      await pumpEventQueue();

      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);
      await pumpEventQueue();

      expect(received.length, 64);
      expect(received.first['index'], 1);
      expect(received.last['index'], 64);
    });

    test('routes deep-link events with an object data payload', () async {
      DeepLinkResult? result;
      await iosSdk.registerDeepLinkListener((value) => result = value);
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {
          'status': 'found',
          'deepLink': {'deep_link_value': 'home'},
        },
      });
      await pumpEventQueue();

      expect(result!.status, DeepLinkStatus.found);
      expect(result!.deepLink!.deepLinkValue, 'home');
    });

    test('drops malformed native events instead of surfacing an error',
        () async {
      final received = <Map<String, dynamic>>[];
      await androidSdk.registerConversionListener(onSuccess: received.add);

      await _emitRaw('not-json-at-all');
      await _emitRaw(jsonEncode(<dynamic>['not', 'an', 'object']));
      await _emitEvent({
        'event': null,
        'data': {'media_source': 'organic'},
      });
      await _emitEvent({
        'event': '',
        'data': {'media_source': 'organic'},
      });
      await _emitEvent({
        'event': 123,
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      expect(received, isEmpty);

      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
    });

    test('maps every deep-link status to DeepLinkStatus', () async {
      final cases = <String, DeepLinkStatus>{
        'found': DeepLinkStatus.found,
        'FOUND': DeepLinkStatus.found,
        'not_found': DeepLinkStatus.notFound,
        'NOT_FOUND': DeepLinkStatus.notFound,
        'error': DeepLinkStatus.error,
        'failure': DeepLinkStatus.error,
        'unexpected': DeepLinkStatus.unknown,
      };

      DeepLinkResult? result;
      await androidSdk.registerDeepLinkListener((value) => result = value);

      for (final entry in cases.entries) {
        await _emitEvent({
          'event': 'onDeepLinking',
          'data': {'status': entry.key},
        });
        await pumpEventQueue();
        expect(result!.status, entry.value);
      }
    });

    // Both SDK instances share the 'af-events' channel name, so the most
    // recently subscribed instance owns the test messenger's handler. Register
    // and assert one platform at a time.
    test('deep-link errors use platform-specific failure fields', () async {
      DeepLinkResult? android;
      await androidSdk.registerDeepLinkListener((value) => android = value);
      await _emitEvent({
        'event': 'onDeepLinking',
        'data': {'status': 'error', 'error': 'NETWORK'},
      });
      await pumpEventQueue();
      expect(android!.status, DeepLinkStatus.error);
      expect(android!.error!.type, 'NETWORK');
      expect(android!.error!.message, isNull);

      DeepLinkResult? ios;
      await iosSdk.registerDeepLinkListener((value) => ios = value);
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {'status': 'error', 'error': 'Timed out'},
      });
      await pumpEventQueue();
      expect(ios!.status, DeepLinkStatus.error);
      expect(ios!.error!.message, 'Timed out');
      expect(ios!.error!.type, isNull);
    });

    test('normalizes Android and iOS deep-link status without hiding errors',
        () async {
      DeepLinkResult? androidResult;
      await androidSdk.registerDeepLinkListener(
        (value) => androidResult = value,
      );
      await _emitEvent({
        'event': 'onDeepLinking',
        'data': {
          'status': 'FOUND',
          'deepLink': '{"deep_link_value":"home","is_deferred":false}',
        },
      });
      await pumpEventQueue();
      final android = androidResult!;

      DeepLinkResult? iosResult;
      await iosSdk.registerDeepLinkListener((value) => iosResult = value);
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {'status': 'failure', 'error': 'Network unavailable'},
      });
      await pumpEventQueue();
      final ios = iosResult!;

      expect(android.status, DeepLinkStatus.found);
      expect(android.deepLink!.deepLinkValue, 'home');
      expect(android.deepLink!.isDeferred, isFalse);
      expect(ios.status, DeepLinkStatus.error);
      expect(ios.error!.message, 'Network unavailable');
      expect(ios.error!.type, isNull);
    });
  });
}

const _sharedMediationNetworkRpcValues = {
  AFMediationNetwork.ironSource: 'ironsource',
  AFMediationNetwork.applovinMax: 'applovin_max',
  AFMediationNetwork.googleAdMob: 'google_admob',
  AFMediationNetwork.fyber: 'fyber',
  AFMediationNetwork.appodeal: 'appodeal',
  AFMediationNetwork.admost: 'admost',
  AFMediationNetwork.topon: 'topon',
  AFMediationNetwork.tradplus: 'tradplus',
  AFMediationNetwork.yandex: 'yandex',
  AFMediationNetwork.chartboost: 'chartboost',
  AFMediationNetwork.unity: 'unity',
  AFMediationNetwork.toponPte: 'topon_pte',
};

Future<void> _expectLogAdRevenueMediationNetworks(
  AppsFlyerSdk sdk,
  Map<AFMediationNetwork, String> expectedNetworks,
  Map<String, dynamic>? Function() readRpcParams,
) async {
  for (final entry in expectedNetworks.entries) {
    final additionalParameters = entry.key == AFMediationNetwork.customMediation
        ? {'placement': 'banner'}
        : null;
    await sdk.logAdRevenue(
      monetizationNetwork: 'network',
      mediationNetwork: entry.key,
      currencyIso4217Code: 'USD',
      revenue: 1.0,
      additionalParameters: additionalParameters,
    );
    expect(
      readRpcParams(),
      {
        'monetizationNetwork': 'network',
        'mediationNetwork': entry.value,
        'currencyIso4217Code': 'USD',
        'revenue': 1.0,
        'additionalParameters': additionalParameters,
      },
    );
  }
}

Future<void> _emitEvent(Map<String, dynamic> event) =>
    _emitRaw(jsonEncode(event));

Future<void> _emitRaw(String payload) async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final ByteData data =
      const StandardMethodCodec().encodeSuccessEnvelope(payload);
  await messenger.handlePlatformMessage('af-events', data, (_) {});
}
