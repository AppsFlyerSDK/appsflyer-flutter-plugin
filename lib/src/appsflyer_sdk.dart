part of appsflyer_sdk;

class AppsflyerSdk {
  StreamController _afGCDStreamController;
  StreamController _afUDLStreamController;
  StreamController _afOpenAttributionStreamController;
  StreamController _afValidtaPurchaseController;
  EventChannel _eventChannel;
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

      EventChannel eventChannel =
          EventChannel(AppsflyerConstants.AF_EVENTS_CHANNEL);

      //check if the option variable is AFOptions type or map type
      if (options is AppsFlyerOptions) {
        _instance = AppsflyerSdk.private(methodChannel, eventChannel,
            afOptions: options);
      } else if (options is Map) {
        _instance = AppsflyerSdk.private(methodChannel, eventChannel,
            mapOptions: options);
      }
    }
    return _instance;
  }

  @visibleForTesting
  AppsflyerSdk.private(this._methodChannel, this._eventChannel,
      {this.afOptions, this.mapOptions});

  Map<String, dynamic> _validateAFOptions(AppsFlyerOptions options) {
    Map<String, dynamic> validatedOptions = {};

    //validations
    dynamic devKey = options.afDevKey;
    assert(devKey != null);
    assert(devKey is String);

    validatedOptions[AppsflyerConstants.AF_DEV_KEY] = devKey;

    dynamic appInviteOneLink = options.appInviteOneLink;
    if (appInviteOneLink != null) {
      assert(appInviteOneLink is String);
    }

    validatedOptions[AppsflyerConstants.APP_INVITE_ONE_LINK] = appInviteOneLink;

    if (options.disableCollectASA != null) {
      validatedOptions[AppsflyerConstants.DISABLE_COLLECT_ASA] =
          options.disableCollectASA;
    }

    if (options.disableAdvertisingIdentifier != null) {
      validatedOptions[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] =
          options.disableAdvertisingIdentifier;
    }

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

    if (_afGCDStreamController != null ||
        _afOpenAttributionStreamController != null) {
      validatedOptions[AppsflyerConstants.AF_GCD] = true;
    } else {
      validatedOptions[AppsflyerConstants.AF_GCD] = false;
    }

    if (_afUDLStreamController != null ) {
      validatedOptions[AppsflyerConstants.AF_UDL] = true;
    } else {
      validatedOptions[AppsflyerConstants.AF_UDL] = false;
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

    dynamic appInviteOneLink = options[AppsflyerConstants.APP_INVITE_ONE_LINK];
    if (appInviteOneLink != null) {
      assert(appInviteOneLink is String);
    }

    afOptions[AppsflyerConstants.APP_INVITE_ONE_LINK] = appInviteOneLink;

    if (options[AppsflyerConstants.DISABLE_COLLECT_ASA] != null) {
      afOptions[AppsflyerConstants.DISABLE_COLLECT_ASA] =
          options[AppsflyerConstants.DISABLE_COLLECT_ASA];
    }

    if (options[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] != null) {
      afOptions[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] =
          options[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER];
    }

    if (Platform.isIOS) {
      if (options[
              AppsflyerConstants.AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION] !=
          null) {
        dynamic timeToWaitForATTUserAuthorization = options[
            AppsflyerConstants.AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION];
        assert(timeToWaitForATTUserAuthorization is double);

        afOptions[
                AppsflyerConstants.AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION] =
            timeToWaitForATTUserAuthorization;
      }

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

    if (_afGCDStreamController != null ||
        _afOpenAttributionStreamController != null) {
      afOptions[AppsflyerConstants.AF_GCD] = true;
    } else {
      afOptions[AppsflyerConstants.AF_GCD] = false;
    }

    if (_afUDLStreamController != null ) {
      afOptions[AppsflyerConstants.AF_UDL] = true;
    } else {
      afOptions[AppsflyerConstants.AF_UDL] = false;
    }

    return afOptions;
  }

  // Accessing AppsFlyer Conversion Data from the SDK
  void _registerConversionDataCallback() {
    if (_afGCDStreamController == null) {
      _afGCDStreamController = StreamController<Map>(onCancel: () {
        _afGCDStreamController.close();
      });
    }
  }

  Stream<Map> get conversionDataStream {
    return _afGCDStreamController?.stream?.asBroadcastStream();
  }

  // Accessing AppsFlyer attribution, referred from deep linking
  void _registerOnAppOpenAttributionCallback() {
    if (_afOpenAttributionStreamController == null) {
      _afOpenAttributionStreamController = StreamController<Map>(onCancel: () {
        _afOpenAttributionStreamController.close();
      });
    }
  }


  Stream<Map> get appOpenAttributionStream {
    return _afOpenAttributionStreamController?.stream?.asBroadcastStream();
  }

  // Unified deeplink: Accessing AppsFlyer deeplink attributes
  void _registerUDLCallback() {
    if (_afUDLStreamController == null) {
      _afUDLStreamController = StreamController<Map>(onCancel: () {
        _afUDLStreamController.close();
      });
      _registerUDLListener();
    }
  }

  Stream<Map> get onDeepLinkingStream {
    return _afUDLStreamController?.stream?.asBroadcastStream();
  }

  ///Returns `Stream`. Accessing AppsFlyer purchase validation data
   Stream<dynamic> _registerValidatePurchaseStream() {
    if (_afValidtaPurchaseController == null) {
      _afValidtaPurchaseController = StreamController(onCancel: () {
        _afValidtaPurchaseController.close();
      });

      _registerPurchaseValidateListener();
    }
    return _afValidtaPurchaseController.stream;
  }

  ///initialize the SDK, using the options initialized from the constructor|
  Future<dynamic> initSdk(
      {bool registerConversionDataCallback = false,
      bool registerOnAppOpenAttributionCallback = false,
      bool registerOnDeepLinkingCallback = false}) async {
    return Future.delayed(Duration(seconds: 0)).then((_) {
      
      if (registerConversionDataCallback) _registerConversionDataCallback();
      if (registerOnAppOpenAttributionCallback)
        _registerOnAppOpenAttributionCallback();

      if (registerConversionDataCallback ||
          registerOnAppOpenAttributionCallback) {
        _registerGCDListener();
      }

      if (registerOnDeepLinkingCallback) {
        _registerUDLCallback();
      }      

      Map<String, dynamic> validatedOptions;
      if (mapOptions != null) {
        validatedOptions = _validateMapOptions(mapOptions);
      } else if (afOptions != null) {
        validatedOptions = _validateAFOptions(afOptions);
      }

      return _methodChannel.invokeMethod("initSdk", validatedOptions);
    });
  }

  Future<String> getSDKVersion() async {
    return _methodChannel.invokeMethod("getSDKVersion");
  }

  ///These in-app events help you to log how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to send ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool> logEvent(String eventName, Map eventValues) async {
    assert(eventValues != null);

    return await _methodChannel.invokeMethod(
        "logEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  void setHost(String hostPrefix, String hostName) {
    _methodChannel.invokeMethod(
        "setHost", {'hostPrefix': hostPrefix, 'hostName': hostName});
  }

  /// Opt-out of collection of IMEI.
  /// If the app does NOT contain Google Play Services, device IMEI is collected by the SDK.
  /// However, apps with Google play services should avoid IMEI collection as this is in violation of the Google Play policy.
  void setCollectIMEI(bool isCollect) {
    _methodChannel.invokeMethod("setCollectIMEI", {'isCollect': isCollect});
  }

  /// Opt-out of collection of Android ID.
  /// If the app does NOT contain Google Play Services, Android ID is collected by the SDK.
  /// However, apps with Google play services should avoid Android ID collection as this is in violation of the Google Play policy.
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

  void setIsUpdate(bool isUpdate) {
    _methodChannel.invokeMethod("setIsUpdate", {'isUpdate': isUpdate});
  }

  /// Once this API is invoked, our SDK no longer communicates with our servers and stops functioning.
  /// In some extreme cases you might want to shut down all SDK activity due to legal and privacy compliance.
  /// This can be achieved with the stop API.
  void stop(bool isStopped) {
    _methodChannel.invokeMethod("stop", {'isStopped': isStopped});
  }

  void enableLocationCollection(bool flag) {
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
  void setUserEmails(List<String> emails, [EmailCryptType cryptType]) {
    if (cryptType != null) {
      int cryptTypeInt = EmailCryptType.values.indexOf(cryptType);
      _methodChannel.invokeMethod("setUserEmailsWithCryptType",
          {'emails': emails, 'cryptType': cryptTypeInt});
    } else {
      _methodChannel.invokeMethod("setUserEmails", {'emails': emails});
    }
  }

  ///Get AppsFlyer's unique device ID is created for every new install of an app.
  Future<String> getAppsFlyerUID() async {
    return await _methodChannel.invokeMethod("getAppsFlyerUID");
  }

  ///Set to true if you want to delay sdk init until CUID is set
  void waitForCustomerUserId(bool wait) {
    _methodChannel.invokeMethod("waitForCustomerUserId", {'wait': wait});
  }

  Future<dynamic> validateAndLogInAppAndroidPurchase (
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String> additionalParameters) {

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
      Map<String, String> additionalParameters)async{
      return await _methodChannel.invokeMethod("validateAndLogInAppIosPurchase", {
        'productIdentifier': productIdentifier,
        'price': price,
        'currency': currency,
        'transactionId': transactionId,
        'additionalParameters': additionalParameters
      });
  }

  /// set sandbox for iOS purchase validation
  void useReceiptValidationSandbox(bool isSandboxEnabled) {
    _methodChannel.invokeMethod("useReceiptValidationSandbox", isSandboxEnabled);
  }

  /// Set additional data to be sent to AppsFlyer.
  void setAdditionalData(Map<String, dynamic> customData) {
    _methodChannel
        .invokeMethod("setAdditionalData", {'customData': customData});
  }

  void _registerUDLListener() {
    _eventChannel.receiveBroadcastStream().listen((data) { 
      var decodedJSON = jsonDecode(data);
      String type = decodedJSON['type'];
      if(type == AppsflyerConstants.AF_ON_DEEP_LINK){
        if (_afUDLStreamController != null &&
              !_afUDLStreamController.isClosed) {
            _afUDLStreamController.sink.add(decodedJSON);
        } else {
          if ((afOptions != null && afOptions.showDebug) ||
              (mapOptions != null &&
                  mapOptions[AppsflyerConstants.AF_IS_DEBUG])) {
            print("UDL Stream controller is closed. the event wasn't sent");
          }
        }
      }
    });
  }

  void _registerGCDListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      var decodedJSON = jsonDecode(data);
      String type = decodedJSON['type'];
      switch (type) {
        case AppsflyerConstants.AF_GET_CONVERSION_DATA:
          if (_afGCDStreamController != null &&
              !_afGCDStreamController.isClosed) {
            _afGCDStreamController.sink.add(decodedJSON);
          } else {
            if ((afOptions != null && afOptions.showDebug) ||
                (mapOptions != null &&
                    mapOptions[AppsflyerConstants.AF_IS_DEBUG])) {
              print("GCD Stream controller is closed. the event wasn't sent");
            }
          }
          break;
        case AppsflyerConstants.AF_ON_APP_OPEN_ATTRIBUTION:
          if (_afOpenAttributionStreamController != null &&
              !_afOpenAttributionStreamController.isClosed) {
            _afOpenAttributionStreamController.sink.add(decodedJSON);
          } else {
            if ((afOptions != null && afOptions.showDebug) ||
                (mapOptions != null &&
                    mapOptions[AppsflyerConstants.AF_IS_DEBUG])) {
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
      var decodedJSON = jsonDecode(data);
      String type = decodedJSON['type'];
      if (type == AppsflyerConstants.AF_VALIDATE_PURCHASE) {
        _afValidtaPurchaseController.sink.add(decodedJSON);
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
    AppsFlyerInviteLinkParams parameters,
    Function success,
    Function error,
  ) {
    Map<String, String> paramsMap;
    if (parameters != null) {
      paramsMap = _translateInviteLinkParamsToMap(parameters);
    }
    startListening(success, "generateInviteLinkSuccess");
    startListening(error, "generateInviteLinkFailure");
    _methodChannel.invokeMethod("generateInviteLink", paramsMap);
  }

  Map<String, String> _translateInviteLinkParamsToMap(
      AppsFlyerInviteLinkParams params) {
    Map<String, String> inviteLinkParamsMap = Map<String, String>();
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
    startListening(callback, "setAppInviteOneLinkIDCallback");
    await _methodChannel.invokeMethod("setAppInviteOneLinkID", {
      'oneLinkID': oneLinkID,
    });
  }

  ///To attribute an impression use the following API call.
  ///Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
  void logCrossPromotionImpression(String appId, String campaign, Map data) {
    _methodChannel.invokeMethod("logCrossPromotionImpression",
        {'appId': appId, 'campaign': campaign, 'data': data});
  }

  ///Use the following API to attribute the click and launch the app store's app page.
  void logCrossPromotionAndOpenStore(
      String appId, String campaign, Map params) {
    _methodChannel.invokeMethod("logCrossPromotionAndOpenStore", {
      'appId': appId,
      'campaign': campaign,
      'params': params,
    });
  }

  void setOneLinkCustomDomain(List<String> brandDomains) {
    _methodChannel.invokeMethod("setOneLinkCustomDomain", brandDomains);
  }

  void setPushNotification(bool isEnabled) {
    _methodChannel.invokeMethod("setPushNotification", isEnabled);
  }

  void onInstallConversionData(Function callback) async {
    startListening(callback, "onInstallConversionData");
  }

  void onAppOpenAttribution(Function callback) async {
    startListening(callback, "onAppOpenAttribution");
  }

  void onDeepLinking(Function callback) async {
    startListening(callback, "onDeepLinking");
  }

  void onPurchaseValidation(Function callback) async {
    startListening(callback, "validatePurchase");
  }
}
