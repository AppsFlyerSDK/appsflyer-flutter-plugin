import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../appsflyer_sdk.dart';
import 'platform_enums.dart';

typedef ResponseCallback = void Function(AppsFlyerResponse response);
typedef CancelListening = void Function();

class Callbacks {
  static const statusKey = 'status', dataKey = 'data', deepLinkKey = 'deepLink';
  static const _channel = MethodChannel('callbacks');
  final Map<PlatformResponse, ResponseCallback> callbacksByResponse =
      <PlatformResponse, ResponseCallback>{};

  String _unwrapJson({
    required String argumentData,
    required String unwrapKey,
  }) {
    return jsonDecode(argumentData)[unwrapKey];
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'callListener':
        try {
          final Map<String, dynamic> argumentMap = jsonDecode(call.arguments);
          // Convert to enum or throw error
          final platformResponse =
              (argumentMap["id"] as String).toPlatformResponse();
          final argumentData = argumentMap[dataKey];

          switch (platformResponse) {
            case PlatformResponse.onAppOpenAttribution:
              _handleKnownResponse(
                platformResponse: platformResponse,
                argumentMap: argumentMap,
              );
              break;
            case PlatformResponse.onInstallConversionData:
              _handleKnownResponse(
                platformResponse: platformResponse,
                argumentMap: argumentMap,
              );
              break;
            case PlatformResponse.onDeepLinking:
              final payload = _unwrapJson(
                unwrapKey: deepLinkKey,
                argumentData: argumentData,
              );

              final response = AppsFlyerData(
                status: argumentMap[statusKey],
                payload: jsonDecode(payload),
              );

              _handleCallback(
                platformResponse: platformResponse,
                response: response,
              );
              break;
            case PlatformResponse.validatePurchase:
              _handleKnownResponse(
                platformResponse: platformResponse,
                argumentMap: argumentMap,
              );
              break;
            case PlatformResponse.generateInviteLinkSuccess:
              _handleKnownResponse(
                platformResponse: platformResponse,
                argumentMap: argumentMap,
              );
              break;
            default:
              _handleCallback(
                platformResponse: platformResponse,
                response: AppsFlyerUnknown(argumentData),
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

  void _handleKnownResponse({
    required PlatformResponse platformResponse,
    required Map<String, dynamic> argumentMap,
  }) {
    assert(argumentMap.containsKey(statusKey));
    assert(argumentMap.containsKey(dataKey));

    final response = AppsFlyerData(
      status: argumentMap[statusKey],
      payload: jsonDecode(argumentMap[dataKey]),
    );

    _handleCallback(
      platformResponse: platformResponse,
      response: response,
    );
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
