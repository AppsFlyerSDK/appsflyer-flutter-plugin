// Runtime verification of the RPC response shape against the real native RPC.
//
// AppsFlyerRPC 7.0.13 (iOS) returns every scalar getter as a bare value in the
// response `data`, matching Android's RpcResponse.Success(value). The plugin
// bridge forwards `data` unchanged; when a platform nests a scalar under a named
// key instead, that call fails with "<method> returned no value". These tests
// exist to catch exactly that, so they assert on the returned value rather than
// just on completion.
//
// Run on a booted simulator or device:
//   flutter test integration_test/rpc_response_shape_test.dart -d <device-id>

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final sdk = AppsFlyerSdk.instance;

  // A "returned no value" failure is the response-shape regression this suite
  // guards; any other AppsFlyerException is an unrelated native rejection.
  Matcher isNotShapeFailure(String method) => isNot(
        isA<AppsFlyerException>().having(
          (error) => error.message,
          'message',
          contains('$method returned no value'),
        ),
      );

  group('RPC response shape', () {
    testWidgets('getSdkVersion returns a bare version string', (_) async {
      final version = await sdk.getSdkVersion();
      expect(version, isNotEmpty);
    });

    testWidgets('host getters round-trip a bare string', (_) async {
      // Empty before setHost, which is also the "not configured" value on iOS.
      expect(await sdk.getHostName(), isA<String>());
      expect(await sdk.getHostPrefix(), isA<String>());

      // Setting a value proves the getters carry the payload rather than only
      // ever yielding the empty string that an unset property also produces.
      await sdk.setHost('prefix', 'host.example.com');
      expect(await sdk.getHostName(), 'host.example.com');
      expect(await sdk.getHostPrefix(), 'prefix');
    });

    testWidgets('isStopped returns a bare bool in both states', (_) async {
      await sdk.stop(false);
      expect(await sdk.isStopped(), isFalse);

      await sdk.stop(true);
      expect(await sdk.isStopped(), isTrue);

      await sdk.stop(false);
    });

    testWidgets('isSessionReady returns a bare bool', (_) async {
      expect(await sdk.isSessionReady(), isA<bool>());
    });

    testWidgets('getAppsFlyerUID returns a bare uid string', (_) async {
      await sdk.init(devKey: 'integration-test-dev-key', appId: '123456789');

      final uid = await sdk.getAppsFlyerUID();
      expect(uid, isNotNull);
      expect(uid, isNotEmpty);
    });

    testWidgets('performDeepLinking resolves under its shared method name',
        (_) async {
      await sdk.registerDeepLinkListener();

      // 7.0.13 renamed the iOS method to performDeepLinking; calling the old
      // name would fail with a method-not-found error rather than completing.
      await expectLater(
        sdk.performDeepLinking('https://example.com/path'),
        completes,
      );
    });

    testWidgets('generateInviteLink does not fail on response shape', (_) async {
      // Link generation needs a real dev key and network, so success is not
      // asserted — only that any failure is not the unwrapping regression.
      try {
        final link = await sdk.generateInviteLink();
        expect(link, isNotEmpty);
      } on AppsFlyerException catch (error) {
        expect(error, isNotShapeFailure('generateInviteLink'));
      }
    });
  });
}
