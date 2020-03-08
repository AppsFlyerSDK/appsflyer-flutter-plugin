import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppsflyerSdk instance;

  group('AppsFlyerSdk', () {
    final List<MethodCall> log = <MethodCall>[];
    const MethodChannel methodChannel = MethodChannel('af-api');
    const EventChannel eventChannel = EventChannel('af-events');
    // const AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

    setUp(() {
      methodChannel.setMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return '';
      });

      log.clear();

      //test map options way
      instance = AppsflyerSdk.private(methodChannel,eventChannel,
          mapOptions: {'afDevKey': 'sdfhj2342cx'});
    });

    test('check initSdk call', () async {
      methodChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'initSdk':
            return 'SUCCESS';
            break;
        }
        return 'FAIL';
      });

      dynamic res = await instance.initSdk(true,true);
      expect(res, 'SUCCESS');
    });
  });
}
