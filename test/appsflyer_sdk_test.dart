import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// SDK 7 migration: the plugin now speaks a single `executeRpc` verb to native on both platforms,
/// carrying `{method, params}`. These tests assert the RPC method name and params the Dart layer
/// emits, rather than the legacy per-method channel calls.
///
/// Note: `flutter test` runs on the host (neither `Platform.isAndroid` nor `Platform.isIOS`), so
/// platform-gated setters (e.g. Android-only `setCollectAndroidId`, iOS-only `disableSKAdNetwork`)
/// are no-ops here and are asserted as such; unconditional methods always dispatch `executeRpc`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppsflyerSdk instance;

  // Last executeRpc call captured from the af-api channel.
  String? rpcMethod;
  Map? rpcParams;
  bool executeRpcCalled = false;

  const MethodChannel methodChannel = MethodChannel('af-api');
  const MethodChannel eventMethodChannel = MethodChannel('af-events');

  void resetCapture() {
    rpcMethod = null;
    rpcParams = null;
    executeRpcCalled = false;
  }

  setUp(() {
    resetCapture();
    instance = AppsflyerSdk.private(methodChannel,
        mapOptions: {'afDevKey': 'sdfhj2342cx'});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      if (methodCall.method != 'executeRpc') {
        return null;
      }
      executeRpcCalled = true;
      final args = methodCall.arguments as Map;
      rpcMethod = args['method'] as String?;
      rpcParams = args['params'] as Map?;

      // Return values for getter-style RPCs so the Dart await path is exercised.
      switch (rpcMethod) {
        case 'getSdkVersion':
          return '7.0.1';
        case 'getAppsFlyerUID':
          return 'af-uid-123';
        case 'isSessionReady':
          return true;
        case 'validateAndLogInAppPurchase':
          return {'status': 'success'};
      }
      return null;
    });

    // The unified event path subscribes to the af-events EventChannel on both platforms.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            eventMethodChannel, (methodCall) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, null);
  });

  test('initSdk dispatches the init RPC', () async {
    await instance.initSdk(
        registerConversionDataCallback: true,
        registerOnDeepLinkingCallback: false);

    expect(rpcMethod, 'init');
    expect(rpcParams?['afDevKey'], 'sdfhj2342cx');
    expect(rpcParams?[AppsflyerConstants.AF_GCD], true);
    expect(rpcParams?[AppsflyerConstants.AF_UDL], false);
  });

  test('startSDK dispatches the start RPC (fire and forget)', () async {
    instance.startSDK();
    expect(rpcMethod, 'start');
    expect(rpcParams?['awaitResponse'], false);
  });

  test(
      'startSDK forwards awaitResponse and invokes onSuccess when a callback is passed',
      () async {
    var ok = false;
    instance.startSDK(onSuccess: () => ok = true);
    expect(rpcMethod, 'start');
    expect(rpcParams?['awaitResponse'], true);
    await pumpEventQueue();
    expect(ok, true);
  });

  group('cross-platform methods dispatch executeRpc', () {
    test('logEvent (fire and forget)', () {
      instance.logEvent('eventName', {'key': 'val'});
      expect(rpcMethod, 'logEvent');
      expect(rpcParams?['eventName'], 'eventName');
      expect(rpcParams?['eventValues'], {'key': 'val'});
      expect(rpcParams?['awaitResponse'], false);
    });

    test('logEvent forwards awaitResponse and invokes onSuccess on a 200 OK',
        () async {
      var ok = false;
      instance.logEvent('e', null, onSuccess: () => ok = true);
      expect(rpcMethod, 'logEvent');
      expect(rpcParams?['awaitResponse'], true);
      await pumpEventQueue();
      expect(ok, true);
    });

    test('logEvent invokes onError with the SDK code/message on failure',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (methodCall) async {
        throw PlatformException(code: '42', message: 'event before start');
      });
      int? code;
      String? message;
      instance.logEvent('e', null, onError: (c, m) {
        code = c;
        message = m;
      });
      await pumpEventQueue();
      expect(code, 42);
      expect(message, 'event before start');
    });

    test('logLocation maps to latitude + longitude', () {
      instance.logLocation(32.0853, 34.7818);
      expect(rpcMethod, 'logLocation');
      expect(rpcParams?['latitude'], 32.0853);
      expect(rpcParams?['longitude'], 34.7818);
    });

    group('AdRevenueData.mediationNetworkForPlatform (CR-055)', () {
      test('remaps the two divergent values for iOS', () {
        expect(
            AdRevenueData.mediationNetworkForPlatform(
                AFMediationNetwork.customMediation.value,
                isIOS: true),
            'custom');
        expect(
            AdRevenueData.mediationNetworkForPlatform(
                AFMediationNetwork.directMonetizationNetwork.value,
                isIOS: true),
            'directmonetization');
      });

      test('passes the divergent values through unchanged off iOS (Android)',
          () {
        expect(
            AdRevenueData.mediationNetworkForPlatform(
                AFMediationNetwork.customMediation.value,
                isIOS: false),
            'custom_mediation');
        expect(
            AdRevenueData.mediationNetworkForPlatform(
                AFMediationNetwork.directMonetizationNetwork.value,
                isIOS: false),
            'direct_monetization_network');
      });

      test('leaves other networks unchanged on both platforms', () {
        for (final iOS in [true, false]) {
          expect(
              AdRevenueData.mediationNetworkForPlatform(
                  AFMediationNetwork.googleAdMob.value,
                  isIOS: iOS),
              'google_admob');
          expect(
              AdRevenueData.mediationNetworkForPlatform(
                  AFMediationNetwork.ironSource.value,
                  isIOS: iOS),
              'ironsource');
        }
      });
    });

    test('setHost uses SDK 7 param names', () {
      instance.setHost('prefix', 'hostname');
      expect(rpcMethod, 'setHost');
      expect(rpcParams?['hostPrefixName'], 'prefix');
      expect(rpcParams?['hostName'], 'hostname');
    });

    test('setHost is a no-op when the prefix or host is empty', () {
      instance.setHost('', 'hostname');
      expect(executeRpcCalled, false);
      instance.setHost('prefix', '');
      expect(executeRpcCalled, false);
    });

    test('setCurrencyCode', () {
      instance.setCurrencyCode('USD');
      expect(rpcMethod, 'setCurrencyCode');
      expect(rpcParams?['currencyCode'], 'USD');
    });

    test('stop maps to shouldStop', () {
      instance.stop(true);
      expect(rpcMethod, 'stop');
      expect(rpcParams?['shouldStop'], true);
    });

    test('setCustomerUserId maps to customerId', () {
      instance.setCustomerUserId('id');
      expect(rpcMethod, 'setCustomerUserId');
      expect(rpcParams?['customerId'], 'id');
    });

    test('setMinTimeBetweenSessions', () {
      instance.setMinTimeBetweenSessions(5);
      expect(rpcMethod, 'setMinTimeBetweenSessions');
      expect(rpcParams?['seconds'], 5);
    });

    test('setAdditionalData', () {
      instance.setAdditionalData({'k': 'v'});
      expect(rpcMethod, 'setAdditionalData');
      expect(rpcParams?['customData'], {'k': 'v'});
    });

    test('setSharingFilterForPartners', () {
      instance.setSharingFilterForPartners(['facebook_int']);
      expect(rpcMethod, 'setSharingFilterForPartners');
      expect(rpcParams?['partners'], contains('facebook_int'));
    });

    test('setPartnerData uses SDK 7 data key', () {
      instance.setPartnerData('partnerId', {'key': 'value'});
      expect(rpcMethod, 'setPartnerData');
      expect(rpcParams?['partnerId'], 'partnerId');
      expect((rpcParams?['data'] as Map)['key'], 'value');
    });

    test('setResolveDeepLinkURLs maps to urls', () {
      instance.setResolveDeepLinkURLs(['https://example.com']);
      expect(rpcMethod, 'setResolveDeepLinkURLs');
      expect(rpcParams?['urls'], contains('https://example.com'));
    });

    test('setOneLinkCustomDomain maps to domains', () {
      instance.setOneLinkCustomDomain(['brand.onelink.me']);
      expect(rpcMethod, 'setOneLinkCustomDomain');
      expect(rpcParams?['domains'], contains('brand.onelink.me'));
    });

    test('setDeepLinkTimeout maps to timeout', () {
      instance.setDeepLinkTimeout(3000);
      expect(rpcMethod, 'setDeepLinkTimeout');
      expect(rpcParams?['timeout'], 3000);
    });

    test('addPushNotificationDeepLinkPath maps to deepLinkPath', () {
      instance.addPushNotificationDeepLinkPath(['af_dp']);
      expect(rpcMethod, 'addPushNotificationDeepLinkPath');
      expect(rpcParams?['deepLinkPath'], contains('af_dp'));
    });

    test('appendParametersToDeepLinkingURL maps to contains + parameters', () {
      instance
          .appendParametersToDeepLinkingURL('https://example.com', {'k': 'v'});
      expect(rpcMethod, 'appendParametersToDeepLinkingURL');
      expect(rpcParams?['contains'], 'https://example.com');
      expect((rpcParams?['parameters'] as Map)['k'], 'v');
    });

    test('enableTCFDataCollection', () {
      instance.enableTCFDataCollection(true);
      expect(rpcMethod, 'enableTCFDataCollection');
      expect(rpcParams?['shouldCollect'], true);
    });

    test('enableFacebookDeferredApplinks maps to isEnabled', () {
      instance.enableFacebookDeferredApplinks(true);
      expect(rpcMethod, 'enableFacebookDeferredApplinks');
      expect(rpcParams?['isEnabled'], true);
    });

    test('anonymizeUser', () {
      instance.anonymizeUser(true);
      expect(rpcMethod, 'anonymizeUser');
      expect(rpcParams?['shouldAnonymize'], true);
    });

    test('setConsentDataV2 maps to setConsentData', () {
      instance.setConsentDataV2(
          isUserSubjectToGDPR: true,
          consentForDataUsage: true,
          consentForAdsPersonalization: false);
      expect(rpcMethod, 'setConsentData');
      expect(rpcParams?['isUserSubjectToGDPR'], true);
      expect(rpcParams?['hasConsentForDataUsage'], true);
      expect(rpcParams?['hasConsentForAdsPersonalization'], false);
    });

    test('setConsentDataV2 (non-GDPR) dispatches without consent flags', () {
      instance.setConsentDataV2(isUserSubjectToGDPR: false);
      expect(rpcMethod, 'setConsentData');
      expect(rpcParams?['isUserSubjectToGDPR'], false);
    });

    test('setConsentDataV2 throws when GDPR is true but consents are missing',
        () {
      expect(() => instance.setConsentDataV2(isUserSubjectToGDPR: true),
          throwsArgumentError);
      expect(executeRpcCalled, false);
    });

    test('setAppInviteOneLinkID maps to setAppInviteOneLink', () async {
      await instance.setAppInviteOneLinkID('oneLinkID', (msg) {});
      expect(rpcMethod, 'setAppInviteOneLink');
      expect(rpcParams?['oneLinkId'], 'oneLinkID');
    });

    test('setAppInviteOneLinkID dispatches without a callback', () async {
      await instance.setAppInviteOneLinkID('oneLinkID');
      expect(rpcMethod, 'setAppInviteOneLink');
      expect(rpcParams?['oneLinkId'], 'oneLinkID');
    });

    test('generateInviteLink', () {
      instance.generateInviteLink(null, (msg) {}, (err) {});
      expect(rpcMethod, 'generateInviteLink');
    });

    test('logCrossPromotionImpression maps to logCrossPromoteImpression', () {
      instance.logCrossPromotionImpression('appId', 'campaign', null);
      expect(rpcMethod, 'logCrossPromoteImpression');
      expect(rpcParams?['appId'], 'appId');
      expect(rpcParams?['campaign'], 'campaign');
    });

    test('logCrossPromotionAndOpenStore maps to logAndOpenStore', () {
      instance.logCrossPromotionAndOpenStore('appId', 'campaign', null);
      expect(rpcMethod, 'logAndOpenStore');
      expect(rpcParams?['promotedAppId'], 'appId');
      expect(rpcParams?['campaign'], 'campaign');
    });

    test('setDisableAdvertisingIdentifiers (host uses Android param isDisable)',
        () {
      instance.setDisableAdvertisingIdentifiers(true);
      expect(rpcMethod, 'setDisableAdvertisingIdentifiers');
      expect(rpcParams?['isDisable'], true);
    });

    test('logAdRevenue forwards the flat ad-revenue map', () {
      final adRevenueData = AdRevenueData(
          monetizationNetwork: 'Applovin',
          mediationNetwork: AFMediationNetwork.applovinMax.value,
          currencyIso4217Code: 'USD',
          revenue: 0.99);
      instance.logAdRevenue(adRevenueData);
      expect(rpcMethod, 'logAdRevenue');
      expect(rpcParams?['mediationNetwork'], 'applovin_max');
      expect(rpcParams?['currencyIso4217Code'], 'USD');
    });

    test('setUserEmail (hashed PII) dispatches on both platforms', () {
      instance.setUserEmail('user@example.com');
      expect(rpcMethod, 'setUserEmail');
      expect(rpcParams?['email'], 'user@example.com');
    });

    test('clearUserPii', () {
      instance.clearUserPii();
      expect(rpcMethod, 'clearUserPii');
    });

    test(
        'setUserFbLoginId parses to a numeric id (dispatched on both platforms)',
        () {
      instance.setUserFbLoginId('1234567890123456');
      expect(rpcMethod, 'setUserFbLoginId');
      expect(rpcParams?['fbLoginId'], 1234567890123456);
    });

    test('setUserFbLoginId drops a non-numeric id (no RPC)', () {
      instance.setUserFbLoginId('not-a-number');
      expect(executeRpcCalled, false);
    });

    test('setInstallId dispatches on both platforms', () {
      instance.setInstallId('install-123');
      expect(rpcMethod, 'setInstallId');
      expect(rpcParams?['installId'], 'install-123');
    });
  });

  group('getter RPCs return unwrapped values', () {
    test('getSDKVersion', () async {
      final v = await instance.getSDKVersion();
      expect(rpcMethod, 'getSdkVersion');
      expect(v, '7.0.1');
    });

    test('getAppsFlyerUID', () async {
      final uid = await instance.getAppsFlyerUID();
      expect(rpcMethod, 'getAppsFlyerUID');
      expect(uid, 'af-uid-123');
    });

    test('isSessionReady', () async {
      final ready = await instance.isSessionReady();
      expect(rpcMethod, 'isSessionReady');
      expect(ready, true);
    });

    test('validateAndLogInAppPurchaseV2 returns the result map', () async {
      final details = AFPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        purchaseToken: 'token',
        productId: 'com.app.product',
      );
      final result = await instance.validateAndLogInAppPurchaseV2(details);
      expect(rpcMethod, 'validateAndLogInAppPurchase');
      expect(result['status'], 'success');
    });

    test('logInvite dispatches with channel + eventParameters', () {
      instance.logInvite('facebook', {'foo': 'bar'});
      expect(rpcMethod, 'logInvite');
      expect(rpcParams?['channel'], 'facebook');
      expect((rpcParams?['eventParameters'] as Map?)?['foo'], 'bar');
    });
  });

  group('platform-gated methods are no-ops on the test host', () {
    // On the host, neither Platform.isAndroid nor Platform.isIOS is true, so these must not
    // dispatch any executeRpc call (and must not throw).
    test('setCollectAndroidId (Android-only) is a no-op', () {
      instance.setCollectAndroidId(true);
      expect(executeRpcCalled, false);
    });

    test('disableSKAdNetwork (iOS-only) is a no-op', () {
      instance.disableSKAdNetwork(true);
      expect(executeRpcCalled, false);
    });

    test('disableAppleAdsAttribution (iOS-only) is a no-op', () {
      instance.disableAppleAdsAttribution(true);
      expect(executeRpcCalled, false);
    });

    test('disableAppSetId (Android-only) is a no-op', () {
      instance.disableAppSetId();
      expect(executeRpcCalled, false);
    });

    test('setFacebookDeferredAppLink (iOS-only) is a no-op', () {
      instance.setFacebookDeferredAppLink('https://fb.link');
      expect(executeRpcCalled, false);
    });

    test('getAttributionId (Android-only) returns null without dispatching',
        () async {
      final id = await instance.getAttributionId();
      expect(executeRpcCalled, false);
      expect(id, isNull);
    });

    test('logSession (Android-only) is a no-op', () {
      instance.logSession();
      expect(executeRpcCalled, false);
    });

    test('setPreinstallAttribution (Android-only) is a no-op', () {
      instance.setPreinstallAttribution('media_source', 'campaign', 'site_id');
      expect(executeRpcCalled, false);
    });

    test('setAppId (Android-only) is a no-op', () {
      instance.setAppId('com.example.app');
      expect(executeRpcCalled, false);
    });

    test('disableIDFVCollection (iOS-only) is a no-op', () {
      instance.disableIDFVCollection(true);
      expect(executeRpcCalled, false);
    });

    test('setShouldCollectDeviceName (iOS-only) is a no-op', () {
      instance.setShouldCollectDeviceName(true);
      expect(executeRpcCalled, false);
    });

    test('useUninstallSandbox (iOS-only) is a no-op', () {
      instance.useUninstallSandbox(true);
      expect(executeRpcCalled, false);
    });

    test('isStopped (Android-only) returns null without dispatching', () async {
      final stopped = await instance.isStopped();
      expect(executeRpcCalled, false);
      expect(stopped, isNull);
    });

    test('isPreInstalledApp (Android-only) returns null without dispatching',
        () async {
      final pre = await instance.isPreInstalledApp();
      expect(executeRpcCalled, false);
      expect(pre, isNull);
    });
  });

  group('observer-only listeners do not dispatch RPC', () {
    // register/unregister for session-ready and conversion data are Dart-side observers only:
    // the native SDK listeners are registered during initSdk, so these must never dispatch RPC.
    test('unregisterConversionDataListener is observer-only (no RPC)', () {
      instance.onInstallConversionData((_) {});
      instance.unregisterConversionDataListener();
      expect(executeRpcCalled, false);
    });

    test('unregisterSessionReadyListener is observer-only (no RPC)', () {
      instance.registerSessionReadyListener((_) {});
      instance.unregisterSessionReadyListener();
      expect(executeRpcCalled, false);
    });
  });
}
