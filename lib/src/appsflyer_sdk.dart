part of appsflyer_sdk;

class AppsflyerSdk {
  // ignore: close_sinks
  StreamController? _afGCDStreamController;
  // ignore: close_sinks
  StreamController? _afUDLStreamController;
  // ignore: close_sinks
  StreamController? _afOpenAttributionStreamController;
  // ignore: close_sinks
  StreamController? _afValidtaPurchaseController;
  EventChannel _eventChannel;
  static AppsflyerSdk? _instance;
  final MethodChannel _methodChannel;

  AppsFlyerOptions? afOptions;
  Map? mapOptions;

  ///Returns the [AppsflyerSdk] instance, initialized with a custom options
  ///provided by the user
  factory AppsflyerSdk(options) {
    if (_instance == null) {
      final methodChannel =
          const MethodChannel(AppsflyerConstants.afMethodChannel);

      final eventChannel = EventChannel(AppsflyerConstants.afEventsChannel);

      //check if the option variable is AFOptions type or map type
      assert(options is AppsFlyerOptions || options is Map);
      if (options is AppsFlyerOptions) {
        _instance = AppsflyerSdk.private(methodChannel, eventChannel,
            afOptions: options);
      } else if (options is Map) {
        _instance = AppsflyerSdk.private(methodChannel, eventChannel,
            mapOptions: options);
      }
    }
    return _instance!;
  }

  @visibleForTesting
  AppsflyerSdk.private(this._methodChannel, this._eventChannel,
      {this.afOptions, this.mapOptions});

  Map<String, dynamic> _validateAFOptions(AppsFlyerOptions options) {
    final validatedOptions = <String, dynamic>{};

    //validations
    final devKey = options.afDevKey;
    assert(devKey is String);

    validatedOptions[AppsflyerConstants.afDevKey] = devKey;

    final appInviteOneLink = options.appInviteOneLink;
    if (appInviteOneLink != null) {
      assert(appInviteOneLink is String);
    }

    validatedOptions[AppsflyerConstants.afInviteOneLink] = appInviteOneLink;

    if (options.disableCollectASA != null) {
      validatedOptions[AppsflyerConstants.disableCollectASA] =
          options.disableCollectASA;
    }

    if (options.disableAdvertisingIdentifier != null) {
      validatedOptions[AppsflyerConstants.disableAdvertisingIdentifier] =
          options.disableAdvertisingIdentifier;
    }

    if (Platform.isIOS) {
      final appID = options.appId;
      assert(appID is String);
      final exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      validatedOptions[AppsflyerConstants.afAppId] = appID;
    }

    validatedOptions[AppsflyerConstants.afIsDebug] =
        // ignore: unnecessary_null_comparison
        (options.showDebug != null) ? options.showDebug : false;

    if (_afGCDStreamController != null ||
        _afOpenAttributionStreamController != null) {
      validatedOptions[AppsflyerConstants.afGCD] = true;
    } else {
      validatedOptions[AppsflyerConstants.afGCD] = false;
    }

    if (_afUDLStreamController != null) {
      validatedOptions[AppsflyerConstants.afUDL] = true;
    } else {
      validatedOptions[AppsflyerConstants.afUDL] = false;
    }
    return validatedOptions;
  }

