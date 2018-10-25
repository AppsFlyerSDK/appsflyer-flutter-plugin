import 'dart:async';

import 'package:flutter/services.dart';

class AppsflyerSdk {
  static const MethodChannel _channel =
      const MethodChannel('appsflyer_sdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
