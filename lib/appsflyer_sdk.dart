import 'dart:io';
import 'package:flutter/services.dart';
import 'appsflyer_constants.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:core';

class AppsflyerSdk {
  static const MethodChannel _channel =
      const MethodChannel(AppsflyerConstants.AF_METHOD_CHANNEL);

  static StreamController _afGCDStreamController;
  static StreamController _afOpenAttributionStreamController;

  static Stream<dynamic> registerConversionDataCallback() {
    _afGCDStreamController = StreamController();
    return _afGCDStreamController.stream;
  }

  static Stream<dynamic> registerOnAppOpenAttributionCallback() {
    _afOpenAttributionStreamController = StreamController();
    return _afOpenAttributionStreamController.stream;
  }

  static Future<dynamic> initSdk(Map options) async {
    Map<String, dynamic> afOptions = {};
    //validations
    dynamic devKey = options[AppsflyerConstants.AF_DEV_KEY];
    assert(devKey != null);
    assert(devKey is String);

    afOptions[AppsflyerConstants.AF_DEV_KEY] = devKey;

    if (Platform.isIOS) {
      dynamic appID = options[AppsflyerConstants.AF_APP_Id];
      assert(appID != null);
      assert(appID is String);
      RegExp exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      afOptions[AppsflyerConstants.AF_APP_Id] = appID;
    }

    afOptions[AppsflyerConstants.AF_IS_DEBUG] =
        options.containsKey(AppsflyerConstants.AF_IS_DEBUG)
            ? options[AppsflyerConstants.AF_IS_DEBUG]
            : false;

    if (_afGCDStreamController != null) {
      afOptions[AppsflyerConstants.AF_GCD] = true;
      _registerListener();
    } else {
      afOptions[AppsflyerConstants.AF_GCD] = false;
    }

    return await _channel.invokeMethod("initSdk", afOptions);
  }

  static Future<bool> trackEvent(String eventName, Map eventValues) async {
    assert(eventValues != null);

    return await _channel.invokeMethod(
        "trackEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  static void _registerListener() {
    BinaryMessages.setMessageHandler(AppsflyerConstants.AF_EVENTS_CHANNEL,
        (ByteData message) async {
      final buffer = message.buffer;
      final decodedStr = utf8.decode(buffer.asUint8List());
      var decodedJSON = jsonDecode(decodedStr);

      String type = decodedJSON['type'];
      switch (type) {
        case AppsflyerConstants.AF_GET_CONVERSION_DATA:
          _afGCDStreamController.sink.add(decodedJSON);
          break;
        case AppsflyerConstants.AF_ON_APP_OPEN_ATTRIBUTION:
          _afOpenAttributionStreamController.sink.add(decodedJSON);
          break;
        default:
      }

      return null;
    });
  }
}
