import 'dart:async';
import 'package:flutter/services.dart';

const _channel = const MethodChannel('callbacks');

typedef void MultiUseCallback(dynamic msg);
typedef void CancelListening();

Map<String, MultiUseCallback> _callbacksById = new Map();

Future<void> _methodCallHandler(MethodCall call) async {
  switch (call.method) {
    case 'callListener':
      _callbacksById[call.arguments["id"]](call.arguments["data"]);
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
