import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppsflyerSdk instance;
  String selectedMethod = "";
  dynamic capturedArguments;
  const MethodChannel methodChannel = MethodChannel('af-api');
  const MethodChannel callbacksChannel = MethodChannel('callbacks');
  const EventChannel eventChannel = EventChannel('af-events');
  const MethodChannel eventMethodChannel = MethodChannel('af-events');

  setUp(() {
    //test map options way
    instance = AppsflyerSdk.private(methodChannel, eventChannel,
        mapOptions: {'afDevKey': 'sdfhj2342cx'});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (methodCall) async {
      String method = methodCall.method;
      switch (method) {
        case 'initSdk':
        case 'setOneLinkCustomDomain':
        case 'logCrossPromotionAndOpenStore':
        case 'logCrossPromotionImpression':
        case 'setAppInviteOneLinkID':
        case 'generateInviteLink':
        case 'setSharingFilterForAllPartners':
        case 'setSharingFilter':
        case 'getSDKVersion':
        case 'getAppsFlyerUID':
        case 'validateAndLogInAppAndroidPurchase':
        case 'setMinTimeBetweenSessions':
        case 'getHostPrefix':
        case 'getHostName':
        case 'setCollectIMEI':
        case 'setCollectAndroidId':
        case 'setUserEmails':
        case 'setAdditionalData':
        case 'waitForCustomerUserId':
        case 'setCustomerUserId':
        case 'setAndroidIdData':
        case 'setImeiData':
        case 'updateServerUninstallToken':
        case 'stop':
        case 'setIsUpdate':
        case 'setCurrencyCode':
        case 'setHost':
        case 'logEvent':
        case 'setOutOfStore':
        case 'getOutOfStore':
        case 'logAdRevenue':
        case 'setConsentData':
        case 'enableTCFDataCollection':
        case 'setDisableNetworkData':
        case 'disableAppSetId':
        case 'setPartnerData':
        case 'setResolveDeepLinkURLs':
        case 'setPushNotification':
        case 'sendPushNotificationData':
        case 'enableFacebookDeferredApplinks':
        case 'disableSKAdNetwork':
        case 'setDisableAdvertisingIdentifiers':
          selectedMethod = method;
          capturedArguments = methodCall.arguments;
          break;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, (methodCall) async {
      String method = methodCall.method;
      if (method == 'listen') {
        selectedMethod = method;
        capturedArguments = methodCall.arguments;
      }
      return null;
    });

    // Mock handler for callbacks channel to avoid MissingPluginException during startListening
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(callbacksChannel, (methodCall) async {
      selectedMethod = methodCall.method;
      capturedArguments = methodCall.arguments;
      return null;
    });
  });

  test('check initSdk call', () async {
    await instance.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: false);

    expect('initSdk', selectedMethod);
  });

  group('AppsFlyerSdk', () {
    setUp(() {
      selectedMethod = "";
      capturedArguments = null;
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(callbacksChannel, null);
    });

    test('check logEvent call', () async {
      await instance.logEvent("eventName", {"key": "val"});

      expect(selectedMethod, 'logEvent');
    });

    test('check setHost call', () async {
      instance.setHost("prefix", "hostname");

      expect(selectedMethod, 'setHost');
      expect(capturedArguments['hostPrefix'], 'prefix');
      expect(capturedArguments['hostName'], 'hostname');
    });

    test('check setCurrencyCode call', () async {
      instance.setCurrencyCode("USD");

      expect(selectedMethod, 'setCurrencyCode');
      expect(capturedArguments['currencyCode'], 'USD');
    });

    test('check setIsUpdate call', () async {
      instance.setIsUpdate(true);

      expect(selectedMethod, 'setIsUpdate');
      expect(capturedArguments['isUpdate'], true);
    });

    test('check stop call', () async {
      instance.stop(true);

      expect(selectedMethod, 'stop');
      expect(capturedArguments['isStopped'], true);
    });

    test('check updateServerUninstallToken call', () async {
      instance.updateServerUninstallToken("token123");

      expect(selectedMethod, 'updateServerUninstallToken');
      expect(capturedArguments['token'], 'token123');
    });

    test('check setOneLinkCustomDomain call', () async {
      instance.setOneLinkCustomDomain(["brandDomains"]);

      expect(selectedMethod, 'setOneLinkCustomDomain');
      expect(capturedArguments, isA<List>());
      expect(capturedArguments, contains('brandDomains'));
    });

    test('check logCrossPromotionAndOpenStore call', () async {
      instance.logCrossPromotionAndOpenStore("appId123", "campaignA", null);

      expect(selectedMethod, 'logCrossPromotionAndOpenStore');
      expect(capturedArguments['appId'], 'appId123');
      expect(capturedArguments['campaign'], 'campaignA');
      expect(capturedArguments['params'], null);
    });

    test('check logCrossPromotionImpression call', () async {
      instance.logCrossPromotionImpression("appId", "campaign", null);

      expect(selectedMethod, 'logCrossPromotionImpression');
    });

    test('check setAppInviteOneLinkID call', () async {
      instance.setAppInviteOneLinkID("oneLinkID", (msg) {});

      expect(selectedMethod, 'setAppInviteOneLinkID');
    });

    test('check generateInviteLink call', () async {
      instance.generateInviteLink(null, (msg) {}, (err) {});

      expect(selectedMethod, 'generateInviteLink');
    });

    test('check getSDKVersion call', () async {
      instance.getSDKVersion();

      expect(selectedMethod, 'getSDKVersion');
    });

    test('check getAppsFlyerUID call', () async {
      instance.getAppsFlyerUID();

      expect(selectedMethod, 'getAppsFlyerUID');
    });

    test('check validateAndLogInAppPurchase call', () async {
      instance.validateAndLogInAppAndroidPurchase(
          "publicKey", "signature", "purchaseData", "9.99", "EUR", null);

      expect(selectedMethod, 'validateAndLogInAppAndroidPurchase');
      expect(capturedArguments['publicKey'], 'publicKey');
      expect(capturedArguments['price'], '9.99');
      expect(capturedArguments['currency'], 'EUR');
    });

    test('check setMinTimeBetweenSessions call', () async {
      instance.setMinTimeBetweenSessions(1);

      expect(selectedMethod, 'setMinTimeBetweenSessions');
    });

    test('check getHostPrefix call', () async {
      instance.getHostPrefix();

      expect(selectedMethod, 'getHostPrefix');
    });

    test('check getHostName call', () async {
      instance.getHostName();

      expect(selectedMethod, 'getHostName');
    });

    test('check setCollectIMEI call', () async {
      instance.setCollectIMEI(true);

      expect(selectedMethod, 'setCollectIMEI');
    });

    test('check setCollectAndroidId call', () async {
      instance.setCollectAndroidId(true);

      expect(selectedMethod, 'setCollectAndroidId');
    });

    test('check setUserEmails call', () async {
      instance.setUserEmails(
          ["user@example.com"], EmailCryptType.EmailCryptTypeSHA256);

      expect(selectedMethod, 'setUserEmails');
      expect(capturedArguments['emails'], contains('user@example.com'));
      expect(capturedArguments['cryptType'],
          EmailCryptType.values.indexOf(EmailCryptType.EmailCryptTypeSHA256));
    });

    test('check setAdditionalData call', () async {
      instance.setAdditionalData(null);

      expect(selectedMethod, 'setAdditionalData');
    });

    test('check waitForCustomerUserId call', () async {
      instance.waitForCustomerUserId(false);

      expect(selectedMethod, 'waitForCustomerUserId');
    });

    test('check setCustomerUserId call', () async {
      instance.setCustomerUserId("id");

      expect(selectedMethod, 'setCustomerUserId');
    });

    test('check setImeiData call', () async {
      instance.setImeiData("imei");

      expect(selectedMethod, 'setImeiData');
    });

    test('check setAndroidIdData call', () async {
      instance.setAndroidIdData("androidId");

      expect(selectedMethod, 'setAndroidIdData');
    });

    test('check getOutOfStore call', () async {
      instance.getOutOfStore();

      expect(selectedMethod, 'getOutOfStore');
    });

    test('check setOutOfStore call', () async {
      instance.setOutOfStore("source");

      expect(selectedMethod, 'setOutOfStore');
    });

    test('check logAdRevenue call', () async {
      final adRevenueData = AdRevenueData(
          monetizationNetwork: 'Applovin',
          mediationNetwork: AFMediationNetwork.applovinMax.value,
          currencyIso4217Code: 'USD',
          revenue: 0.99);
      instance.logAdRevenue(adRevenueData);

      expect(selectedMethod, 'logAdRevenue');
      expect(capturedArguments['mediationNetwork'], 'applovin_max');
    });

    test('check enableTCFDataCollection call', () async {
      instance.enableTCFDataCollection(true);

      expect(selectedMethod, 'enableTCFDataCollection');
    });

    test('check setDisableNetworkData call', () async {
      instance.setDisableNetworkData(true);

      expect(selectedMethod, 'setDisableNetworkData');
    });

    test('check setPartnerData call', () async {
      instance.setPartnerData('partnerId', {'key': 'value'});

      expect(selectedMethod, 'setPartnerData');
      expect(capturedArguments['partnerId'], 'partnerId');
      expect(capturedArguments['partnersData']['key'], 'value');
    });

    test('check setResolveDeepLinkURLs call', () async {
      instance.setResolveDeepLinkURLs(['https://example.com']);

      expect(selectedMethod, 'setResolveDeepLinkURLs');
      expect(capturedArguments, contains('https://example.com'));
    });

    test('check sendPushNotificationData call', () async {
      instance.sendPushNotificationData({'key': 'value'});

      expect(selectedMethod, 'sendPushNotificationData');
      expect(capturedArguments['key'], 'value');
    });

    test('check enableFacebookDeferredApplinks call', () async {
      instance.enableFacebookDeferredApplinks(true);

      expect(selectedMethod, 'enableFacebookDeferredApplinks');
      expect(capturedArguments['isFacebookDeferredApplinksEnabled'], true);
    });

    test('check disableSKAdNetwork call', () async {
      instance.disableSKAdNetwork(true);

      expect(selectedMethod, 'disableSKAdNetwork');
    });

    test('check setDisableAdvertisingIdentifiers call', () async {
      instance.setDisableAdvertisingIdentifiers(true);

      expect(selectedMethod, 'setDisableAdvertisingIdentifiers');
      expect(capturedArguments, true);
    });

    test('check disableAppSetId call', () async {
      instance.disableAppSetId();

      expect(selectedMethod, 'disableAppSetId');
    });
  });
}
