import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';

void main() {
  // AppsflyerSdk instance;
  // MockMethodChannel methodChannel;
  // MockEventChannel eventChannel;

  // group('AppsFlyerSdk', () {
  //   final List<MethodCall> log = <MethodCall>[];
  //   // const AppsflyerSdk appsflyerSdk = AppsflyerSdk(options);

  //   setUp(() {
  //     methodChannel = MockMethodChannel();
  //     eventChannel = MockEventChannel();
  //     instance =
  //         AppsflyerSdk.private(methodChannel, {'afDevKey': 'sdfhj2342cx'});
  //   });
  // });

  test('basic test', () {
    int x = 3;
    expect(x, 3);
  });
}

class MockMethodChannel extends Mock implements MethodChannel {}

class MockEventChannel extends Mock implements EventChannel {}
