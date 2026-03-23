import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';

import 'af_demo_logger.dart';

/// The main demo page.
///
/// Responsibilities:
///   - Display live in-app log output (mirrors [AF_DEMO] lines from [AfDemoLogger]).
///   - Display the latest conversion data and deep-link payloads received via callbacks.
///   - Provide clearly labelled buttons for every Manual API.
///
/// All logging uses [AfDemoLogger] so the same messages appear in both the
/// in-app panel and Android logcat / iOS simulator logs.
class AfDemoPage extends StatefulWidget {
  final AppsflyerSdk sdk;

  const AfDemoPage({Key? key, required this.sdk}) : super(key: key);

  @override
  State<AfDemoPage> createState() => _AfDemoPageState();
}

class _AfDemoPageState extends State<AfDemoPage> {
  final AfDemoLogger _logger = AfDemoLogger();

  // Latest callback payloads shown in the UI
  String _conversionDataPayload = 'Waiting for conversion data...';
  String _appOpenAttributionPayload = 'Waiting for app open attribution...';
  String _deepLinkPayload = 'Waiting for deep link result...';

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onLogUpdate);
    _wireCallbacks();
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogUpdate);
    super.dispose();
  }

  void _onLogUpdate() {
    if (mounted) setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Callback wiring  (callbacks were registered in main_page.dart initSdk —
  // we re-register here so the UI panel is populated too)
  // ─────────────────────────────────────────────────────────────────────────

  void _wireCallbacks() {
    widget.sdk.onInstallConversionData((res) {
      _logger.logCallback('onInstallConversionData', res);
      if (mounted) {
        setState(() {
          _conversionDataPayload = res.toString();
        });
      }
    });

    widget.sdk.onAppOpenAttribution((res) {
      _logger.logCallback('onAppOpenAttribution', res);
      if (mounted) {
        setState(() {
          _appOpenAttributionPayload = res.toString();
        });
      }
    });

    widget.sdk.onDeepLinking((DeepLinkResult dp) {
      _logger.logCallback('onDeepLinking',
          'status=${dp.status} deepLinkValue=${dp.deepLink?.deepLinkValue} error=${dp.error}');
      if (mounted) {
        setState(() {
          _deepLinkPayload = dp.toString();
        });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Manual API implementations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _getAppsFlyerUID() async {
    _logger.logCalling('getAppsFlyerUID');
    try {
      final uid = await widget.sdk.getAppsFlyerUID();
      _logger.logResult('getAppsFlyerUID', uid);
    } catch (e) {
      _logger.logError('getAppsFlyerUID', e);
    }
  }

  Future<void> _getSDKVersion() async {
    _logger.logCalling('getSDKVersion');
    try {
      final version = await widget.sdk.getSDKVersion();
      _logger.logResult('getSDKVersion', version);
    } catch (e) {
      _logger.logError('getSDKVersion', e);
    }
  }

  void _getVersionNumber() {
    _logger.logCalling('getVersionNumber');
    final version = widget.sdk.getVersionNumber();
    _logger.logResult('getVersionNumber', version);
  }

  Future<void> _getHostName() async {
    _logger.logCalling('getHostName');
    try {
      final host = await widget.sdk.getHostName();
      _logger.logResult('getHostName', host);
    } catch (e) {
      _logger.logError('getHostName', e);
    }
  }

  Future<void> _getHostPrefix() async {
    _logger.logCalling('getHostPrefix');
    try {
      final prefix = await widget.sdk.getHostPrefix();
      _logger.logResult('getHostPrefix', prefix);
    } catch (e) {
      _logger.logError('getHostPrefix', e);
    }
  }

  Future<void> _getOutOfStore() async {
    _logger.logCalling('getOutOfStore');
    try {
      final source = await widget.sdk.getOutOfStore();
      _logger.logResult('getOutOfStore', source);
    } catch (e) {
      _logger.logError('getOutOfStore', e);
    }
  }

  Future<void> _logPurchaseEvent() async {
    const method = 'logEvent';
    _logger.logCalling(method);
    try {
      final result = await widget.sdk.logEvent('af_purchase', {
        'af_content_id': 'demo_product_001',
        'af_currency': 'USD',
        'af_revenue': 9.99,
        'af_quantity': 1,
      });
      _logger.logResult(method, result);
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  Future<void> _logCustomEvent() async {
    const method = 'logEvent(custom)';
    _logger.logCalling(method);
    try {
      final result = await widget.sdk.logEvent('af_demo_custom_event', {
        'demo_param_1': 'value_1',
        'demo_param_2': 42,
      });
      _logger.logResult(method, result);
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _logAdRevenue() {
    const method = 'logAdRevenue';
    _logger.logCalling(method);
    try {
      final adRevenueData = AdRevenueData(
        monetizationNetwork: 'demo_network',
        mediationNetwork: AFMediationNetwork.applovinMax.value,
        currencyIso4217Code: 'USD',
        revenue: 0.05,
        additionalParameters: {
          'ad_unit': 'demo_banner',
          'placement': 'main_screen',
        },
      );
      widget.sdk.logAdRevenue(adRevenueData);
      _logger.log(method, 'dispatched (fire-and-forget)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setCustomerUserId() {
    const method = 'setCustomerUserId';
    _logger.logCalling(method);
    try {
      widget.sdk.setCustomerUserId('demo_customer_id_12345');
      _logger.log(method, 'set to: demo_customer_id_12345');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setCurrencyCode() {
    const method = 'setCurrencyCode';
    _logger.logCalling(method);
    try {
      widget.sdk.setCurrencyCode('EUR');
      _logger.log(method, 'set to: EUR');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setUserEmails() {
    const method = 'setUserEmails';
    _logger.logCalling(method);
    try {
      widget.sdk.setUserEmails(
        ['demo@example.com', 'test@example.com'],
        EmailCryptType.EmailCryptTypeSHA256,
      );
      _logger.log(method,
          'set 2 emails with SHA256 encryption');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setAdditionalData() {
    const method = 'setAdditionalData';
    _logger.logCalling(method);
    try {
      widget.sdk.setAdditionalData({
        'demo_key_1': 'demo_value_1',
        'demo_key_2': 'demo_value_2',
      });
      _logger.log(method, 'custom data map dispatched');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setHost() {
    const method = 'setHost';
    _logger.logCalling(method);
    try {
      // Reset to default AppsFlyer host as a safe demo value
      widget.sdk.setHost('', 'appsflyer.com');
      _logger.log(method, 'hostPrefix="" hostName="appsflyer.com"');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setMinTimeBetweenSessions() {
    const method = 'setMinTimeBetweenSessions';
    _logger.logCalling(method);
    try {
      widget.sdk.setMinTimeBetweenSessions(5);
      _logger.log(method, 'set to 5 seconds');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setSharingFilterForPartners() {
    const method = 'setSharingFilterForPartners';
    _logger.logCalling(method);
    try {
      widget.sdk.setSharingFilterForPartners(['demo_partner']);
      _logger.log(method, 'filter set for: [demo_partner]');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setOneLinkCustomDomain() {
    const method = 'setOneLinkCustomDomain';
    _logger.logCalling(method);
    try {
      widget.sdk.setOneLinkCustomDomain(['demo.yourdomain.com']);
      _logger.log(method, 'set to: [demo.yourdomain.com]');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setResolveDeepLinkURLs() {
    const method = 'setResolveDeepLinkURLs';
    _logger.logCalling(method);
    try {
      widget.sdk.setResolveDeepLinkURLs(['yourdomain.com']);
      _logger.log(method, 'set to: [yourdomain.com]');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setPartnerData() {
    const method = 'setPartnerData';
    _logger.logCalling(method);
    try {
      widget.sdk.setPartnerData('demo_partner_id', {
        'demo_partner_key': 'demo_partner_value',
      });
      _logger.log(method, 'partnerId=demo_partner_id data set');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _enableTCFDataCollection() {
    const method = 'enableTCFDataCollection';
    _logger.logCalling(method);
    try {
      widget.sdk.enableTCFDataCollection(true);
      _logger.log(method, 'enabled=true');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setConsentDataV2GDPR() {
    const method = 'setConsentDataV2(GDPR)';
    _logger.logCalling(method);
    try {
      widget.sdk.setConsentDataV2(
        isUserSubjectToGDPR: true,
        consentForDataUsage: true,
        consentForAdsPersonalization: true,
        hasConsentForAdStorage: true,
      );
      _logger.log(method,
          'GDPR=true dataUsage=true adsPersonalization=true adStorage=true');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setConsentDataV2NonGDPR() {
    const method = 'setConsentDataV2(non-GDPR)';
    _logger.logCalling(method);
    try {
      widget.sdk.setConsentDataV2(
        isUserSubjectToGDPR: false,
      );
      _logger.log(method, 'GDPR=false (non-GDPR user)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _anonymizeUser() {
    const method = 'anonymizeUser';
    _logger.logCalling(method);
    try {
      widget.sdk.anonymizeUser(true);
      _logger.log(method, 'shouldAnonymize=true — WARNING: re-enable after demo');
      // Re-enable after a short delay so the demo app remains functional
      Future.delayed(const Duration(seconds: 3), () {
        widget.sdk.anonymizeUser(false);
        _logger.log(method, 'shouldAnonymize=false — restored after 3s demo');
      });
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _stopSDK() {
    const method = 'stop';
    _logger.logCalling(method);
    try {
      widget.sdk.stop(true);
      _logger.log(method,
          'SDK stopped — WARNING: re-enabling after 3s for demo purposes');
      Future.delayed(const Duration(seconds: 3), () {
        widget.sdk.stop(false);
        _logger.log(method, 'SDK re-enabled after 3s demo');
      });
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setIsUpdate() {
    const method = 'setIsUpdate';
    _logger.logCalling(method);
    try {
      widget.sdk.setIsUpdate(true);
      _logger.log(method, 'isUpdate=true');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setDisableNetworkData() {
    const method = 'setDisableNetworkData';
    _logger.logCalling(method);
    try {
      widget.sdk.setDisableNetworkData(false);
      _logger.log(method, 'disable=false (network data enabled)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _addPushNotificationDeepLinkPath() {
    const method = 'addPushNotificationDeepLinkPath';
    _logger.logCalling(method);
    try {
      widget.sdk.addPushNotificationDeepLinkPath(['af', 'deeplink']);
      _logger.log(method, 'path=["af","deeplink"]');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _generateInviteLink() {
    const method = 'generateInviteLink';
    _logger.logCalling(method);
    try {
      final params = AppsFlyerInviteLinkParams(
        channel: 'demo_channel',
        campaign: 'demo_campaign',
        referrerName: 'Demo User',
        customParams: {'promo_code': 'DEMO2024'},
      );
      widget.sdk.generateInviteLink(
        params,
        (result) {
          _logger.logCallback('generateInviteLinkSuccess', result);
        },
        (error) {
          _logger.logCallback('generateInviteLinkFailure', error);
        },
      );
      _logger.log(method, 'link generation requested');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _logCrossPromotionImpression() {
    const method = 'logCrossPromotionImpression';
    _logger.logCalling(method);
    try {
      widget.sdk.logCrossPromotionImpression(
        'YOUR_PROMOTED_APP_ID',
        'demo_cross_promo_campaign',
        {'custom_key': 'custom_value'},
      );
      _logger.log(method, 'appId=YOUR_PROMOTED_APP_ID dispatched');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _sendPushNotificationData() {
    const method = 'sendPushNotificationData';
    _logger.logCalling(method);
    try {
      widget.sdk.sendPushNotificationData({
        'af': {'link': 'https://yourdomain.com/demo'},
      });
      _logger.log(method, 'mock push payload dispatched');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  // ── Android-only ──────────────────────────────────────────────────────────

  void _setCollectIMEI() {
    const method = 'setCollectIMEI (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.setCollectIMEI(false);
      _logger.log(method, 'isCollect=false');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setCollectAndroidId() {
    const method = 'setCollectAndroidId (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.setCollectAndroidId(false);
      _logger.log(method, 'isCollect=false');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setAndroidIdData() {
    const method = 'setAndroidIdData (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.setAndroidIdData('demo_android_id_00000000');
      _logger.log(method, 'androidId=demo_android_id_00000000');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _disableAppSetId() {
    const method = 'disableAppSetId (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.disableAppSetId();
      _logger.log(method, 'AppSet ID collection disabled');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setOutOfStore() {
    const method = 'setOutOfStore (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.setOutOfStore('amazon');
      _logger.log(method, 'sourceName=amazon');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setImeiData() {
    const method = 'setImeiData (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.setImeiData('000000000000000');
      _logger.log(method, 'imei=000000000000000 (placeholder)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _updateServerUninstallToken() {
    const method = 'updateServerUninstallToken (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.updateServerUninstallToken('DEMO_FCM_TOKEN_PLACEHOLDER');
      _logger.log(method, 'token=DEMO_FCM_TOKEN_PLACEHOLDER (placeholder)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  // ── iOS-only ──────────────────────────────────────────────────────────────

  void _disableSKAdNetwork() {
    const method = 'disableSKAdNetwork (iOS only)';
    if (!Platform.isIOS) {
      _logger.log(method, 'skipped — Android platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.disableSKAdNetwork(false);
      _logger.log(method, 'isDisabled=false (SKAdNetwork enabled)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _useReceiptValidationSandbox() {
    const method = 'useReceiptValidationSandbox (iOS only)';
    if (!Platform.isIOS) {
      _logger.log(method, 'skipped — Android platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.useReceiptValidationSandbox(true);
      _logger.log(method, 'sandbox=true');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setDisableAdvertisingIdentifiers() {
    const method = 'setDisableAdvertisingIdentifiers';
    _logger.logCalling(method);
    try {
      widget.sdk.setDisableAdvertisingIdentifiers(false);
      _logger.log(method, 'disabled=false (advertising identifiers enabled)');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _enableFacebookDeferredApplinks() {
    const method = 'enableFacebookDeferredApplinks';
    _logger.logCalling(method);
    try {
      widget.sdk.enableFacebookDeferredApplinks(false);
      _logger.log(method, 'isEnabled=false');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _setCurrentDeviceLanguage() {
    const method = 'setCurrentDeviceLanguage';
    _logger.logCalling(method);
    try {
      widget.sdk.setCurrentDeviceLanguage('en');
      _logger.log(method, 'language=en');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  Future<void> _validateAndLogInAppPurchaseV2() async {
    const method = 'validateAndLogInAppPurchaseV2';
    _logger.logCalling(method);
    try {
      final purchaseDetails = AFPurchaseDetails(
        purchaseType: AFPurchaseType.oneTimePurchase,
        purchaseToken: 'DEMO_PURCHASE_TOKEN_PLACEHOLDER',
        productId: 'com.example.demo_product',
      );
      final result = await widget.sdk.validateAndLogInAppPurchaseV2(
        purchaseDetails,
        additionalParameters: {
          'validation_source': 'af_demo_app',
          'environment': 'demo',
        },
      );
      _logger.logResult(method, result);
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _performOnDeepLinking() {
    const method = 'performOnDeepLinking (Android only)';
    if (!Platform.isAndroid) {
      _logger.log(method, 'skipped — iOS platform');
      return;
    }
    _logger.logCalling(method);
    try {
      widget.sdk.performOnDeepLinking();
      _logger.log(method, 'called');
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  void _waitForCustomerUserId() {
    const method = 'waitForCustomerUserId';
    _logger.logCalling(method);
    try {
      // Demonstrate the API — immediately unlock with setCustomerIdAndLogSession
      widget.sdk.waitForCustomerUserId(true);
      _logger.log(method, 'wait=true — will unlock with setCustomerIdAndLogSession');
      Future.delayed(const Duration(seconds: 1), () {
        widget.sdk.setCustomerIdAndLogSession('demo_cuid_session_001');
        _logger.log('setCustomerIdAndLogSession',
            'id=demo_cuid_session_001 — session unlocked');
      });
    } catch (e) {
      _logger.logError(method, e);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AppsFlyer SDK Demo'),
          centerTitle: true,
          backgroundColor: Colors.green,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'API BUTTONS'),
              Tab(text: 'LIVE LOGS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildApiButtonsTab(),
            _buildLogTab(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: API Buttons
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildApiButtonsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _sectionCard('CALLBACKS (auto-wired on launch)', [
          _infoTile('onInstallConversionData', _conversionDataPayload),
          _infoTile('onAppOpenAttribution', _appOpenAttributionPayload),
          _infoTile('onDeepLinking', _deepLinkPayload),
        ]),

        _sectionCard('GETTERS', [
          _apiButton('getAppsFlyerUID', _getAppsFlyerUID),
          _apiButton('getSDKVersion', _getSDKVersion),
          _apiButton('getVersionNumber (plugin)', _getVersionNumber),
          _apiButton('getHostName', _getHostName),
          _apiButton('getHostPrefix', _getHostPrefix),
          _apiButton('getOutOfStore', _getOutOfStore),
        ]),

        _sectionCard('EVENT LOGGING', [
          _apiButton('logEvent — af_purchase', _logPurchaseEvent),
          _apiButton('logEvent — custom event', _logCustomEvent),
          _apiButton('logAdRevenue', _logAdRevenue),
        ]),

        _sectionCard('USER & SESSION', [
          _apiButton('setCustomerUserId', _setCustomerUserId),
          _apiButton('setCurrencyCode', _setCurrencyCode),
          _apiButton('setUserEmails (SHA256)', _setUserEmails),
          _apiButton('setAdditionalData', _setAdditionalData),
          _apiButton('setCurrentDeviceLanguage', _setCurrentDeviceLanguage),
          _apiButton('setIsUpdate', _setIsUpdate),
          _apiButton(
              'waitForCustomerUserId + setCustomerIdAndLogSession',
              _waitForCustomerUserId),
        ]),

        _sectionCard('SDK CONFIGURATION', [
          _apiButton('setHost', _setHost),
          _apiButton('setMinTimeBetweenSessions', _setMinTimeBetweenSessions),
          _apiButton('setSharingFilterForPartners', _setSharingFilterForPartners),
          _apiButton('setOneLinkCustomDomain', _setOneLinkCustomDomain),
          _apiButton('setResolveDeepLinkURLs', _setResolveDeepLinkURLs),
          _apiButton('setPartnerData', _setPartnerData),
          _apiButton('enableTCFDataCollection', _enableTCFDataCollection),
          _apiButton('setConsentDataV2 (GDPR user)', _setConsentDataV2GDPR),
          _apiButton('setConsentDataV2 (non-GDPR user)', _setConsentDataV2NonGDPR),
          _apiButton('setDisableNetworkData', _setDisableNetworkData),
          _apiButton('setDisableAdvertisingIdentifiers',
              _setDisableAdvertisingIdentifiers),
          _apiButton(
              'enableFacebookDeferredApplinks', _enableFacebookDeferredApplinks),
          _apiButton('addPushNotificationDeepLinkPath',
              _addPushNotificationDeepLinkPath),
        ]),

        _sectionCard(
            'PRIVACY / STOP (temporary — auto-restores after 3s)', [
          _apiButton('anonymizeUser (temp)', _anonymizeUser,
              color: Colors.orange),
          _apiButton('stop SDK (temp)', _stopSDK, color: Colors.orange),
        ]),

        _sectionCard('DEEP LINK & ATTRIBUTION', [
          _apiButton('sendPushNotificationData', _sendPushNotificationData),
          _apiButton('generateInviteLink', _generateInviteLink),
          _apiButton('logCrossPromotionImpression', _logCrossPromotionImpression),
        ]),

        _sectionCard(
            'PURCHASE VALIDATION\n(requires real purchase token — will fail gracefully)',
            [
              _apiButton('validateAndLogInAppPurchaseV2',
                  _validateAndLogInAppPurchaseV2),
            ]),

        _sectionCard('ANDROID ONLY', [
          _apiButton('setCollectIMEI', _setCollectIMEI),
          _apiButton('setCollectAndroidId', _setCollectAndroidId),
          _apiButton('setAndroidIdData', _setAndroidIdData),
          _apiButton('disableAppSetId', _disableAppSetId),
          _apiButton('setOutOfStore', _setOutOfStore),
          _apiButton('setImeiData', _setImeiData),
          _apiButton('updateServerUninstallToken (FCM)', _updateServerUninstallToken),
          _apiButton('performOnDeepLinking', _performOnDeepLinking),
        ]),

        _sectionCard('IOS ONLY', [
          _apiButton('disableSKAdNetwork', _disableSKAdNetwork),
          _apiButton('useReceiptValidationSandbox', _useReceiptValidationSandbox),
        ]),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _apiButton(String label, VoidCallback onPressed,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.green.shade700,
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: Live Logs
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLogTab() {
    final logs = List<String>.from(_logger.lines.reversed);
    return Column(
      children: [
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text('${_logger.lines.length} entries',
                  style: const TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _logger.clear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(
                  child: Text(
                    'No logs yet.\nTap buttons on the API BUTTONS tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (_, i) {
                    final line = logs[i];
                    Color bg = Colors.white;
                    if (line.contains('error:')) bg = Colors.red.shade50;
                    if (line.contains('[CALLBACK]')) bg = Colors.blue.shade50;
                    if (line.contains('calling...')) bg = Colors.green.shade50;
                    return Container(
                      color: bg,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
