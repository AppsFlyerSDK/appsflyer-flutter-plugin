import 'dart:async';
import 'dart:io';

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
  // Resolves on the first onInstallConversionData callback so the auto-run
  // doesn't race ahead and call stop(true) before the install GCD response
  // lands. AppsFlyer's SDK substitutes the conversion-data payload with
  // "isStopTracking enabled" when the callback fires after stop(true), which
  // makes phase_1's is_first_launch=true check flake.
  final Completer<void> _gcdReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    afStart();
  }

  Future<void> afStart() async {
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: dotenv.env["DEV_KEY"]!,
        appId: dotenv.env["APP_ID"]!,
        showDebug: true,
        timeToWaitForATTUserAuthorization: 15,
        manualStart: true);
    _appsflyerSdk = AppsflyerSdk(options);

    _registerCallbacks();
    await _runPreStartAutoApis();

    await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);

    await _startSdkProgrammatically();
    await _runPostStartAutoApis();

    if (Platform.isAndroid) {
      _appsflyerSdk.performOnDeepLinking();
    }

    await _runStandardEvents();
    await _runCustomEvent();
    await _runIdentityCheck();

    try {
      await _gcdReady.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      AfQaLogger.error("onInstallConversionData", "code=-1 msg=gcd_timeout");
    }
    await _runStopResumeSequence();

    if (mounted) setState(() {});
    // Emit a single terminal marker the smoke runner can poll for. Lets the
    // runner replace its fixed `wait_after_launch_sec` sleep with an early
    // exit, which matters on CI where the SDK's first-launch HTTP round-trip
    // can take 60-120s on a no-KVM Linux emulator or a cold macOS sim.
    AfQaLogger.autoApis("--- Auto run complete ---");
  }

  void _registerCallbacks() {
    _appsflyerSdk.onInstallConversionData((res) {
      AfQaLogger.callback("onInstallConversionData", res);
      if (!_gcdReady.isCompleted) _gcdReady.complete();
      if (mounted) setState(() => _gcd = res);
    });

    _appsflyerSdk.onAppOpenAttribution((res) {
      AfQaLogger.callback("onAppOpenAttribution", res);
      if (mounted) setState(() => _deepLinkData = res);
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
  }

  Future<void> _runPreStartAutoApis() async {
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

  Future<void> _startSdkProgrammatically() async {
    final completer = Completer<void>();
    _appsflyerSdk.startSDK(
      onSuccess: () {
        AfQaLogger.result("startSDK", "SUCCESS");
        if (!completer.isCompleted) completer.complete();
      },
      onError: (int errorCode, String errorMessage) {
        AfQaLogger.error("startSDK", "code=$errorCode msg=$errorMessage");
        if (!completer.isCompleted) completer.complete();
      },
    );
    try {
      await completer.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      AfQaLogger.error("startSDK", "code=-1 msg=startSDK_callback_timeout");
    }
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

  /// Emit `[AF_QA][logEvent] name=... params=...`, call the SDK, then emit
  /// `[AF_QA][<resultTag>] result: ...` on success (default tag:
  /// `logEvent(<name>)`) or the unified `[AF_QA][logEvent] error: ...` on
  /// throw — the latter shape is what the smoke runner's `no_log_event_error`
  /// absent check greps for, so any logEvent failure surfaces uniformly.
  Future<bool?> _logEvent(
    String name,
    Map params, {
    String? resultTag,
  }) async {
    AfQaLogger.log("logEvent", "name=$name params=$params");
    try {
      final r = await _appsflyerSdk.logEvent(name, params);
      AfQaLogger.result(resultTag ?? "logEvent($name)", r);
      return r;
    } catch (e) {
      AfQaLogger.error("logEvent", e);
      return null;
    }
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
    final result = await _logEvent(eventName, eventValues);
    print(result == null ? "Failed to log event" : "Event logged");
    return result;
  }

  void logAdRevenueEvent() {
    try {
      Map<String, String> customParams = {
        'ad_platform': 'Admob',
        'ad_currency': 'USD',
      };

      AdRevenueData adRevenueData = AdRevenueData(
          monetizationNetwork: 'SpongeBob',
          mediationNetwork: AFMediationNetwork.applovinMax.value,
          currencyIso4217Code: 'USD',
          revenue: 100.3,
          additionalParameters: customParams);
      _appsflyerSdk.logAdRevenue(adRevenueData);
      AfQaLogger.log("logAdRevenue",
          "monetizationNetwork=SpongeBob currency=USD revenue=100.3");
      print("Ad Revenue event logged with no errors");
    } catch (e) {
      AfQaLogger.error("logAdRevenue", e);
      print("Failed to log event: $e");
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

      Map<String, String> additionalParameters = {
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
      print("Purchase validation successful: $result");
      return result as Map<String, dynamic>?;
    } catch (e) {
      AfQaLogger.error("validatePurchase", e);
      print("Purchase validation failed: $e");
      rethrow;
    }
  }
}
