import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../appsflyer_sdk.dart';

const _channel = MethodChannel('callbacks');

typedef MultiUseCallback = void Function(dynamic msg);
typedef UDLCallback = void Function(DeepLinkResult deepLinkResult);
typedef CancelListening = void Function();

Map<String, MultiUseCallback> _callbacksById = <String, void Function(dynamic)>{
};
UDLCallback? _udlCallback;

Future<void> _methodCallHandler(MethodCall call) async {
  switch (call.method) {
    case 'callListener':
      try {
        dynamic callMap = jsonDecode(call.arguments);
        switch (callMap["id"]) {
          case "onAppOpenAttribution":
          case "onInstallConversionData":
          case "validatePurchase":
          case "generateInviteLinkSuccess":
            String data = callMap["data"];
            Map? decodedData = jsonDecode(data);
            Map fullResponse = {
              "status": callMap['status'],
              "payload": decodedData
            };
            _callbacksById[callMap["id"]]!(fullResponse);
            break;
          case "onDeepLinking":
            Error? error = (callMap["deepLinkError"] as String?)
                ?.errorFromString();
            Status? status = (callMap["deepLinkStatus"] as String?)
                ?.statusFromString() ?? Status.PARSE_ERROR;
            Map<String, dynamic>? map = callMap["deepLinkObj"] as Map<
                String,
                dynamic>?;
            DeepLink? deepLink = map != null ? DeepLink(map) : null;
            var dp = DeepLinkResult(error, deepLink, status);
            if (_udlCallback != null) {
              _udlCallback!(dp);
            }
            break;
          default:
            _callbacksById[callMap["id"]]!(callMap["data"]);
            break;
        }
      } on Exception catch (e) {
        print("Exception $e");
      }
      break;
    default:
      print('Ignoring invoke from native. This normally shouldn\'t happen.');
  }
}

Future<CancelListening> startListening(MultiUseCallback callback,
    String callbackName) async {
  _channel.setMethodCallHandler(_methodCallHandler);

  _callbacksById[callbackName] = callback;

  await _channel.invokeMethod("startListening", callbackName);

  return () {
    _channel.invokeMethod("cancelListening", callbackName);
    _callbacksById.remove(callbackName);
  };
}

Future<CancelListening> startListeningToUDL(UDLCallback callback,
    String callbackName) async {
  _channel.setMethodCallHandler(_methodCallHandler);

  _udlCallback = callback;

  await _channel.invokeMethod("startListening", callbackName);

  return () {
    _channel.invokeMethod("cancelListening", callbackName);
    _callbacksById.remove(callbackName);
  };
}
