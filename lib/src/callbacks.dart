import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

const _channel = MethodChannel('callbacks');

typedef MultiUseCallback = void Function(dynamic msg);
typedef CancelListening = void Function();

Map<String, MultiUseCallback> _callbacksById = <String, void Function(dynamic)> {};

Future<void> _methodCallHandler(MethodCall call) async {
  switch (call.method) {
    case 'callListener':
      try {
        dynamic callMap = jsonDecode(call.arguments);
        switch (callMap["id"]) {
          case "onAppOpenAttribution":
          case "onInstallConversionData":
          case "onDeepLinking":
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
          default:
            _callbacksById[callMap["id"]]!(callMap["data"]);
            break;
        }
      } on Exception catch (e) {
        print(e);
      }
      break;
    default:
      print('Ignoring invoke from native. This normally shouldn\'t happen.');
  }
}

Future<CancelListening> startListening(
    MultiUseCallback callback, String callbackName) async {
  _channel.setMethodCallHandler(_methodCallHandler);

  _callbacksById[callbackName] = callback;

  await _channel.invokeMethod("startListening", callbackName);

  return () {
    _channel.invokeMethod("cancelListening", callbackName);
    _callbacksById.remove(callbackName);
  };
}
