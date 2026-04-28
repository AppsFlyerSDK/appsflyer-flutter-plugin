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
    await _runStopResumeSequence();

    if (mounted) setState(() {});
  }

  void _registerCallbacks() {
    _appsflyerSdk.onInstallConversionData((res) {
      AfQaLogger.callback("onInstallConversionData", res.toString());
      if (mounted) {
        setState(() {
          _gcd = res is Map ? res : {};
        });
      }
    });

    _appsflyerSdk.onAppOpenAttribution((res) {
      AfQaLogger.callback("onAppOpenAttribution", res.toString());
      if (mounted) {
        setState(() {
          _deepLinkData = res is Map ? res : {};
        });
      }
    });

    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      final payload = dp.deepLink == null ? {} : dp.toJson();
      AfQaLogger.callback(
          "onDeepLinking",
          "status=${dp.status}, "
              "deepLinkValue=${dp.deepLink?.deepLinkValue}, "
              "payload=$payload");
      if (mounted) {
        setState(() {
          _deepLinkData = dp.toJson();
        });
      }
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
        AfQaLogger.error(
            "startSDK", "code=$errorCode msg=$errorMessage");
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
    final r1 = await _logEventLogged(
      eventName: "af_demo_launch",
      values: const {},
      logTag: "logEvent(af_demo_launch)",
    );
    AfQaLogger.result("logEvent(af_demo_launch)", r1);

    final r2 = await _logEventLogged(
      eventName: "af_purchase",
      values: const {
        "af_revenue": 19.99,
        "af_currency": "EUR",
        "af_content_id": "id_42",
      },
      logTag: "logEvent: af_purchase sent",
    );
    AfQaLogger.result("logEvent: af_purchase sent", r2);

    final r3 = await _logEventLogged(
      eventName: "af_content_view",
      values: const {
        "af_content_id": "id_42",
        "af_content_type": "demo",
      },
      logTag: "logEvent: af_content_view sent",
    );
    AfQaLogger.result("logEvent: af_content_view sent", r3);
  }

  Future<void> _runCustomEvent() async {
    final params = <String, dynamic>{
      "af_revenue": 42.5,
      "af_currency": "EUR",
      "metadata": {
        "tenant": "qa_eu",
        "experiment": "rc_pipeline_v1",
        "ab_variant": "B",
      },
    };
    AfQaLogger.log(
      "logEvent",
      "name=af_qa_custom_purchase params=$params",
    );
    try {
      await _appsflyerSdk.logEvent("af_qa_custom_purchase", params);
    } catch (e) {
      AfQaLogger.error("logEvent", e);
    }
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
    final Map<String, dynamic> additionalData = {
      "tenant": "qa_eu",
      "experiment": "rc_pipeline_v1",
    };
    _safeCall("setAdditionalData", () {
      _appsflyerSdk.setAdditionalData(additionalData);
      AfQaLogger.log(
          "setAdditionalData", "keys=${additionalData.keys.toList()}");
    });

    final params = <String, dynamic>{
      "customer_user_id": "e2e_user_42",
      "tenant": "qa_eu",
      "experiment": "rc_pipeline_v1",
    };
    AfQaLogger.log(
      "logEvent",
      "name=af_qa_identity_check params=$params",
    );
    try {
      await _appsflyerSdk.logEvent("af_qa_identity_check", params);
    } catch (e) {
      AfQaLogger.error("logEvent", e);
    }
  }

  Future<void> _runStopResumeSequence() async {
    _safeCall("stop", () {
      _appsflyerSdk.stop(true);
      AfQaLogger.result("stop", true);
    });

    AfQaLogger.log("logEvent", "name=af_qa_suppressed params={}");
    try {
      await _appsflyerSdk.logEvent("af_qa_suppressed", const {});
    } catch (e) {
      AfQaLogger.error("logEvent", e);
    }

    await Future<void>.delayed(const Duration(seconds: 3));

    _safeCall("stop", () {
      _appsflyerSdk.stop(false);
      AfQaLogger.result("stop", false);
    });

    AfQaLogger.log("logEvent", "name=af_qa_resumed params={}");
    try {
      await _appsflyerSdk.logEvent("af_qa_resumed", const {});
    } catch (e) {
      AfQaLogger.error("logEvent", e);
    }
  }

  Future<bool?> _logEventLogged({
    required String eventName,
    required Map values,
    required String logTag,
  }) async {
    try {
      return await _appsflyerSdk.logEvent(eventName, values);
    } catch (e) {
      AfQaLogger.error(logTag, e);
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
    bool? logResult;
    try {
      AfQaLogger.log(
        "logEvent",
        "name=$eventName params=$eventValues",
      );
      logResult = await _appsflyerSdk.logEvent(eventName, eventValues);
      AfQaLogger.result("logEvent($eventName)", logResult);
      print("Event logged");
    } catch (e) {
      AfQaLogger.error("logEvent($eventName)", e);
      print("Failed to log event: $e");
    }
    return logResult;
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
      AfQaLogger.log(
          "logAdRevenue", "monetizationNetwork=SpongeBob currency=USD revenue=100.3");
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
