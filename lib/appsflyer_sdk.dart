import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppsflyerSdk {
  static const MethodChannel _channel = const MethodChannel('appsflyer_sdk');

  static void initSdk(String afDevKey) {
    _channel.invokeMethod("initSdk", {'afDevKey': afDevKey});
  }

  static void trackEvent(String eventName, eventValues) {
    _channel.invokeMethod(
        "trackEvent", {'eventName': eventName, 'eventValues': eventValues});
  }
}
