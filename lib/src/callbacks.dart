import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:appsflyer_sdk/src/platform_enums.dart';

typedef ResponseCallback = void Function(AppsFlyerResponse response);
typedef CancelListening = void Function();

class Callbacks {
  static const _channel = const MethodChannel('callbacks');
  final Map<PlatformResponse, ResponseCallback> callbacksByResponse =
      <PlatformResponse, ResponseCallback>{};

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'callListener':
        try {
          Map<String, dynamic> argumentMap = jsonDecode(call.arguments);
          // Convert to enum or throw error
          final platformResponse = (argumentMap["id"] as String).toEnum();

          switch (platformResponse) {
            case PlatformResponse.onAppOpenAttribution:
            case PlatformResponse.onInstallConversionData:
            case PlatformResponse.onDeepLinking:
            case PlatformResponse.validatePurchase:
            case PlatformResponse.generateInviteLinkSuccess:
              final String data = argumentMap["data"];
              final AppsFlyerData response = AppsFlyerData(
                status: argumentMap['status'],
                payload: jsonDecode(data),
              );

              _handleCallback(
                platformResponse: platformResponse,
                response: response,
              );
              break;
            default:
              _handleCallback(
                platformResponse: platformResponse,
                response: AppsFlyerUnknown(argumentMap["data"]),
              );
              break;
          }
        } catch (e) {
          print(e);
        }
        break;
      default:
        print("Ignoring invoke from native. This normally shouldn't happen.");
    }
  }

  void _handleCallback({
    required PlatformResponse platformResponse,
    required AppsFlyerResponse response,
  }) {
    if (callbacksByResponse.containsKey(platformResponse)) {
      final methodCallback = callbacksByResponse[platformResponse]!;

      methodCallback(response);
    }
  }

  Future<CancelListening> startListening<T>({
    required ResponseCallback responseCallback,
    required PlatformResponse platformResponse,
  }) async {
    _channel.setMethodCallHandler(_methodCallHandler);

    callbacksByResponse[platformResponse] = responseCallback;

    await _channel.invokeMethod("startListening", platformResponse.asString());

    return () {
      _channel.invokeMethod("cancelListening", platformResponse.asString());
      callbacksByResponse.remove(platformResponse);
    };
  }
}
