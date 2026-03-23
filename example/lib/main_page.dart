import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'af_demo_logger.dart';
import 'af_demo_page.dart';

/// Entry widget for the demo app.
///
/// Responsibilities:
///   1. Build [AppsFlyerOptions] from .env values.
///   2. Call [AppsflyerSdk.initSdk] with all three callback flags.
///   3. Call [AppsflyerSdk.startSDK] (manual-start mode).
///   4. Run every "Auto" API immediately after start, with full [AF_DEMO] logging.
///   5. Hand the initialised SDK instance to [AfDemoPage].
///
/// Config keys expected in example/.env:
///   DEV_KEY   — AppsFlyer dev key        (placeholder: YOUR_DEV_KEY)
///   APP_ID    — iOS numeric App Store ID  (placeholder: YOUR_IOS_APP_ID)
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late AppsflyerSdk _sdk;
  final AfDemoLogger _logger = AfDemoLogger();
  bool _sdkReady = false;
  String _initStatus = 'Initialising AppsFlyer SDK...';

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SDK Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initSdk() async {
    // ── Step 1: Build options from .env ────────────────────────────────────
    final devKey = dotenv.env['DEV_KEY'] ?? 'YOUR_DEV_KEY';
    final appId = dotenv.env['APP_ID'] ?? '000000000';

    _logger.log('initSdk', 'devKey=${_mask(devKey)} appId=$appId platform=${Platform.operatingSystem}');

    final options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: appId,
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      // manualStart=true lets us call startSDK() separately so we can attach
      // callbacks before the SDK fires its first session.
      manualStart: true,
    );

    // ── Step 2: Create SDK instance ─────────────────────────────────────────
    _logger.logCalling('AppsflyerSdk constructor');
    _sdk = AppsflyerSdk(options);

    // ── Step 3: initSdk — registers all three callback channels ────────────
    _logger.logCalling('initSdk');
    try {
      await _sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
      _logger.logResult('initSdk', 'channel registration complete');
    } catch (e) {
      _logger.logError('initSdk', e);
    }

    // ── Step 3b: Wire callbacks early so they fire on first session ──────────
    _sdk.onInstallConversionData((data) {
      _logger.logCallback('onInstallConversionData', data);
      print('[AF_QA] onInstallConversionData callback received: $data');
    });

    _sdk.onAppOpenAttribution((data) {
      _logger.logCallback('onAppOpenAttribution', data);
      print('[AF_QA] onAppOpenAttribution callback received: $data');
    });

    _sdk.onDeepLinking((DeepLinkResult dp) {
      _logger.logCallback('onDeepLinking',
          'status=${dp.status} deepLinkValue=${dp.deepLink?.deepLinkValue} error=${dp.error}');
      print('[AF_QA] onDeepLinking callback received: status=${dp.status} deepLinkValue=${dp.deepLink?.deepLinkValue} error=${dp.error}');
    });

    // ── Step 4: Run all safe Auto APIs before startSDK ──────────────────────
    _runAutoApis();

    // ── Step 5: startSDK ────────────────────────────────────────────────────
    _logger.logCalling('startSDK');
    _sdk.startSDK(
      onSuccess: () {
        _logger.logResult('startSDK', 'SUCCESS — SDK started');
        if (mounted) {
          setState(() {
            _sdkReady = true;
            _initStatus = 'SDK started successfully';
          });
        }
        // Run Auto APIs that are safe to call after start
        _runAutoApisPostStart();
      },
      onError: (int code, String message) {
        _logger.logError('startSDK', 'code=$code message=$message');
        if (mounted) {
          setState(() {
            // Still show the demo page so manual buttons remain usable
            _sdkReady = true;
            _initStatus = 'SDK start error: $code — $message';
          });
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auto APIs: run on launch, before startSDK
  // These are configuration setters that are safe to call before the first
  // session event is sent.
  // ─────────────────────────────────────────────────────────────────────────

  void _runAutoApis() {
    _logger.log('AUTO_APIS', '--- Running pre-start auto APIs ---');

    // Plugin version (synchronous, no native call)
    _logger.logCalling('getVersionNumber');
    final pluginVersion = _sdk.getVersionNumber();
    _logger.logResult('getVersionNumber', pluginVersion);

    // TCF data collection — safe to set before SDK start
    _logger.logCalling('enableTCFDataCollection');
    _sdk.enableTCFDataCollection(true);
    _logger.log('enableTCFDataCollection', 'shouldCollect=true');

    // Consent data (GDPR example — adjust for your jurisdiction)
    _logger.logCalling('setConsentDataV2');
    _sdk.setConsentDataV2(
      isUserSubjectToGDPR: false,
    );
    _logger.log('setConsentDataV2', 'isUserSubjectToGDPR=false (non-GDPR demo)');

    // Disable advertising identifiers (privacy-safe default for demo)
    _logger.logCalling('setDisableAdvertisingIdentifiers');
    _sdk.setDisableAdvertisingIdentifiers(false);
    _logger.log('setDisableAdvertisingIdentifiers',
        'disabled=false (identifiers enabled for demo)');

    // Android-only pre-start settings
    if (Platform.isAndroid) {
      _logger.logCalling('setCollectIMEI (Android)');
      _sdk.setCollectIMEI(false);
      _logger.log('setCollectIMEI', 'isCollect=false');

      _logger.logCalling('setCollectAndroidId (Android)');
      _sdk.setCollectAndroidId(false);
      _logger.log('setCollectAndroidId', 'isCollect=false');

      _logger.logCalling('performOnDeepLinking (Android)');
      _sdk.performOnDeepLinking();
      _logger.log('performOnDeepLinking', 'called');
    }

    // iOS-only pre-start settings
    if (Platform.isIOS) {
      _logger.logCalling('disableSKAdNetwork (iOS)');
      _sdk.disableSKAdNetwork(false);
      _logger.log('disableSKAdNetwork', 'isDisabled=false (SKAdNetwork active)');
    }

    _logger.log('AUTO_APIS', '--- Pre-start auto APIs complete ---');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auto APIs: run after startSDK success
  // These require the SDK to be started before they are meaningful.
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _runAutoApisPostStart() async {
    _logger.log('AUTO_APIS', '--- Running post-start auto APIs ---');

    // getSDKVersion
    _logger.logCalling('getSDKVersion');
    try {
      final version = await _sdk.getSDKVersion();
      _logger.logResult('getSDKVersion', version);
    } catch (e) {
      _logger.logError('getSDKVersion', e);
    }

    // getAppsFlyerUID
    _logger.logCalling('getAppsFlyerUID');
    try {
      final uid = await _sdk.getAppsFlyerUID();
      _logger.logResult('getAppsFlyerUID', uid);
    } catch (e) {
      _logger.logError('getAppsFlyerUID', e);
    }

    // getHostName
    _logger.logCalling('getHostName');
    try {
      final host = await _sdk.getHostName();
      _logger.logResult('getHostName', host);
    } catch (e) {
      _logger.logError('getHostName', e);
    }

    // getHostPrefix
    _logger.logCalling('getHostPrefix');
    try {
      final prefix = await _sdk.getHostPrefix();
      _logger.logResult('getHostPrefix', prefix);
    } catch (e) {
      _logger.logError('getHostPrefix', e);
    }

    // Log a launch event to verify event channel is working
    _logger.logCalling('logEvent(af_demo_launch)');
    try {
      final result = await _sdk.logEvent('af_demo_launch', {
        'platform': Platform.operatingSystem,
        'plugin_version': _sdk.getVersionNumber(),
      });
      _logger.logResult('logEvent(af_demo_launch)', result);
    } catch (e) {
      _logger.logError('logEvent(af_demo_launch)', e);
    }

    // af_purchase event — required by QA
    _logger.logCalling('logEvent: af_purchase sent');
    try {
      final result = await _sdk.logEvent('af_purchase', {
        'af_content_id': 'auto_product_001',
        'af_currency': 'USD',
        'af_revenue': 9.99,
        'af_quantity': 1,
        'source': 'auto_on_launch',
      });
      _logger.logResult('logEvent: af_purchase sent', result);
    } catch (e) {
      _logger.logError('logEvent: af_purchase sent', e);
    }

    // af_content_view event — required by QA
    _logger.logCalling('logEvent: af_content_view sent');
    try {
      final result = await _sdk.logEvent('af_content_view', {
        'af_content_id': 'auto_content_001',
        'af_content_type': 'demo_page',
        'af_currency': 'USD',
        'source': 'auto_on_launch',
      });
      _logger.logResult('logEvent: af_content_view sent', result);
    } catch (e) {
      _logger.logError('logEvent: af_content_view sent', e);
    }

    // setCustomerUserId
    _logger.logCalling('setCustomerUserId');
    _sdk.setCustomerUserId('qa_auto_customer_001');
    _logger.log('setCustomerUserId', 'id=qa_auto_customer_001');

    // anonymizeUser
    _logger.logCalling('anonymizeUser');
    _sdk.anonymizeUser(false);
    _logger.log('anonymizeUser', 'shouldAnonymize=false');

    // setAdditionalData
    _logger.logCalling('setAdditionalData');
    _sdk.setAdditionalData({'qa_key': 'qa_value', 'auto_run': 'true'});
    _logger.log('setAdditionalData', 'customData={qa_key:qa_value, auto_run:true}');

    // setSharingFilterForPartners (replaces deprecated setSharingFilterForAllPartners)
    _logger.logCalling('setSharingFilterForPartners');
    _sdk.setSharingFilterForPartners(['demo_partner']);
    _logger.log('setSharingFilterForPartners', 'partners=[demo_partner]');

    // Android-specific
    if (Platform.isAndroid) {
      _logger.logCalling('updateServerUninstallToken (Android)');
      _sdk.updateServerUninstallToken('QA_AUTO_FCM_TOKEN_PLACEHOLDER');
      _logger.log('updateServerUninstallToken', 'token=QA_AUTO_FCM_TOKEN_PLACEHOLDER');
    }

    // Android-only post-start
    if (Platform.isAndroid) {
      _logger.logCalling('getOutOfStore (Android)');
      try {
        final source = await _sdk.getOutOfStore();
        _logger.logResult('getOutOfStore', source);
      } catch (e) {
        _logger.logError('getOutOfStore', e);
      }
    }

    _logger.log('AUTO_APIS', '--- Post-start auto APIs complete ---');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Masks a key so it is not fully visible in logs.
  String _mask(String key) {
    if (key.length <= 4) return '****';
    return '${key.substring(0, 4)}****';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_sdkReady) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              Text(
                _initStatus,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AfDemoPage(sdk: _sdk);
  }
}
