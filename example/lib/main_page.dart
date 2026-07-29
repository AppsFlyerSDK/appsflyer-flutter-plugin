import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'af_qa_logger.dart';
import 'home_container.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  late AppsflyerSdk _appsflyerSdk;
  Map _deepLinkData = {};
  Map _gcd = {};
  // Unblocks the auto-run after the first install GCD callback. Must complete
  // before stop(true) so phase_1's is_first_launch check is not corrupted.
  final Completer<void> _gcdReady = Completer<void>();
  // Unblocks post-start auto APIs after the first onSessionReady-driven startSDK
  // callback (success or error) in this cold-start auto-run.
  final Completer<void> _firstStartDone = Completer<void>();

  @override
  void initState() {
    super.initState();
    afStart();
  }

  Future<void> afStart() async {
    try {
      final AppsFlyerOptions options = AppsFlyerOptions(
          afDevKey: dotenv.env["DEV_KEY"]!,
          appId: dotenv.env["APP_ID"]!,
          showDebug: true,
          timeToWaitForATTUserAuthorization: 15);
      _appsflyerSdk = AppsflyerSdk(options);

      _registerCallbacks();
      await _runPreStartAutoApis();

      // initSdk() initializes only; startSDK() sends the Launch and must be
      // called from onSessionReady once per foreground cycle.
      await _appsflyerSdk.initSdk(
          registerConversionDataCallback: true,
          registerOnDeepLinkingCallback: true);

      await _firstStartDone.future;
      await _runPostStartAutoApis();

      await _runStandardEvents();
      await _runCustomEvent();
      await _runIdentityCheck();

      try {
        await _gcdReady.future.timeout(const Duration(seconds: 90));
      } on TimeoutException {
        AfQaLogger.error("onInstallConversionData", "code=-1 msg=gcd_timeout");
      }
      await _runStopResumeSequence();
    } catch (e, st) {
      AfQaLogger.error("afStart", '$e\n$st');
    } finally {
      if (mounted) setState(() {});
      AfQaLogger.autoApis("--- Auto run complete ---");
    }
  }

  void _registerCallbacks() {
    _appsflyerSdk.onInstallConversionData((res) {
      AfQaLogger.callback("onInstallConversionData", res);
      if (!_gcdReady.isCompleted) _gcdReady.complete();
      if (mounted) {
        setState(() => _gcd = _conversionPayloadForUi(res));
      }
    });

    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      // Empty payload when the SDK didn't resolve a deep link, so the
      // smoke runner's pattern check sees a stable `payload={}` shape.
      final payload = dp.deepLink == null ? const {} : dp.toJson();
      AfQaLogger.callback(
        "onDeepLinking",
        "status=${dp.status}, "
            "deepLinkValue=${dp.deepLink?.deepLinkValue}, "
            "payload=$payload",
      );
      if (mounted) setState(() => _deepLinkData = dp.toJson());
    });

    // onSessionReady fires once per foreground cycle after launch deep link
    // resolution; issue startSDK() here so every foreground sends a session.
    _appsflyerSdk.registerSessionReadyListener((res) {
      AfQaLogger.callback("onSessionReady", res);
      _startSdkForCurrentSession();
    });
  }

  /// Extracts the conversion-data map for the example UI (`payload` envelope).
  static Map<String, dynamic> _conversionPayloadForUi(dynamic res) {
    if (res is! Map) return {};
    final payload = res['payload'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return Map<String, dynamic>.from(res);
  }

  @override
  void dispose() {
    _appsflyerSdk.unregisterSessionReadyListener();
    _appsflyerSdk.unregisterConversionDataListener();
    super.dispose();
  }

  Future<void> _runPreStartAutoApis() async {
    // Apply configuration setters before the first startSDK() in this session.
    _safeCall("setCurrencyCode", () {
      _appsflyerSdk.setCurrencyCode("EUR");
      AfQaLogger.result("setCurrencyCode", "EUR");
    });

    _safeCall("setCustomerUserId", () {
      _appsflyerSdk.setCustomerUserId("e2e_user_42");
      AfQaLogger.result("setCustomerUserId", "e2e_user_42");
    });

    final Map<String, dynamic> additionalData = {
      "tenant": "qa_eu",
      "experiment": "rc_pipeline_v1",
    };
    _safeCall("setAdditionalData", () {
      _appsflyerSdk.setAdditionalData(additionalData);
      AfQaLogger.log(
          "setAdditionalData", "keys=${additionalData.keys.toList()}");
    });

    AfQaLogger.autoApis("--- Pre-start auto APIs complete ---");
  }

  void _startSdkForCurrentSession() {
    _appsflyerSdk.startSDK(
      onSuccess: () {
        AfQaLogger.result("startSDK", "SUCCESS");
        if (!_firstStartDone.isCompleted) _firstStartDone.complete();
      },
      onError: (int errorCode, String errorMessage) {
        AfQaLogger.error("startSDK", "code=$errorCode msg=$errorMessage");
        if (!_firstStartDone.isCompleted) _firstStartDone.complete();
      },
    );
  }

  Future<void> _runPostStartAutoApis() async {
    try {
      final v = await _appsflyerSdk.getSDKVersion();
      AfQaLogger.result("getSDKVersion", v);
    } catch (e) {
      AfQaLogger.error("getSDKVersion", e);
    }

    try {
      final uid = await _appsflyerSdk.getAppsFlyerUID();
      AfQaLogger.result("getAppsFlyerUID", uid);
    } catch (e) {
      AfQaLogger.error("getAppsFlyerUID", e);
    }

    AfQaLogger.autoApis("--- Post-start auto APIs complete ---");
  }

  Future<void> _runStandardEvents() async {
    await _logEvent("af_demo_launch", const {});
    await _logEvent(
      "af_purchase",
      const {
        "af_revenue": 19.99,
        "af_currency": "EUR",
        "af_content_id": "id_42",
      },
      resultTag: "logEvent: af_purchase sent",
    );
    await _logEvent(
      "af_content_view",
      const {
        "af_content_id": "id_42",
        "af_content_type": "demo",
      },
      resultTag: "logEvent: af_content_view sent",
    );
  }

  Future<void> _runCustomEvent() async {
    await _logEvent("af_qa_custom_purchase", const {
      "af_revenue": 42.5,
      "af_currency": "EUR",
      "metadata": {
        "tenant": "qa_eu",
        "experiment": "rc_pipeline_v1",
        "ab_variant": "B",
      },
    });
  }

  Future<void> _runIdentityCheck() async {
    _safeCall("setCustomerUserId", () {
      _appsflyerSdk.setCustomerUserId("e2e_user_42");
      AfQaLogger.result("setCustomerUserId", "e2e_user_42");
    });
    _safeCall("setCurrencyCode", () {
      _appsflyerSdk.setCurrencyCode("EUR");
      AfQaLogger.result("setCurrencyCode", "EUR");
    });
    const additionalData = {
      "tenant": "qa_eu",
      "experiment": "rc_pipeline_v1",
    };
    _safeCall("setAdditionalData", () {
      _appsflyerSdk.setAdditionalData(additionalData);
      AfQaLogger.log(
          "setAdditionalData", "keys=${additionalData.keys.toList()}");
    });

    await _logEvent("af_qa_identity_check", const {
      "customer_user_id": "e2e_user_42",
      "tenant": "qa_eu",
      "experiment": "rc_pipeline_v1",
    });
  }

  Future<void> _runStopResumeSequence() async {
    _safeCall("stop", () {
      _appsflyerSdk.stop(true);
      AfQaLogger.result("stop", true);
    });
    await _logEvent("af_qa_suppressed", const {});

    await Future<void>.delayed(const Duration(seconds: 3));

    _safeCall("stop", () {
      _appsflyerSdk.stop(false);
      AfQaLogger.result("stop", false);
    });
    await _logEvent("af_qa_resumed", const {});
  }

  /// Logs the invocation, calls [AppsflyerSdk.logEvent] (fire-and-forget), and
  /// emits a harness `result: true` line for the smoke runner. Server failures
  /// are not surfaced unless onSuccess/onError callbacks are added here.
  Future<bool?> _logEvent(
    String name,
    Map params, {
    String? resultTag,
  }) async {
    AfQaLogger.log("logEvent", "name=$name params=$params");
    _appsflyerSdk.logEvent(name, params);
    AfQaLogger.result(resultTag ?? "logEvent($name)", true);
    return true;
  }

  void _safeCall(String tag, void Function() body) {
    try {
      body();
    } catch (e) {
      AfQaLogger.error(tag, e);
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
    try {
      final Map<String, String> customParams = {
        'ad_platform': 'Admob',
        'ad_currency': 'USD',
      };

      final AdRevenueData adRevenueData = AdRevenueData(
          monetizationNetwork: 'SpongeBob',
          mediationNetwork: AFMediationNetwork.applovinMax.value,
          currencyIso4217Code: 'USD',
          revenue: 100.3,
          additionalParameters: customParams);
      _appsflyerSdk.logAdRevenue(adRevenueData);
      AfQaLogger.log("logAdRevenue",
          "monetizationNetwork=SpongeBob currency=USD revenue=100.3");
    } catch (e) {
      AfQaLogger.error("logAdRevenue", e);
    }
  }

  Future<Map<String, dynamic>?> validatePurchase(
      String purchaseToken, String productId) async {
    try {
      final purchaseDetails = AFPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        purchaseToken: purchaseToken,
        productId: productId,
      );

      final Map<String, String> additionalParameters = {
        'validation_source': 'flutter_example',
        'app_version': '1.0.0',
      };

      AfQaLogger.log("validatePurchase",
          "productId=$productId tokenLen=${purchaseToken.length}");
      final result = await _appsflyerSdk.validateAndLogInAppPurchaseV2(
        purchaseDetails,
        additionalParameters: additionalParameters,
      );

      AfQaLogger.result("validatePurchase", result);
      return result;
    } catch (e) {
      AfQaLogger.error("validatePurchase", e);
      rethrow;
    }
  }
}
