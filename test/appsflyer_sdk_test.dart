import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppsflyerSdk instance;
  String selectedMethod = "";

  group('AppsFlyerSdk', () {
    const MethodChannel methodChannel = MethodChannel('af-api');
    const EventChannel eventChannel = EventChannel('af-events');
    // const AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

    setUp(() {
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
          case 'validateAndLogInAppPurchase':
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

      //test map options way
      instance = AppsflyerSdk.private(methodChannel, eventChannel,
          mapOptions: {'afDevKey': 'sdfhj2342cx'});
    });

    tearDown(() {
      methodChannel.setMockMethodCallHandler(null);
    });

    test('check initSdk call', () async {
      dynamic res = await instance.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
      );

      expect('initSdk', selectedMethod);
    });

    test('check logEvent call', () async {
      await instance.logEvent("eventName", {"key": "val"});

      expect('logEvent', selectedMethod);
    });

    test('check setHost call', () async {
      instance.setHost("", "");

      expect('setHost', selectedMethod);
    });

    test('check setCurrencyCode call', () async {
      instance.setCurrencyCode("currencyCode");

      expect('setCurrencyCode', selectedMethod);
    });

    test('check setIsUpdate call', () async {
      instance.setIsUpdate(true);

      expect('setIsUpdate', selectedMethod);
    });

    test('check stop call', () async {
      instance.stop(true);

      expect('stop', selectedMethod);
    });
  });
}