  Map<String, dynamic> _validateMapOptions(Map options) {
    final afOptions = <String, dynamic>{};
    //validations
    final devKey = options[AppsflyerConstants.afDevKey];
    assert(devKey != null);
    assert(devKey is String);

    afOptions[AppsflyerConstants.afDevKey] = devKey;

    final appInviteOneLink = options[AppsflyerConstants.afInviteOneLink];
    if (appInviteOneLink != null) {
      assert(appInviteOneLink is String);
    }

    afOptions[AppsflyerConstants.afInviteOneLink] = appInviteOneLink;

    if (options[AppsflyerConstants.disableCollectASA] != null) {
      afOptions[AppsflyerConstants.disableCollectASA] =
          options[AppsflyerConstants.disableCollectASA];
    }

    if (options[AppsflyerConstants.disableAdvertisingIdentifier] != null) {
      afOptions[AppsflyerConstants.disableAdvertisingIdentifier] =
          options[AppsflyerConstants.disableAdvertisingIdentifier];
    }

    if (Platform.isIOS) {
      if (options[AppsflyerConstants.afTimeToWaitForAttUserAuthorization] !=
          null) {
        final timeToWaitForATTUserAuthorization =
            options[AppsflyerConstants.afTimeToWaitForAttUserAuthorization];
        assert(timeToWaitForATTUserAuthorization is double);

        afOptions[AppsflyerConstants.afTimeToWaitForAttUserAuthorization] =
            timeToWaitForATTUserAuthorization;
      }

      final appID = options[AppsflyerConstants.afAppId];
      assert(appID != null, "appleAppId is required for iOS apps");
      assert(appID is String);
      final exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      afOptions[AppsflyerConstants.afAppId] = appID;
    }

    afOptions[AppsflyerConstants.afIsDebug] =
        options.containsKey(AppsflyerConstants.afIsDebug)
            ? options[AppsflyerConstants.afIsDebug]
            : false;

    if (_afGCDStreamController != null ||
        _afOpenAttributionStreamController != null) {
      afOptions[AppsflyerConstants.afGCD] = true;
    } else {
      afOptions[AppsflyerConstants.afGCD] = false;
    }

    if (_afUDLStreamController != null) {
      afOptions[AppsflyerConstants.afUDL] = true;
    } else {
      afOptions[AppsflyerConstants.afUDL] = false;
    }

    return afOptions;
  }

  // Accessing AppsFlyer Conversion Data from the SDK
  void _registerConversionDataCallback() {
    if (_afGCDStreamController == null) {
      _afGCDStreamController = StreamController<Map>(onCancel: () {
        _afGCDStreamController!.close();
      });
    }
  }

