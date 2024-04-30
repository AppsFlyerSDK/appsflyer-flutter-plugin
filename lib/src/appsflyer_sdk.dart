part of appsflyer_sdk;

class AppsflyerSdk {
  EventChannel _eventChannel;
  static AppsflyerSdk? _instance;
  final MethodChannel _methodChannel;
  bool _isSdkStarted = false;

  AppsFlyerOptions? afOptions;
  Map? mapOptions;

  ///Returns the [AppsflyerSdk] instance, initialized with a custom options
  ///provided by the user
  factory AppsflyerSdk(options) {
    if (_instance == null) {
      MethodChannel methodChannel =
          const MethodChannel(AppsflyerConstants.AF_METHOD_CHANNEL);

      EventChannel eventChannel =
          EventChannel(AppsflyerConstants.AF_EVENTS_CHANNEL);

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

  /// Validates [AppsFlyerOptions] and converts them to a map acceptable for the AppsFlyer SDK.
  Map<String, dynamic> _validateAFOptions(AppsFlyerOptions options) {
    Map<String, dynamic> validatedOptions = {};

    bool? manualStart = options.manualStart;
    if (manualStart != null) {
      validatedOptions[AppsflyerConstants.AF_MANUAL_START] = manualStart;
    }

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
    } else {
      validatedOptions[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] =
          false;
    }

    if (Platform.isIOS) {
      if (options.timeToWaitForATTUserAuthorization != null) {
        dynamic timeToWaitForATTUserAuthorization =
            options.timeToWaitForATTUserAuthorization;
        assert(timeToWaitForATTUserAuthorization is double);

        validatedOptions[
                AppsflyerConstants.AF_TIME_TO_WAIT_FOR_ATT_USER_AUTHORIZATION] =
            timeToWaitForATTUserAuthorization;
      }
      dynamic appID = options.appId;
      assert(appID != null, "appleAppId is required for iOS apps");
      assert(appID is String);
      RegExp exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      validatedOptions[AppsflyerConstants.AF_APP_Id] = appID;
    }

    validatedOptions[AppsflyerConstants.AF_IS_DEBUG] =
        // ignore: unnecessary_null_comparison
        (options.showDebug != null) ? options.showDebug : false;

    return validatedOptions;
  }

  /// Validates a map of option values, checking their types and presence.
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

    if (options[AppsflyerConstants.AF_MANUAL_START] != null) {
      afOptions[AppsflyerConstants.AF_MANUAL_START] = options[AppsflyerConstants.AF_MANUAL_START];
    }else{
      afOptions[AppsflyerConstants.AF_MANUAL_START] = false;
    }

    afOptions[AppsflyerConstants.APP_INVITE_ONE_LINK] = appInviteOneLink;

    if (options[AppsflyerConstants.DISABLE_COLLECT_ASA] != null) {
      afOptions[AppsflyerConstants.DISABLE_COLLECT_ASA] =
          options[AppsflyerConstants.DISABLE_COLLECT_ASA];
    }

    if (options[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] != null) {
      afOptions[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] =
          options[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER];
    } else {
      afOptions[AppsflyerConstants.DISABLE_ADVERTISING_IDENTIFIER] = false;
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

    return afOptions;
  }

  ///initialize the SDK, using the options initialized from the constructor|
  Future<dynamic> initSdk(
      {bool registerConversionDataCallback = false,
      bool registerOnAppOpenAttributionCallback = false,
      bool registerOnDeepLinkingCallback = false}) async {
    return Future.delayed(Duration(seconds: 0)).then((_) {
      Map<String, dynamic>? validatedOptions;
      if (mapOptions != null) {
        validatedOptions = _validateMapOptions(mapOptions!);
      } else if (afOptions != null) {
        validatedOptions = _validateAFOptions(afOptions!);
      }

      validatedOptions?[AppsflyerConstants.AF_GCD] =
          registerConversionDataCallback ||
              registerOnAppOpenAttributionCallback;
      validatedOptions?[AppsflyerConstants.AF_UDL] =
          registerOnDeepLinkingCallback;
      //Means that we automatically starting the SDK
      if (validatedOptions?[AppsflyerConstants.AF_MANUAL_START] == false) {
        _isSdkStarted = true;
      }
      return _methodChannel.invokeMethod("initSdk", validatedOptions);
    });
  }

  /// Initializes the SDK and sets up a method call handler to listen for native callbacks.
  /// Guards against multiple initializations with `_isSdkStarted`
  void startSDK({
    RequestSuccessListener? onSuccess,
    RequestErrorListener? onError,
  }) {
    if (_isSdkStarted) {
      return;
    }
    _isSdkStarted = true;
    if (onSuccess != null || onError != null) {
      _methodChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onSuccess':
            onSuccess?.call();
            _methodChannel.setMethodCallHandler(null);
            break;
          case 'onError':
            final int errorCode = call.arguments['errorCode'];
            final String errorMessage = call.arguments['errorMessage'];
            onError?.call(errorCode, errorMessage);
            _methodChannel.setMethodCallHandler(null);
            break;
          default:
            print('Unknown method called from the native side.');
            _isSdkStarted = false;
            _methodChannel.setMethodCallHandler(null);
            break;
        }
      });
      _methodChannel.invokeMethod('startSDKwithHandler');
    } else {
      _methodChannel.invokeMethod('startSDK');
    }
  }

  /// Retrieves the current SDK version.
  Future<String?> getSDKVersion() async {
    return _methodChannel.invokeMethod("getSDKVersion");
  }

  ///These in-app events help you to log how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to send ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool?> logEvent(String eventName, Map? eventValues) async {
    return await _methodChannel.invokeMethod(
        "logEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  /// Sets the host name and the host prefix.
  /// This is only relevant if you need to switch between HTTPS environments.
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

  /// Retrieves the host name.
  Future<String?> getHostName() async {
    return await _methodChannel.invokeMethod("getHostName");
  }

  /// Retrieves the host prefix.
  Future<String?> getHostPrefix() async {
    return await _methodChannel.invokeMethod("getHostPrefix");
  }

  /// Sets Android ID.
  void setAndroidIdData(String androidId) {
    _methodChannel.invokeMethod("setAndroidIdData", {'androidId': androidId});
  }

  /// Set the minimum time between sessions.
  /// Any app launches that happen within this minimum threshold will be
  /// attributed to the current session. Launches that occur after
  /// this threshold has been crossed will be counted as a separate session.
  void setMinTimeBetweenSessions(int seconds) {
    assert(seconds >= 0, "the minimum timeout must be a positive number");
    _methodChannel
        .invokeMethod("setMinTimeBetweenSessions", {'seconds': seconds});
  }

  /// Sets the IMEI for the device.
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

  /// Setting whether the SDK should collect tcf data automatically from SharedPreferences/UserDefaults
  void enableTCFDataCollection(bool shouldCollect) {
    _methodChannel.invokeListMethod(
        "enableTCFDataCollection", {'shouldCollect': shouldCollect});
  }

  void setConsentData(AppsFlyerConsent consentData) {
    _methodChannel.invokeMethod('setConsentData',
        <String, dynamic>{'consentData': consentData.toMap()});
  }

  /// Opt-out logging for specific user
  void anonymizeUser(bool shouldAnonymize) {
    _methodChannel
        .invokeMethod("anonymizeUser", {'shouldAnonymize': shouldAnonymize});
  }

  /// Opt-out logging for specific user
  void performOnDeepLinking() {
    _methodChannel.invokeMethod("performOnDeepLinking");
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

  ///Please use updateServerUninstallToken instead (deprecated)
  @Deprecated("use updateServerUninstallToken instead")
  void enableUninstallTracking(String senderId) {
    print("Please use updateServerUninstallToken instead");
  }

  ///Manually pass the Firebase / GCM Device Token for Uninstall measurement.
  void updateServerUninstallToken(String token) {
    _methodChannel.invokeMethod("updateServerUninstallToken", {'token': token});
  }

  ///Set the user emails and encrypt them.
  void setUserEmails(List<String> emails, [EmailCryptType? cryptType]) {
    int cryptTypeInt = 0;
    if (cryptType != null) {
      cryptTypeInt = EmailCryptType.values.indexOf(cryptType);
    }
    _methodChannel.invokeMethod(
        "setUserEmails", {'emails': emails, 'cryptType': cryptTypeInt});
  }

  ///Get AppsFlyer's unique device ID is created for every new install of an app.
  Future<String?> getAppsFlyerUID() async {
    return await _methodChannel.invokeMethod("getAppsFlyerUID");
  }

  ///Set customer user ID and unlock the wait for customer user id. Use with waitForCustomerUserId
  void setCustomerIdAndLogSession(String id) {
    _methodChannel.invokeMethod("setCustomerIdAndLogSession", {'id': id});
  }

  ///Set to true if you want to delay sdk init until CUID is set
  void waitForCustomerUserId(bool wait) {
    _methodChannel.invokeMethod("waitForCustomerUserId", {'wait': wait});
  }

  ///Adds array of keys, which are used to compose key path to resolve deeplink from push notification payload.
  void addPushNotificationDeepLinkPath(List<String> deeplinkPath) {
    _methodChannel.invokeMethod(
        "addPushNotificationDeepLinkPath", deeplinkPath);
  }

  /// Validate and log the In-App Purchase for Android on AppsFlyer's dashboard.
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
    _methodChannel.invokeMethod(
        "useReceiptValidationSandbox", isSandboxEnabled);
  }

  /// Set additional data to be sent to AppsFlyer.
  void setAdditionalData(Map<String, dynamic>? customData) {
    _methodChannel
        .invokeMethod("setAdditionalData", {'customData': customData});
  }

  /// Generates an invite link using the specified parameters, aka User Invite feature
  void generateInviteLink(
    AppsFlyerInviteLinkParams? parameters,
    Function success,
    Function error,
  ) {
    Map<String, Object?>? paramsMap;
    if (parameters != null) {
      paramsMap = _translateInviteLinkParamsToMap(parameters);
    }
    startListening(
        success as void Function(dynamic), "generateInviteLinkSuccess");
    startListening(
        error as void Function(dynamic), "generateInviteLinkFailure");
    _methodChannel.invokeMethod("generateInviteLink", paramsMap);
  }

  /// Translates invite link parameters into a map for sending over the method channel.
  Map<String, Object?> _translateInviteLinkParamsToMap(
      AppsFlyerInviteLinkParams params) {
    Map<String, Object?> inviteLinkParamsMap = <String, Object?>{};
    inviteLinkParamsMap['customParams'] = params.customParams;
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

  /// Sets custom domain for OneLink aka Branded Domains
  void setOneLinkCustomDomain(List<String> brandDomains) {
    _methodChannel.invokeMethod("setOneLinkCustomDomain", brandDomains);
  }

  /// Is push notification enabled or not (deprecated)
  @Deprecated("use sendPushNotificationData instead")
  void setPushNotification(bool isEnabled) {
    _methodChannel.invokeMethod("setPushNotification", isEnabled);
  }

  /// Sends push notification data.
  void sendPushNotificationData(Map? userInfo) {
    _methodChannel.invokeMethod("sendPushNotificationData", userInfo);
  }

  /// Enables or disables Facebook deferred deep links.
  void enableFacebookDeferredApplinks(bool isEnabled) {
    _methodChannel.invokeMethod("enableFacebookDeferredApplinks",
        {'isFacebookDeferredApplinksEnabled': isEnabled});
  }

  /// Disables SKAdNetwork (iOS 14 attribution framework).
  void disableSKAdNetwork(bool isEnabled) {
    _methodChannel.invokeMethod("disableSKAdNetwork", isEnabled);
  }

  /// Disables tracking of advertising identifiers.
  void setDisableAdvertisingIdentifiers(bool isEnabled) {
    _methodChannel.invokeMethod("setDisableAdvertisingIdentifiers", isEnabled);
  }

  /// Listens for conversion data following app install.
  void onInstallConversionData(Function callback) async {
    startListening(
        callback as void Function(dynamic), "onInstallConversionData");
  }

  /// Listens for attribution data following app open.
  void onAppOpenAttribution(Function callback) async {
    startListening(callback as void Function(dynamic), "onAppOpenAttribution");
  }

  /// Handles deep link result.
  void onDeepLinking(Function(DeepLinkResult) callback) async {
    startListeningToUDL(callback, "onDeepLinking");
  }

  /// Validates purchase.
  void onPurchaseValidation(Function callback) async {
    startListening(callback as void Function(dynamic), "validatePurchase");
  }

  /// Sets the current device language.
  void setCurrentDeviceLanguage(String language) async {
    _methodChannel.invokeMethod("setCurrentDeviceLanguage", language);
  }

  /// Sets sharing filter for specific partners (deprecated).
  @Deprecated("use setSharingFilterForPartners instead")
  void setSharingFilter(List<String> partners) {
    setSharingFilterForPartners(partners);
  }

  /// Sets sharing filter for all partners (deprecated).
  @Deprecated("use setSharingFilterForPartners instead")
  void setSharingFilterForAllPartners() {
    setSharingFilterForPartners(["all"]);
  }

  ///The sharing filter blocks the sharing of S2S events via postbacks/API with integrated partners and other third-party integrations.
  ///Use the filter to fulfill regulatory requirements like GDPR and CCPA, to comply with user opt-out mechanisms, and for other business logic reasons.
  void setSharingFilterForPartners(List<String> partners) async {
    _methodChannel.invokeMethod("setSharingFilterForPartners", partners);
  }

  /// Sets out of store app install source.
  void setOutOfStore(String sourceName) async {
    _methodChannel.invokeMethod("setOutOfStore", sourceName);
  }

  /// Gets out of store app install source.
  Future<String?> getOutOfStore() async {
    return await _methodChannel.invokeMethod("getOutOfStore");
  }

  /// Sets the partner-specific data.
  void setPartnerData(String partnerId, Map<String, Object> partnerData) async {
    _methodChannel.invokeMethod("setPartnerData",
        {'partnerId': partnerId, 'partnersData': partnerData});
  }

  /// Sets URLs to deep link into the app when the app is first installed.
  void setResolveDeepLinkURLs(List<String> urls) async {
    _methodChannel.invokeMethod("setResolveDeepLinkURLs", urls);
  }

  /// Disables transfer of user-specific data over the network.
  void setDisableNetworkData(bool disable) {
    _methodChannel.invokeMethod("setDisableNetworkData", disable);
  }
}
