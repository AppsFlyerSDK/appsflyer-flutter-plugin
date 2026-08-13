import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'af_qa_logger.dart';
import 'home_container.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  late final AppsFlyerSdk _appsflyerSdk;

  // Unblocks the auto-run after the first install GCD callback. Must complete
  // before stop(true) so phase_1's is_first_launch check is not corrupted.
  final Completer<void> _gcdReady = Completer<void>();
  // Unblocks post-start auto APIs after the first session-ready-driven start
  // callback (success or error) in this cold-start auto-run.
  final Completer<void> _firstStartDone = Completer<void>();

  Map<String, dynamic> _deepLinkData = {};
  Map<String, dynamic> _gcd = {};

  @override
  void initState() {
    super.initState();
    afStart();
  }

  Future<void> afStart() async {
    try {
      _appsflyerSdk = AppsFlyerSdk.instance;
      await _appsflyerSdk.enableDebug(true);

      await _runPreStartAutoApis();

      // Before init(): the Android SDK runs its one-shot deferred deep-link
      // resolution while init() replays the launch intent, and skips it when no
      // listener is registered yet.
      await _registerDeepLinkListener();

      // init() initializes only; start() sends the Launch and must be called
      // from the session-ready callback once per foreground cycle.
      await _appsflyerSdk.init(
        devKey: dotenv.env['DEV_KEY']!,
        appId: dotenv.env['APP_ID']!,
      );

      await _registerListeners();

      await _firstStartDone.future;
      await _runPostStartAutoApis();

      await _runStandardEvents();
      await _runCustomEvent();
      await _runIdentityCheck();

      try {
        await _gcdReady.future.timeout(const Duration(seconds: 90));
      } on TimeoutException {
        AfQaLogger.error('onInstallConversionData', 'code=-1 msg=gcd_timeout');
      }
      await _runStopResumeSequence();
    } catch (error, stackTrace) {
      AfQaLogger.error('afStart', '$error\n$stackTrace');
    } finally {
      if (mounted) {
        setState(() {});
      }
      AfQaLogger.autoApis('--- Auto run complete ---');
    }
  }

  Future<void> _registerDeepLinkListener() async {
    await _appsflyerSdk.registerDeepLinkListener((result) {
      // Empty payload when the SDK didn't resolve a deep link, so the
      // smoke runner's pattern check sees a stable `payload={}` shape.
      final payload = result.deepLink == null ? const {} : result.toJson();
      AfQaLogger.callback(
        'onDeepLinking',
        'status=${_deepLinkStatusForQaLog(result.status)}, '
            'deepLinkValue=${result.deepLink?.deepLinkValue}, '
            'payload=$payload',
      );
      if (mounted) {
        setState(() => _deepLinkData = result.toJson());
      }
    });
  }

  Future<void> _registerListeners() async {
    await _appsflyerSdk.registerConversionListener(
      onSuccess: (res) {
        AfQaLogger.callback('onInstallConversionData', res);
        if (!_gcdReady.isCompleted) {
          _gcdReady.complete();
        }
        if (mounted) {
          setState(() => _gcd = _conversionPayloadForUi(res));
        }
      },
      onFailure: (error) {
        AfQaLogger.error('onInstallConversionData', error);
        if (!_gcdReady.isCompleted) {
          _gcdReady.complete();
        }
      },
    );

    // The session-ready callback fires once per foreground cycle after launch
    // deep link resolution; issue start() here so every foreground sends a
    // session.
    await _appsflyerSdk.registerSessionReadyListener(() {
      AfQaLogger.callback('onSessionReady', null);
      _startSdkForCurrentSession();
    });
  }

  /// Maps the SDK 7 deep-link status to the legacy QA log format.
  static String _deepLinkStatusForQaLog(DeepLinkStatus status) {
    switch (status) {
      case DeepLinkStatus.found:
        return 'Status.FOUND';
      case DeepLinkStatus.notFound:
        return 'Status.NOT_FOUND';
      case DeepLinkStatus.error:
        return 'Status.ERROR';
      case DeepLinkStatus.unknown:
        return 'Status.PARSE_ERROR';
    }
  }

  /// Extracts the conversion-data map for the example UI (`payload` envelope).
  static Map<String, dynamic> _conversionPayloadForUi(
    Map<String, dynamic> res,
  ) {
    final payload = res['payload'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return res;
  }

  @override
  void dispose() {
    _appsflyerSdk.unregisterSessionReadyListener();
    _appsflyerSdk.unregisterConversionListener();
    super.dispose();
  }

  Future<void> _runPreStartAutoApis() async {
    // Apply configuration setters before the first start() in this session.
    await _safeCall('setCurrencyCode', () async {
      await _appsflyerSdk.setCurrencyCode('EUR');
      AfQaLogger.result('setCurrencyCode', 'EUR');
    });

    await _safeCall('setCustomerUserId', () async {
      await _appsflyerSdk.setCustomerUserId('e2e_user_42');
      AfQaLogger.result('setCustomerUserId', 'e2e_user_42');
    });

    const additionalData = {
      'tenant': 'qa_eu',
      'experiment': 'rc_pipeline_v1',
    };
    await _safeCall('setAdditionalData', () async {
      await _appsflyerSdk.setAdditionalData(additionalData);
      AfQaLogger.log(
        'setAdditionalData',
        'keys=${additionalData.keys.toList()}',
      );
    });

    AfQaLogger.autoApis('--- Pre-start auto APIs complete ---');
  }

  Future<void> _startSdkForCurrentSession() async {
    try {
      await _appsflyerSdk.start(awaitResponse: true);
      AfQaLogger.result('startSDK', 'SUCCESS');
    } on AppsFlyerException catch (error) {
      AfQaLogger.error(
        'startSDK',
        'code=${error.code} msg=${error.message}',
      );
    } finally {
      if (!_firstStartDone.isCompleted) {
        _firstStartDone.complete();
      }
    }
  }

  Future<void> _runPostStartAutoApis() async {
    try {
      final version = await _appsflyerSdk.getSdkVersion();
      AfQaLogger.result('getSDKVersion', version);
    } catch (error) {
      AfQaLogger.error('getSDKVersion', error);
    }

    try {
      final uid = await _appsflyerSdk.getAppsFlyerUID();
      AfQaLogger.result('getAppsFlyerUID', uid);
    } catch (error) {
      AfQaLogger.error('getAppsFlyerUID', error);
    }

    AfQaLogger.autoApis('--- Post-start auto APIs complete ---');
  }

  Future<void> _runStandardEvents() async {
    await _logEvent('af_demo_launch', const {});
    await _logEvent(
      'af_purchase',
      const {
        'af_revenue': 19.99,
        'af_currency': 'EUR',
        'af_content_id': 'id_42',
      },
      resultTag: 'logEvent: af_purchase sent',
    );
    await _logEvent(
      'af_content_view',
      const {
        'af_content_id': 'id_42',
        'af_content_type': 'demo',
      },
      resultTag: 'logEvent: af_content_view sent',
    );
  }

  Future<void> _runCustomEvent() async {
    await _logEvent('af_qa_custom_purchase', const {
      'af_revenue': 42.5,
      'af_currency': 'EUR',
      'metadata': {
        'tenant': 'qa_eu',
        'experiment': 'rc_pipeline_v1',
        'ab_variant': 'B',
      },
    });
  }

  Future<void> _runIdentityCheck() async {
    await _safeCall('setCustomerUserId', () async {
      await _appsflyerSdk.setCustomerUserId('e2e_user_42');
      AfQaLogger.result('setCustomerUserId', 'e2e_user_42');
    });
    await _safeCall('setCurrencyCode', () async {
      await _appsflyerSdk.setCurrencyCode('EUR');
      AfQaLogger.result('setCurrencyCode', 'EUR');
    });
    const additionalData = {
      'tenant': 'qa_eu',
      'experiment': 'rc_pipeline_v1',
    };
    await _safeCall('setAdditionalData', () async {
      await _appsflyerSdk.setAdditionalData(additionalData);
      AfQaLogger.log(
        'setAdditionalData',
        'keys=${additionalData.keys.toList()}',
      );
    });

    await _logEvent('af_qa_identity_check', const {
      'customer_user_id': 'e2e_user_42',
      'tenant': 'qa_eu',
      'experiment': 'rc_pipeline_v1',
    });
  }

  Future<void> _runStopResumeSequence() async {
    await _safeCall('stop', () async {
      await _appsflyerSdk.stop(true);
      AfQaLogger.result('stop', true);
    });
    await _logEvent('af_qa_suppressed', const {});

    await Future<void>.delayed(const Duration(seconds: 3));

    await _safeCall('stop', () async {
      await _appsflyerSdk.stop(false);
      AfQaLogger.result('stop', false);
    });
    await _logEvent('af_qa_resumed', const {});
  }

  /// Logs the invocation, calls [AppsFlyerSdk.logEvent] (fire-and-forget), and
  /// emits a harness `result: true` line for the smoke runner. Server failures
  /// are not surfaced unless awaitResponse is enabled here.
  Future<bool?> _logEvent(
    String name,
    Map params, {
    String? resultTag,
  }) async {
    AfQaLogger.log('logEvent', 'name=$name params=$params');
    try {
      await _appsflyerSdk.logEvent(
        name,
        eventValues: Map<String, dynamic>.from(params),
      );
    } on AppsFlyerException catch (error) {
      AfQaLogger.error('logEvent', error);
    }
    AfQaLogger.result(resultTag ?? 'logEvent($name)', true);
    return true;
  }

  Future<void> _safeCall(
    String tag,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (error) {
      AfQaLogger.error(tag, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppsFlyer SDK example app'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Builder(
        builder: (context) {
          return SafeArea(
            child: HomeContainer(
              onData: _gcd,
              deepLinkData: _deepLinkData,
              logEvent: logEvent,
              logAdRevenueEvent: logAdRevenueEvent,
              validatePurchase: validatePurchase,
            ),
          );
        },
      ),
    );
  }

  Future<bool?> logEvent(String eventName, Map eventValues) async {
    return _logEvent(eventName, eventValues);
  }

  void logAdRevenueEvent() {
    () async {
      try {
        await _appsflyerSdk.logAdRevenue(
          monetizationNetwork: 'SpongeBob',
          mediationNetwork: AFMediationNetwork.applovinMax,
          currencyIso4217Code: 'USD',
          revenue: 100.3,
          additionalParameters: const {
            'ad_platform': 'Admob',
            'ad_currency': 'USD',
          },
        );
        AfQaLogger.log(
          'logAdRevenue',
          'monetizationNetwork=SpongeBob currency=USD revenue=100.3',
        );
      } on AppsFlyerException catch (error) {
        AfQaLogger.error('logAdRevenue', error);
      }
    }();
  }

  Future<Map<String, dynamic>?> validatePurchase(
    String purchaseToken,
    String productId,
  ) async {
    final purchase = defaultTargetPlatform == TargetPlatform.iOS
        ? AFIOSPurchaseDetails(
            purchaseType: AFPurchaseType.oneTimePurchase,
            productId: productId,
            transactionId: purchaseToken,
          )
        : AFAndroidPurchaseDetails(
            purchaseType: AFPurchaseType.oneTimePurchase,
            productId: productId,
            purchaseToken: purchaseToken,
          );

    try {
      AfQaLogger.log(
        'validatePurchase',
        'productId=$productId tokenLen=${purchaseToken.length}',
      );
      final result = await _appsflyerSdk.validateAndLogInAppPurchase(
        purchase,
        additionalParameters: const {
          'validation_source': 'flutter_example',
          'app_version': '1.0.0',
        },
        awaitResponse: true,
      );

      AfQaLogger.result('validatePurchase', result);
      return result;
    } on AppsFlyerException catch (error) {
      AfQaLogger.error('validatePurchase', error);
      rethrow;
    }
  }
}