  Stream<Map>? get conversionDataStream {
    return _afGCDStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  // Accessing AppsFlyer attribution, referred from deep linking
  void _registerOnAppOpenAttributionCallback() {
    if (_afOpenAttributionStreamController == null) {
      _afOpenAttributionStreamController = StreamController<Map>(onCancel: () {
        _afOpenAttributionStreamController!.close();
      });
    }
  }

  Stream<Map>? get appOpenAttributionStream {
    return _afOpenAttributionStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  // Unified deeplink: Accessing AppsFlyer deeplink attributes
  void _registerUDLCallback() {
    if (_afUDLStreamController == null) {
      _afUDLStreamController = StreamController<Map>(onCancel: () {
        _afUDLStreamController!.close();
      });
      _registerUDLListener();
    }
  }

  Stream<Map>? get onDeepLinkingStream {
    return _afUDLStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  ///Returns `Stream`. Accessing AppsFlyer purchase validation data
  // ignore: unused_element
  Stream<dynamic> _registerValidatePurchaseStream() {
    if (_afValidtaPurchaseController == null) {
      _afValidtaPurchaseController = StreamController(onCancel: () {
        _afValidtaPurchaseController!.close();
      });

      _registerPurchaseValidateListener();
    }
    return _afValidtaPurchaseController!.stream;
  }

  ///initialize the SDK, using the options initialized from the constructor|
  Future<dynamic> initSdk(
      {bool registerConversionDataCallback = false,
      bool registerOnAppOpenAttributionCallback = false,
      bool registerOnDeepLinkingCallback = false}) async {
    return Future.delayed(Duration(seconds: 0)).then((_) {
      if (registerConversionDataCallback) _registerConversionDataCallback();
      if (registerOnAppOpenAttributionCallback) {
        _registerOnAppOpenAttributionCallback();
      }

      if (registerConversionDataCallback ||
          registerOnAppOpenAttributionCallback) {
        _registerGCDListener();
      }

      if (registerOnDeepLinkingCallback) {
        _registerUDLCallback();
      }

      Map<String, dynamic>? validatedOptions;
      if (mapOptions != null) {
        validatedOptions = _validateMapOptions(mapOptions!);
      } else if (afOptions != null) {
        validatedOptions = _validateAFOptions(afOptions!);
      }

      return _methodChannel.invokeMethod("initSdk", validatedOptions);
    });
  }

  Future<String?> getSDKVersion() async {
    return _methodChannel.invokeMethod("getSDKVersion");
  }

  ///These in-app events help you to log how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to send ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool?> logEvent(String eventName, Map eventValues) async {
    // ignore: unnecessary_null_comparison
    assert(eventValues != null);

    return _methodChannel.invokeMethod(
        "logEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  void setHost(String hostPrefix, String hostName) {
    _methodChannel.invokeMethod(
        "setHost", {'hostPrefix': hostPrefix, 'hostName': hostName});
  }

  /// Opt-out of collection of IMEI.
  /// If the app does NOT contain Google Play Services, device IMEI is collected by the SDK.
  /// However, apps with Google play services should avoid IMEI collection as this is in violation of the Google Play policy.
  void setCollectIMEI({required bool isCollect}) {
    _methodChannel.invokeMethod("setCollectIMEI", {'isCollect': isCollect});
  }

  /// Opt-out of collection of Android ID.
  /// If the app does NOT contain Google Play Services, Android ID is collected by the SDK.
  /// However, apps with Google play services should avoid Android ID collection as this is in violation of the Google Play policy.
  void setCollectAndroidId({required bool isCollect}) {
    _methodChannel
        .invokeMethod("setCollectAndroidId", {'isCollect': isCollect});
  }

  Future<String?> getHostName() async {
    return _methodChannel.invokeMethod("getHostName");
  }

  Future<String?> getHostPrefix() async {
    return _methodChannel.invokeMethod("getHostPrefix");
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

  /// Setting user local currency code for in-app purchases.
  /// The currency code should be a 3 character ISO 4217 code. (default is USD).
  /// You can set the currency code for all events by calling the following method.
  void setCurrencyCode(String currencyCode) {
    _methodChannel
        .invokeMethod("setCurrencyCode", {'currencyCode': currencyCode});
  }

  /// Setting your own customer ID enables you to cross-reference your own unique ID with AppsFlyer’s unique ID and the other devices’ IDs.
  /// This ID is available in AppsFlyer CSV reports along with Postback APIs for cross-referencing with your internal IDs.
  void setCustomerUserId(String id) {
    _methodChannel.invokeMethod("setCustomerUserId", {'id': id});
  }

  void setIsUpdate({required bool isUpdate}) {
    _methodChannel.invokeMethod("setIsUpdate", {'isUpdate': isUpdate});
  }

  /// Once this API is invoked, our SDK no longer communicates with our servers and stops functioning.
  /// In some extreme cases you might want to shut down all SDK activity due to legal and privacy compliance.
  /// This can be achieved with the stop API.
  void stop({required bool isStopped}) {
    _methodChannel.invokeMethod("stop", {'isStopped': isStopped});
  }

  void enableLocationCollection({required bool flag}) {
    _methodChannel.invokeMethod("enableLocationCollection", {'flag': flag});
  }

  ///Please use updateServerUninstallToken instead
  @deprecated
  void enableUninstallTracking(String senderId) {
    print("Please use updateServerUninstallToken instead");
  }

  ///Manually pass the Firebase / GCM Device Token for Uninstall measurement.
  void updateServerUninstallToken(String token) {
    _methodChannel.invokeMethod("updateServerUninstallToken", {'token': token});
  }

  ///Set the user emails and encrypt them.
  void setUserEmails(List<String> emails, [EmailCryptType? cryptType]) {
    if (cryptType != null) {
      final cryptTypeInt = EmailCryptType.values.indexOf(cryptType);
      _methodChannel.invokeMethod("setUserEmailsWithCryptType",
          {'emails': emails, 'cryptType': cryptTypeInt});
    } else {
      _methodChannel.invokeMethod("setUserEmails", {'emails': emails});
    }
  }

  ///Get AppsFlyer's unique device ID is created for every new install of an app.
  Future<String?> getAppsFlyerUID() async {
    return _methodChannel.invokeMethod("getAppsFlyerUID");
  }

  ///Set to true if you want to delay sdk init until CUID is set
  void waitForCustomerUserId({required bool wait}) {
    _methodChannel.invokeMethod("waitForCustomerUserId", {'wait': wait});
  }

  Future<dynamic> validateAndLogInAppAndroidPurchase(
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String>? additionalParameters) {
    return _methodChannel.invokeMethod("validateAndLogInAppAndroidPurchase", {
      'publicKey': publicKey,
      'signature': signature,
      'purchaseData': purchaseData,
      'price': price,
      'currency': currency,
      'additionalParameters': additionalParameters
    });
  }

  ///Accessing AppsFlyer purchase validation data
  Future<dynamic> validateAndLogInAppIosPurchase(
      String productIdentifier,
      String price,
      String currency,
      String transactionId,
      Map<String, String> additionalParameters) async {
    return _methodChannel.invokeMethod("validateAndLogInAppIosPurchase", {
      'productIdentifier': productIdentifier,
      'price': price,
      'currency': currency,
      'transactionId': transactionId,
      'additionalParameters': additionalParameters
    });
  }

  /// set sandbox for iOS purchase validation
  void useReceiptValidationSandbox({required bool isSandboxEnabled}) {
    _methodChannel.invokeMethod(
        "useReceiptValidationSandbox", isSandboxEnabled);
  }

  /// Set additional data to be sent to AppsFlyer.
  void setAdditionalData(Map<String, dynamic>? customData) {
    _methodChannel
        .invokeMethod("setAdditionalData", {'customData': customData});
  }

  void _registerUDLListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data as String);
      final String? type = decodedJSON['type'];
      if (type == AppsflyerConstants.afOnDeepLink) {
        if (_afUDLStreamController != null &&
            !_afUDLStreamController!.isClosed) {
          _afUDLStreamController!.sink.add(decodedJSON);
        } else {
          if ((afOptions != null && afOptions!.showDebug) ||
              (mapOptions != null &&
                  mapOptions![AppsflyerConstants.afIsDebug])) {
            print("UDL Stream controller is closed. the event wasn't sent");
          }
        }
      }
    });
  }

