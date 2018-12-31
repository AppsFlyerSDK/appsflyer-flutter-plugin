import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

void main() {
  // test('check if initSdk returns answer', () {
  //   int x = 1;
  //   expect(x, 1);
  // });
  Map options = {'afDevKey': 'fsdfjksf3as'};
  // AppsflyerSdk instance =
  // AppsflyerSdk({}).channel.setMockMethodCallHandler(handler);
  var result;
  setUp(() async {
    // result = await AppsflyerSdk.initSdk(options);
  });

  group('initSdk test', () {
    test("initSdk response isn't empty", () {
      expect(result, result.toString().isNotEmpty);
    });
  });
}
