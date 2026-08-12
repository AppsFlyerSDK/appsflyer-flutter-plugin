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
  late AppsFlyerSdk androidSdk;
  late AppsFlyerSdk iosSdk;

  setUp(() {
    rpcMethod = null;
    rpcParams = null;
    rpcResult = null;

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      expect(call.method, 'executeRpc');
      final args = Map<String, dynamic>.from(call.arguments as Map);
      rpcMethod = args['method'] as String;
      rpcParams = Map<String, dynamic>.from(args['params'] as Map);
      return rpcResult;
    });
    messenger.setMockMethodCallHandler(eventMethodChannel, (_) async => null);

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
      await androidSdk.registerConversionListener();
      expect(rpcMethod, 'registerConversionListener');

      await androidSdk.registerDeepLinkListener();
      expect(rpcMethod, 'subscribeForDeepLink');

      await iosSdk.registerDeepLinkListener();
      expect(rpcMethod, 'registerDeeplinkListener');

      await iosSdk.registerSessionReadyListener();
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

    test('platform-only void calls are ignored without reaching the native RPC',
        () async {
      await iosSdk.setCollectAndroidID(true);
      await iosSdk.setLogLevel(AFLogLevel.debug);
      await iosSdk.unregisterDeeplinkListener();
      await iosSdk.unregisterConversionListener();
      await iosSdk.logSession();
      await iosSdk.setOutOfStore('source');
      await iosSdk.setIsUpdate(true);
      await iosSdk.setPreinstallAttribution('media-source');
      await iosSdk.setAppId('123');
      await iosSdk.setDisableNetworkData(true);
      await iosSdk.disableAppSetId();
      await iosSdk.sendPushNotificationData(
        campaign: 'campaign',
        pid: 'media-source',
      );

      await androidSdk.setDisableSKAdNetwork(true);
      await androidSdk.setDisableCollectASA(true);
      await androidSdk.setDisableAppleAdsAttribution(true);
      await androidSdk.setDisableIDFVCollection(true);
      await androidSdk.setShouldCollectDeviceName(true);
      await androidSdk.setCurrentDeviceLanguage('en');
      await androidSdk.setFacebookDeferredAppLink('https://example.com');
      await androidSdk.handlePushNotification({'aps': {}});

      expect(rpcMethod, isNull);
    });

    test('platform-only value calls return a safe default off-platform',
        () async {
      expect(await iosSdk.isStopped(), isFalse);

      expect(rpcMethod, isNull);
    });

    test(
        'symmetric platform-only getters surface RPC method-not-found off-platform',
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

    test(
        'symmetric platform-only setters surface RPC errors off-platform',
        () async {
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

    test('Android cannot clear the sharing filter through RPC 7.0.1', () async {
      await androidSdk.setSharingFilterForPartners(null);
      expect(rpcMethod, isNull);

      await androidSdk.setSharingFilterForPartners([]);
      expect(rpcMethod, isNull);
    });
  });

  group('models and platform payloads', () {
    test('consent validates GDPR-required fields in release behavior', () {
      expect(
        () => androidSdk.setConsentData(isUserSubjectToGDPR: true),
        throwsArgumentError,
      );
      expect(
        () => androidSdk.setConsentData(
          isUserSubjectToGDPR: true,
          hasConsentForDataUsage: true,
        ),
        throwsArgumentError,
      );
      expect(rpcMethod, isNull);
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

    test('generateInviteLink throws AppsFlyerException when native returns null',
        () async {
      rpcResult = null;

      expect(
        () => androidSdk.generateInviteLink(),
        throwsA(
          isA<AppsFlyerException>().having(
            (error) => error.message,
            'message',
            'generateInviteLink returned no result',
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
            'getSdkVersion returned no result',
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
    test('filters conversion events from the raw RPC stream', () async {
      final result = androidSdk.onConversionDataSuccess.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
        'timestamp': 123,
        'origin': 'android',
      });

      expect(await result, {'media_source': 'organic'});
    });

    test(
        'onConversionDataFailure passes through the raw native payload '
        '(no synthesized RPC exception)', () async {
      final result = androidSdk.onConversionDataFailure.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onConversionDataFail',
        'data': {'error': 'Network unavailable'},
        'timestamp': 123,
        'origin': 'android',
      });

      // Android never reports a numeric code — the payload is passed through
      // as-is rather than backfilled with a synthesized default.
      expect(await result, {'error': 'Network unavailable'});
    });

    test('ignores transport-only envelope fields on conversion stream',
        () async {
      final result = androidSdk.onConversionDataSuccess.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
        'timestamp': 999,
        'origin': 'android',
      });

      expect(await result, {'media_source': 'organic'});
    });

    test('routes onSessionReady without a payload', () async {
      var readyCount = 0;
      final subscription = androidSdk.onSessionReady.listen((_) {
        readyCount++;
      });
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onSessionReady',
        'data': <String, dynamic>{},
        'timestamp': 123.9,
        'origin': 'ios',
      });
      await pumpEventQueue();

      expect(readyCount, 1);
      await subscription.cancel();
    });

    test('routes deep-link events with an object data payload', () async {
      final result = iosSdk.onDeepLinkReceived.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {
          'status': 'found',
          'deepLink': {'deep_link_value': 'home'},
        },
      });

      final deepLinkResult = await result;
      expect(deepLinkResult.status, DeepLinkStatus.found);
      expect(deepLinkResult.deepLink!.deepLinkValue, 'home');
    });

    test('drops malformed native events instead of surfacing an error',
        () async {
      final received = <Map<String, dynamic>>[];
      final errors = <Object>[];
      final subscription = androidSdk.onConversionDataSuccess.listen(
        received.add,
        onError: errors.add,
      );
      await pumpEventQueue();

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
      expect(errors, isEmpty);

      await _emitEvent({
        'event': 'onConversionDataSuccess',
        'data': {'media_source': 'organic'},
      });
      await pumpEventQueue();

      expect(received.single, {'media_source': 'organic'});
      expect(errors, isEmpty);

      await subscription.cancel();
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

      for (final entry in cases.entries) {
        final result = androidSdk.onDeepLinkReceived.first;
        await pumpEventQueue();
        await _emitEvent({
          'event': 'onDeepLinking',
          'data': {'status': entry.key},
        });
        expect((await result).status, entry.value);
      }
    });

    test('deep-link errors use platform-specific failure fields', () async {
      final androidResult = androidSdk.onDeepLinkReceived.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onDeepLinking',
        'data': {'status': 'error', 'error': 'NETWORK'},
      });
      final android = await androidResult;
      expect(android.status, DeepLinkStatus.error);
      expect(android.error!.type, 'NETWORK');
      expect(android.error!.message, isNull);

      final iosResult = iosSdk.onDeepLinkReceived.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {'status': 'error', 'error': 'Timed out'},
      });
      final ios = await iosResult;
      expect(ios.status, DeepLinkStatus.error);
      expect(ios.error!.message, 'Timed out');
      expect(ios.error!.type, isNull);
    });

    test('normalizes Android and iOS deep-link status without hiding errors',
        () async {
      final androidResult = androidSdk.onDeepLinkReceived.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onDeepLinking',
        'data': {
          'status': 'FOUND',
          'deepLink': '{"deep_link_value":"home","is_deferred":false}',
        },
      });
      final android = await androidResult;

      final iosResult = iosSdk.onDeepLinkReceived.first;
      await pumpEventQueue();
      await _emitEvent({
        'event': 'onDeepLinkReceived',
        'data': {'status': 'failure', 'error': 'Network unavailable'},
      });
      final ios = await iosResult;

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
