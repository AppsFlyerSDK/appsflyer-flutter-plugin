part of appsflyer_sdk;

class AppsflyerSdk {
  StreamController _afGCDStreamController;
  StreamController _afOpenAttributionStreamController;
  static AppsflyerSdk _instance;
  final MethodChannel _methodChannel;

  AppsFlyerOptions afOptions;
  Map mapOptions;

  ///Returns the [AppsflyerSdk] instance, initialized with a custom options
  ///provided by the user
  factory AppsflyerSdk(options) {
    if (_instance == null) {
      MethodChannel methodChannel =
          const MethodChannel(AppsflyerConstants.AF_METHOD_CHANNEL);

      //check if the option variable is AFOptions type or map type
      if (options is AppsFlyerOptions) {
        _instance = AppsflyerSdk.private(methodChannel, afOptions: options);
      } else if (options is Map) {
        _instance = AppsflyerSdk.private(methodChannel, mapOptions: options);
      }
    }
    return _instance;
  }

  @visibleForTesting
  AppsflyerSdk.private(this._methodChannel, {this.afOptions, this.mapOptions});

  Map<String, dynamic> _validateAFOptions(AppsFlyerOptions options) {
    Map<String, dynamic> validatedOptions = {};
    //validations
    dynamic devKey = options.afDevKey;
    assert(devKey != null);
    assert(devKey is String);

    validatedOptions[AppsflyerConstants.AF_DEV_KEY] = devKey;

    if (Platform.isIOS) {
      dynamic appID = options.appId;
      assert(appID != null, "appleAppId is required for iOS apps");
      assert(appID is String);
      RegExp exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      validatedOptions[AppsflyerConstants.AF_APP_Id] = appID;
    }

    validatedOptions[AppsflyerConstants.AF_IS_DEBUG] =
        (options.showDebug != null) ? options.showDebug : false;

    if (_afGCDStreamController != null) {
      validatedOptions[AppsflyerConstants.AF_GCD] = true;
      _registerListener();
    } else {
      validatedOptions[AppsflyerConstants.AF_GCD] = false;
    }

    return validatedOptions;
  }

  Map<String, dynamic> _validateMapOptions(Map options) {
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
    Map<String, dynamic> validatedOptions;
    if (mapOptions != null) {
      validatedOptions = _validateMapOptions(mapOptions);
    } else if (afOptions != null) {
      validatedOptions = _validateAFOptions(afOptions);
    }

    return _methodChannel.invokeMethod("initSdk", validatedOptions);
  }

  ///These in-app events help you track how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to track ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `trackEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool> trackEvent(String eventName, Map eventValues) async {
    assert(eventValues != null);

    return await _methodChannel.invokeMethod(
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
