import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppsflyerSdk instance;
  String selectedMethod = "";
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
        case 'setPartnerData':
        case 'setResolveDeepLinkURLs':
        case 'setPushNotification':
        case 'sendPushNotificationData':
        case 'enableFacebookDeferredApplinks':
        case 'disableSKAdNetwork':
        case 'setDisableAdvertisingIdentifiers':
          selectedMethod = method;
          break;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, (methodCall) async {
      String method = methodCall.method;
      if (method == 'listen') {
        selectedMethod = method;
      }
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
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('check logEvent call', () async {
      await instance.logEvent("eventName", {"key": "val"});

      expect(selectedMethod, 'logEvent');
    });

    test('check setHost call', () async {
      instance.setHost("", "");

      expect(selectedMethod, 'setHost');
    });

    test('check setCurrencyCode call', () async {
      instance.setCurrencyCode("currencyCode");

      expect(selectedMethod, 'setCurrencyCode');
    });

    test('check setIsUpdate call', () async {
      instance.setIsUpdate(true);

      expect(selectedMethod, 'setIsUpdate');
    });

    test('check stop call', () async {
      instance.stop(true);

      expect(selectedMethod, 'stop');
    });

    test('check updateServerUninstallToken call', () async {
      instance.updateServerUninstallToken("token");

      expect(selectedMethod, 'updateServerUninstallToken');
    });

    test('check setOneLinkCustomDomain call', () async {
      instance.setOneLinkCustomDomain(["brandDomains"]);

      expect(selectedMethod, 'setOneLinkCustomDomain');
    });

    test('check logCrossPromotionAndOpenStore call', () async {
      instance.logCrossPromotionAndOpenStore("appId", "campaign", null);

      expect(selectedMethod, 'logCrossPromotionAndOpenStore');
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
          "publicKey", "signature", "purchaseData", "price", "currency", null);

      expect(selectedMethod, 'validateAndLogInAppAndroidPurchase');
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
      instance.setUserEmails(["emails"], EmailCryptType.EmailCryptTypeNone);

      expect(selectedMethod, 'setUserEmails');
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
          monetizationNetwork: 'GoogleAdMob',
          mediationNetwork: AFMediationNetwork.googleAdMob.value,
          currencyIso4217Code: 'USD',
          revenue: 1.23,
          additionalParameters: {
            'adUnitId': 'ca-app-pub-XXXX/YYYY',
            'ad_network_click_id': '12345'
          });
      instance.logAdRevenue(adRevenueData);

      expect(selectedMethod, 'logAdRevenue');
    });

    test('check setConsentData call', () async {
      final consentData = AppsFlyerConsent.forGDPRUser(
        hasConsentForDataUsage: true,
        hasConsentForAdsPersonalization: true,
      );
      instance.setConsentData(consentData);

      expect(selectedMethod, 'setConsentData');
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
    });

    test('check setResolveDeepLinkURLs call', () async {
      instance.setResolveDeepLinkURLs(['https://example.com']);

      expect(selectedMethod, 'setResolveDeepLinkURLs');
    });

    test('check setPushNotification call', () async {
      instance.setPushNotification(true);

      expect(selectedMethod, 'setPushNotification');
    });

    test('check sendPushNotificationData call', () async {
      instance.sendPushNotificationData({'key': 'value'});

      expect(selectedMethod, 'sendPushNotificationData');
    });

    test('check enableFacebookDeferredApplinks call', () async {
      instance.enableFacebookDeferredApplinks(true);

      expect(selectedMethod, 'enableFacebookDeferredApplinks');
    });

    test('check disableSKAdNetwork call', () async {
      instance.disableSKAdNetwork(true);

      expect(selectedMethod, 'disableSKAdNetwork');
    });

    test('check setDisableAdvertisingIdentifiers call', () async {
      instance.setDisableAdvertisingIdentifiers(true);

      expect(selectedMethod, 'setDisableAdvertisingIdentifiers');
    });
  });
}
