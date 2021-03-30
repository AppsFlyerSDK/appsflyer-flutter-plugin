import 'dart:async';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppsFlyerService extends ChangeNotifier {
  // full app restart required when changing static variables
  static const brandDomain = 'sub.domain.com';
  static const urlPrefix = 'https://$brandDomain';

  final Completer _sdkInitialized = Completer();

  AppsflyerSdk sdk;
  AppInstallResponse appInstallResponse;
  DeepLinkResponse deepLinkData;

  Future get initializer => _sdkInitialized.future;

  Future<void> initialize() async {
    // Set these values in the .env file
    final dotEnv = DotEnv();
    final devKey = dotEnv.env['DEV_KEY'];
    final appKey = Platform.isIOS ? 'IOS_APP_ID' : 'ANDROID_APP_ID';
    final appId = dotEnv.env[appKey];

    final options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: appId,
      showDebug: true,
    );

    sdk = AppsflyerSdk(options)
      ..onInstallConversionData(_handleInstallConversion)
      ..onAppOpenAttribution(_handleDeepLink)
      ..onDeepLinking(_handleDeepLink);

    _sdkInitialized.complete();
  }

  void dispose() {
    sdk?.dispose();
    super.dispose();
  }

  void _handleInstallConversion(AppsFlyerResponse response) {
    debugPrint('Install conversion response: $response');

    final appInstallResponse = response.map(_toAppInstallResponse);

    this.appInstallResponse = appInstallResponse;
    notifyListeners();
  }

  void _handleDeepLink(AppsFlyerResponse response) {
    debugPrint('Deep link response: $response');

    final deepLinkData = response.map(_toDeepLinkResponse);

    this.deepLinkData = deepLinkData;
    notifyListeners();
  }

  AppInstallResponse _toAppInstallResponse(json) {
    // Note: `json` can be null
    if (json != null) return AppInstallResponse.fromJson(json);

    return null;
  }

  DeepLinkResponse _toDeepLinkResponse(json) {
    // Note: `json` can be null
    if (json != null) return DeepLinkResponse.fromJson(json);

    return null;
  }

  Future<AppsFlyerResponse> generateInviteLinkAsync(
      AppsFlyerInviteLinkParams params) {
    final completer = Completer<AppsFlyerResponse>();

    sdk.generateInviteLink(
      params,
      onSuccess: (link) {
        debugPrint('success: $link');
        completer.complete(link);
      },
      onError: (error) {
        debugPrint('failure: $error');
        completer.completeError(error);
      },
    );

    return completer.future;
  }
}

class DeepLinkResponse with Diagnosticable {
  final OneLinkBase base;
  // Add your custom attributes below here
  final String product; // example attribute
  final String branch; // example attribute

  DeepLinkResponse._({
    @required this.base,
    @required this.product,
    @required this.branch,
  });

  /// Convert JSON data to a [DeepLinkResponse]
  static DeepLinkResponse fromJson(Map<String, dynamic> json) {
    try {
      final base = OneLinkBase.fromJson(json);
      // Your custom attributes
      final product = json['product'];
      final branch = json['branch'];

      final result = DeepLinkResponse._(
        base: base,
        product: product,
        branch: branch,
      );

      debugPrint('$DeepLinkResponse created! $result');

      return result;
    } catch (e) {
      debugPrint('$DeepLinkResponse creation failed: $e');
    }

    return null;
  }

  /// Prints the information below when [toString] is called
  ///
  /// Extremely helpful for debugging
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message('$base'));
    // Your custom attributes
    properties.add(DiagnosticsNode.message('product: $product'));
    properties.add(DiagnosticsNode.message('branch: $branch'));
  }
}
