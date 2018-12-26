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
  static Stream<dynamic> afStream;
  static StreamController afGCDStreamController;
  static StreamController afOpenAttributionStreamController;

  static Stream<dynamic> registerConversionDataCallback() {
    afGCDStreamController = StreamController();
    return afGCDStreamController.stream;
  }

  static Stream<dynamic> registerOnAppOpenAttributionCallback() {
    afOpenAttributionStreamController = StreamController();
    return afOpenAttributionStreamController.stream;
  }

  static Future<dynamic> initSdk(Map options) async {
    Map<String, dynamic> afOptions = {};
    //validations
    dynamic devKey = options[AppsflyerConstants.AF_DEV_KEY];

    if (devKey != null) {
      //Check that the dev key is a valid number
      if (devKey is String) {
        afOptions[AppsflyerConstants.AF_DEV_KEY] = devKey;
      }
    } else {
      throw Exception("Expected a dev key");
    }

    if (Platform.isIOS) {
      dynamic appID = options[AppsflyerConstants.AF_APP_Id];
      if (appID != null) {
        if (!(appID is String)) {
          throw Exception("App id suppose to be a string");
        }
        RegExp exp = RegExp(r'^\d{8,11}$');
        if (exp.hasMatch(appID)) {
          afOptions[AppsflyerConstants.AF_APP_Id] = appID;
        } else {
          throw Exception(
              "App id (iTunes) need to be a number, for example '123456789'");
        }
      } else {
        throw Exception("Expected an app id");
      }
    }

    afOptions[AppsflyerConstants.AF_IS_DEBUG] =
        options.containsKey(AppsflyerConstants.AF_IS_DEBUG)
            ? options[AppsflyerConstants.AF_IS_DEBUG]
            : false;

    if (afGCDStreamController != null) {
      afOptions[AppsflyerConstants.AF_GCD] = true;
      registerListener();
    } else {
      afOptions[AppsflyerConstants.AF_GCD] = false;
    }

    return await _channel.invokeMethod("initSdk", afOptions);
  }

  static Future<bool> trackEvent(String eventName, Map eventValues) async {
    if (eventValues == null) {
      throw Exception("Event value can't be null");
    }

    return await _channel.invokeMethod(
        "trackEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  static void registerListener() {
    BinaryMessages.setMessageHandler(AppsflyerConstants.AF_EVENTS_CHANNEL,
        (ByteData message) async {
      final buffer = message.buffer;
      final decodedStr = utf8.decode(buffer.asUint8List());
      var decodedJSON = jsonDecode(decodedStr);

      String type = decodedJSON['type'];
      switch (type) {
        case AppsflyerConstants.AF_GET_CONVERSION_DATA:
          afGCDStreamController.sink.add(decodedJSON);
          break;
        case AppsflyerConstants.AF_ON_APP_OPEN_ATTRIBUTION:
          afOpenAttributionStreamController.sink.add(decodedJSON);
          break;
        default:
      }

      return null;
    });
  }
}
