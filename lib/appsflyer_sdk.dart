import 'package:flutter/services.dart';
import 'appsflyer_constants.dart';
import 'package:flutter/material.dart';

class AppsflyerSdk {
  static const MethodChannel _channel = const MethodChannel('appsflyer_sdk');

  static Future<dynamic> initSdk(
      {@required String afDevKey, String iOSAppId}) async {
    var afSettings = {
      appsflyer_constants.AF_DEV_KEY: afDevKey,
    };

    if (iOSAppId != null) {
      afSettings[appsflyer_constants.AF_APP_KEY] = iOSAppId;
    }

    print('afSettings: ${afSettings}');
    var result = await _channel.invokeMethod("initSdk", afSettings);
    return result;
  }

  static void trackEvent(String eventName, eventValues) {
    _channel.invokeMethod(
        "trackEvent", {'eventName': eventName, 'eventValues': eventValues});
  }
}
