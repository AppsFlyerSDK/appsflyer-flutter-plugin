import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppsflyerSdk instance;
  String selectedMethod = "";
  const MethodChannel methodChannel = MethodChannel('af-api');
  const MethodChannel callbacksChannel = MethodChannel('callbacks');
  const EventChannel eventChannel = EventChannel('af-events');
  const MethodChannel eventMethodChannel = MethodChannel('af-events');

  setUp(() {
    //test map options way
    instance = AppsflyerSdk.private(methodChannel, eventChannel,
        mapOptions: {'afDevKey': 'sdfhj2342cx'});

    methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      String method = methodCall.method;
      if (method == 'initSdk') {
        selectedMethod = method;
      }
    });

    eventMethodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      String method = methodCall.method;
      if (method == 'listen') {
        selectedMethod = method;
      }
    });
  });

  test('check initSdk call', () async {
    await instance.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: false
    );

    expect('initSdk', selectedMethod);
  });

  group('AppsFlyerSdk', () {
    setUp(() {
      //test map options way
      instance = AppsflyerSdk.private(methodChannel, eventChannel,
          mapOptions: {'afDevKey': 'sdfhj2342cx'});

      callbacksChannel.setMockMethodCallHandler((call) async {
        String method = call.method;
        if (method == 'startListening') {
          selectedMethod = method;
        }
      });

      methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        String method = methodCall.method;
        switch (method) {
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
          case 'setUserEmailsWithCryptType':
          case 'setUserEmails':
          case 'setAdditionalData':
          case 'waitForCustomerUserId':
          case 'setCustomerUserId':
          case 'enableLocationCollection':
          case 'setAndroidIdData':
          case 'setImeiData':
          case 'updateServerUninstallToken':
          case 'stop':
          case 'setIsUpdate':
          case 'setCurrencyCode':
          case 'setHost':
          case 'logEvent':
          case 'initSdk':
            selectedMethod = methodCall.method;
            break;
        }
      });
    });

    tearDown(() {
      methodChannel.setMockMethodCallHandler(null);
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

    test('check setSharingFilterForAllPartners call', () async {
      instance.setSharingFilterForAllPartners();

      expect(selectedMethod, 'setSharingFilterForAllPartners');
    });

    test('check setSharingFilter call', () async {
      instance.setSharingFilter(["filters"]);

      expect(selectedMethod, 'setSharingFilter');
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

      expect(selectedMethod, 'listen');
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

    test('check setUserEmailsWithCryptType call', () async {
      instance.setUserEmails(["emails"], EmailCryptType.EmailCryptTypeNone);

      expect(selectedMethod, 'setUserEmailsWithCryptType');
    });

    test('check setUserEmails call', () async {
      instance.setUserEmails(["emails"]);

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

    test('check enableLocationCollection call', () async {
      instance.enableLocationCollection(false);

      expect(selectedMethod, 'enableLocationCollection');
    });

    test('check setImeiData call', () async {
      instance.setImeiData("imei");

      expect(selectedMethod, 'setImeiData');
    });

    test('check setAndroidIdData call', () async {
      instance.setAndroidIdData("androidId");

      expect(selectedMethod, 'setAndroidIdData');
    });
  });
}
