import 'dart:io';
import 'package:flutter/services.dart';
import 'appsflyer_constants.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:core';

class AppsflyerSdk {
  MethodChannel channel =
      const MethodChannel(AppsflyerConstants.AF_METHOD_CHANNEL);
  StreamController _afGCDStreamController;
  StreamController _afOpenAttributionStreamController;
  Map<String, dynamic> _afOptions;

  ///Returns the [AppsflyerSdk] instance, initialized with a custom options
  ///provided by the user
  AppsflyerSdk(Map options) {
    _afOptions = _validateOptions(options);
  }

  Map<String, dynamic> _validateOptions(Map options) {
    Map<String, dynamic> afOptions = {};
    //validations
    dynamic devKey = options[AppsflyerConstants.AF_DEV_KEY];
    assert(devKey != null);
    assert(devKey is String);

    afOptions[AppsflyerConstants.AF_DEV_KEY] = devKey;

    if (Platform.isIOS) {
      dynamic appID = options[AppsflyerConstants.AF_APP_Id];
      assert(appID != null, "appleAppId is required for iOS apps");
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

    return afOptions;
  }

  ///Returns `Stream`. Accessing AppsFlyer Conversion Data from the SDK
  Stream<dynamic> registerConversionDataCallback() {
    _afGCDStreamController = StreamController();
    return _afGCDStreamController.stream;
  }

  ///Returns `Stream`. Accessing AppsFlyer attribution, referred from deep linking
  Stream<dynamic> registerOnAppOpenAttributionCallback() {
    _afOpenAttributionStreamController = StreamController();
    return _afOpenAttributionStreamController.stream;
  }

  ///initialize the SDK, using the options initialized from the constructor|
  Future<dynamic> initSdk() async {
    return channel.invokeMethod("initSdk", _afOptions);
  }

  ///These in-app events help you track how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to track ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool> trackEvent(String eventName, Map eventValues) async {
    assert(eventValues != null);

    return await channel.invokeMethod(
        "trackEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  void _registerListener() {
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