  void _registerGCDListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data);
      final String? type = decodedJSON['type'];
      switch (type) {
        case AppsflyerConstants.afGetConversionData:
          if (_afGCDStreamController != null &&
              !_afGCDStreamController!.isClosed) {
            _afGCDStreamController!.sink.add(decodedJSON);
          } else {
            if ((afOptions != null && afOptions!.showDebug) ||
                (mapOptions != null &&
                    mapOptions![AppsflyerConstants.afIsDebug])) {
              print("GCD Stream controller is closed. the event wasn't sent");
            }
          }
          break;
        case AppsflyerConstants.afOnAppOpenAttribution:
          if (_afOpenAttributionStreamController != null &&
              !_afOpenAttributionStreamController!.isClosed) {
            _afOpenAttributionStreamController!.sink.add(decodedJSON);
          } else {
            if ((afOptions != null && afOptions!.showDebug) ||
                (mapOptions != null &&
                    mapOptions![AppsflyerConstants.afIsDebug])) {
              print(
                  "OnAppOpenAttribution stream is closed. the event wasn't sent");
            }
          }
          break;
      }
    });
  }

  void _registerPurchaseValidateListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data);
      final String? type = decodedJSON['type'];
      if (type == AppsflyerConstants.afValidatePurchase) {
        _afValidtaPurchaseController!.sink.add(decodedJSON);
      }
    });
  }

  ///The sharing filter blocks the sharing of S2S events via postbacks/API with integrated partners and other third-party integrations.
  ///Use the filter to fulfill regulatory requirements like GDPR and CCPA, to comply with user opt-out mechanisms, and for other business logic reasons.
  void setSharingFilter(List<String> filters) {
    _methodChannel.invokeMethod("setSharingFilter", filters);
  }

  void setSharingFilterForAllPartners() {
    _methodChannel.invokeMethod("setSharingFilterForAllPartners");
  }

  void generateInviteLink(
    AppsFlyerInviteLinkParams? parameters,
    Function success,
    Function error,
  ) {
    Map<String, String?>? paramsMap;
    if (parameters != null) {
      paramsMap = _translateInviteLinkParamsToMap(parameters);
    }
    startListening(
        success as void Function(dynamic), "generateInviteLinkSuccess");
    startListening(
        error as void Function(dynamic), "generateInviteLinkFailure");
    _methodChannel.invokeMethod("generateInviteLink", paramsMap);
  }

  Map<String, String?> _translateInviteLinkParamsToMap(
      AppsFlyerInviteLinkParams params) {
    final inviteLinkParamsMap = <String, String?>{};
    inviteLinkParamsMap['referrerImageUrl'] = params.referreImageUrl;
    inviteLinkParamsMap['customerID'] = params.customerID;
    inviteLinkParamsMap['brandDomain'] = params.brandDomain;
    inviteLinkParamsMap['baseDeeplink'] = params.baseDeepLink;
    inviteLinkParamsMap['referrerName'] = params.referrerName;
    inviteLinkParamsMap['channel'] = params.channel;
    inviteLinkParamsMap['campaign'] = params.campaign;

    return inviteLinkParamsMap;
  }

  ///Set the OneLink ID that should be used for User-Invite-API.
  ///The link that is generated for the user invite will use this OneLink ID as the base link ID
  Future<void> setAppInviteOneLinkID(
      String oneLinkID, Function callback) async {
    startListening(
        callback as void Function(dynamic), "setAppInviteOneLinkIDCallback");
    await _methodChannel.invokeMethod("setAppInviteOneLinkID", {
      'oneLinkID': oneLinkID,
    });
  }

  ///To attribute an impression use the following API call.
  ///Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
  void logCrossPromotionImpression(String appId, String campaign, Map? data) {
    _methodChannel.invokeMethod("logCrossPromotionImpression",
        {'appId': appId, 'campaign': campaign, 'data': data});
  }

  ///Use the following API to attribute the click and launch the app store's app page.
  void logCrossPromotionAndOpenStore(
      String appId, String campaign, Map? params) {
    _methodChannel.invokeMethod("logCrossPromotionAndOpenStore", {
      'appId': appId,
      'campaign': campaign,
      'params': params,
    });
  }

  void setOneLinkCustomDomain(List<String> brandDomains) {
    _methodChannel.invokeMethod("setOneLinkCustomDomain", brandDomains);
  }

  void setPushNotification({required bool isEnabled}) {
    _methodChannel.invokeMethod("setPushNotification", isEnabled);
  }

  void enableFacebookDeferredApplinks({required bool isEnabled}) {
    _methodChannel.invokeMethod("enableFacebookDeferredApplinks",
        {'isFacebookDeferredApplinksEnabled': isEnabled});
  }

  void disableSKAdNetwork({required bool isEnabled}) {
    _methodChannel.invokeMethod("disableSKAdNetwork", isEnabled);
  }

  void onInstallConversionData(Function callback) async {
    startListening(
        callback as void Function(dynamic), "onInstallConversionData");
  }

  void onAppOpenAttribution(Function callback) async {
    startListening(callback as void Function(dynamic), "onAppOpenAttribution");
  }

  void onDeepLinking(Function callback) async {
    startListening(callback as void Function(dynamic), "onDeepLinking");
  }

  void onPurchaseValidation(Function callback) async {
    startListening(callback as void Function(dynamic), "validatePurchase");
  }
}
