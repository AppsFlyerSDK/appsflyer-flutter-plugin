part of appsflyer_sdk;

class AppsflyerSdk {
  StreamController _afGCDStreamController;
  StreamController _afOpenAttributionStreamController;
  StreamController _afValidtaPurchaseController;
  final eventChannel = EventChannel(AppsflyerConstants.AF_EVENTS_CHANNEL);
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
      _registerGCDListener();
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
      _registerGCDListener();
    } else {
      afOptions[AppsflyerConstants.AF_GCD] = false;
    }

    return afOptions;
  }

  ///Returns `Stream`. Accessing AppsFlyer Conversion Data from the SDK
  Stream<dynamic> registerConversionDataCallback() {
    if (_afGCDStreamController == null) {
      _afGCDStreamController = StreamController(onCancel: () {
        _afGCDStreamController.close();
      });
    }
    return _afGCDStreamController.stream;
  }

  ///Returns `Stream`. Accessing AppsFlyer attribution, referred from deep linking
  Stream<dynamic> registerOnAppOpenAttributionCallback() {
    if (_afOpenAttributionStreamController == null) {
      _afOpenAttributionStreamController = StreamController(onCancel: () {
        _afOpenAttributionStreamController.close();
      });
    }
    return _afOpenAttributionStreamController.stream;
  }

  ///Returns `Stream`. Accessing AppsFlyer purchase validation data
  Stream<dynamic> _registerValidatePurchaseCallback() {
    if (_afValidtaPurchaseController == null) {
      _afValidtaPurchaseController = StreamController(onCancel: () {
        _afValidtaPurchaseController.close();
      });

      _registerPurchaseValidateListener();
    }
    return _afValidtaPurchaseController.stream;
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

  void setHost(String hostPrefix, String hostName) {
    _methodChannel.invokeMethod(
        "setHost", {'hostPrefix': hostPrefix, 'hostName': hostName});
  }

  void setCollectIMEI(bool isCollect) {
    _methodChannel.invokeMethod("setCollectIMEI", {'isCollect': isCollect});
  }

  void setCollectAndroidId(bool isCollect) {
    _methodChannel
        .invokeMethod("setCollectAndroidId", {'isCollect': isCollect});
  }

  Future<String> getHostName() async {
    return await _methodChannel.invokeMethod("getHostName");
  }

  Future<String> getHostPrefix() async {
    return await _methodChannel.invokeMethod("getHostPrefix");
  }

  void setAndroidIdData(String androidId) {
    _methodChannel.invokeMethod("setAndroidIdData", {'androidId': androidId});
  }

  void setMinTimeBetweenSessions(int seconds) {
    assert(seconds >= 0, "the minimum timeout must be a positive number");
    _methodChannel
        .invokeMethod("setMinTimeBetweenSessions", {'seconds': seconds});
  }

  void setImeiData(String imei) {
    _methodChannel.invokeMethod("setImeiData", {'imei': imei});
  }

  void setCurrencyCode(String currencyCode) {
    _methodChannel
        .invokeMethod("setCurrencyCode", {'currencyCode': currencyCode});
  }

  void setCustomerUserId(String id) {
    _methodChannel.invokeMethod("setCustomerUserId", {'id': id});
  }

  void setIsUpdate(bool isUpdate) {
    _methodChannel.invokeMethod("setIsUpdate", {'isUpdate': isUpdate});
  }

  void stopTracking(bool isTrackingStopped) {
    _methodChannel
        .invokeMethod("stopTracking", {'isTrackingStopped': isTrackingStopped});
  }

  void enableLocationCollection(bool flag) {
    _methodChannel.invokeMethod("enableLocationCollection", {'flag': flag});
  }

  void enableUninstallTracking(String senderId) {
    _methodChannel
        .invokeMethod("enableUninstallTracking", {'senderId': senderId});
  }

  void updateServerUninstallToken(String token) {
    _methodChannel.invokeMethod("updateServerUninstallToken", {'token': token});
  }

  void setUserEmails(List<String> emails, [EmailCryptType cryptType]) {
    if (cryptType != null) {
      int cryptTypeInt = EmailCryptType.values.indexOf(cryptType);
      _methodChannel.invokeMethod("setUserEmailsWithCryptType",
          {'emails': emails, 'cryptType': cryptTypeInt});
    } else {
      _methodChannel.invokeMethod("setUserEmails", {'emails': emails});
    }
  }

  Future<String> getAppsFlyerUID() async {
    return await _methodChannel.invokeMethod("getAppsFlyerUID");
  }

  void waitForCustomerUserId(bool wait) {
    _methodChannel.invokeMethod("waitForCustomerUserId", {'wait': wait});
  }

  ///Returns `Stream`. Accessing AppsFlyer purchase validation data
  Stream<dynamic> validateAndTrackInAppPurchase(
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String> additionalParameters) {
    _methodChannel.invokeMethod("validateAndTrackInAppPurchase", {
      'publicKey': publicKey,
      'signature': signature,
      'purchaseData': purchaseData,
      'price': price,
      'currency': currency,
      'additionalParameters': additionalParameters
    });
    return _registerValidatePurchaseCallback();
  }

  void setAdditionalData(Map<String, dynamic> customData) {
    _methodChannel
        .invokeMethod("setAdditionalData", {'customData': customData});
  }

  void _registerGCDListener() {
    eventChannel.receiveBroadcastStream().listen((data) {
      var decodedJSON = jsonDecode(data);
      String type = decodedJSON['type'];
      switch (type) {
        case AppsflyerConstants.AF_GET_CONVERSION_DATA:
          _afGCDStreamController.sink.add(decodedJSON);
          break;
        case AppsflyerConstants.AF_ON_APP_OPEN_ATTRIBUTION:
          _afOpenAttributionStreamController.sink.add(decodedJSON);
          break;
      }
    });
  }

  void _registerPurchaseValidateListener() {
    eventChannel.receiveBroadcastStream().listen((data) {
      var decodedJSON = jsonDecode(data);
      String type = decodedJSON['type'];
      if (type == AppsflyerConstants.AF_VALIDATE_PURCHASE) {
        _afValidtaPurchaseController.sink.add(decodedJSON);
      }
    });
  }
}
