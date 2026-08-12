part of appsflyer_sdk;

/// The AppsFlyer SDK entry point.
///
/// Use the shared [instance] to configure and initialize the SDK. Subscribe to
/// the required event streams before registering their native listeners.
///
/// Initialization does not send a session. Register the session-ready
/// listener and call [start] when [onSessionReady] emits:
///
/// ```dart
/// final appsFlyer = AppsFlyerSdk.instance;
///
/// appsFlyer.onSessionReady.listen((_) async {
///   await appsFlyer.start();
/// });
///
/// await appsFlyer.init(
///   devKey: 'YOUR_DEV_KEY',
///   appId: 'YOUR_APP_ID',
/// );
/// await appsFlyer.registerSessionReadyListener();
/// ```
class AppsFlyerSdk {
  /// Returns the shared [AppsFlyerSdk] instance.
  static final AppsFlyerSdk instance = AppsFlyerSdk.private(
    const MethodChannel(_AppsFlyerConstants.AF_METHOD_CHANNEL),
    const EventChannel(_AppsFlyerConstants.AF_EVENTS_CHANNEL),
  );

  @visibleForTesting
  AppsFlyerSdk.private(
    this._methodChannel,
    EventChannel eventChannel, {
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform {
    _events = eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<dynamic, _AppsFlyerEvent>.fromHandlers(
        handleData: (dynamic value, EventSink<_AppsFlyerEvent> sink) {
          try {
            if (value is! String) {
              throw FormatException(
                'AppsFlyer event must be a JSON string, got ${value.runtimeType}',
              );
            }
            sink.add(_AppsFlyerEvent.fromNative(value));
          } catch (error) {
            debugPrint('AppsFlyer: dropped malformed native event: $error');
          }
        },
      ),
    ).asBroadcastStream();
  }

  final TargetPlatform _platform;

  bool get _isIOS => _platform == TargetPlatform.iOS;

  bool get _isAndroid => _platform == TargetPlatform.android;

  /// Returns the Flutter plugin version.
  String get pluginVersion => _AppsFlyerConstants.PLUGIN_VERSION;

  final MethodChannel _methodChannel;
  late final Stream<_AppsFlyerEvent> _events;

  /// Listens for successful install and attribution conversion data.
  ///
  /// Subscribe before [registerConversionListener] so the first result is not
  /// missed.
  Stream<Map<String, dynamic>> get onConversionDataSuccess => _events
      .where((event) => event.name == 'onConversionDataSuccess')
      .map((event) => event.data);

  /// Listens for conversion-data failures reported by the native SDK.
  ///
  /// The [registerConversionListener] call can succeed while conversion data
  /// retrieval still fails. The payload shape differs by platform: Android
  /// reports `{"error": String}` with no error code; iOS reports
  /// `{"error": String, "code": int}`.
  ///
  /// Subscribe before [registerConversionListener] so the first result is not
  /// missed.
  Stream<Map<String, dynamic>> get onConversionDataFailure => _events
      .where((event) => event.name == 'onConversionDataFail')
      .map((event) => event.data);

  /// Listens for Unified Deep Linking results.
  ///
  /// Subscribe before [registerDeepLinkListener] so a launch deep link is not
  /// missed.
  Stream<DeepLinkResult> get onDeepLinkReceived => _events
      .where(
        (event) =>
            event.name == 'onDeepLinking' || event.name == 'onDeepLinkReceived',
      )
      .map((event) => DeepLinkResult._fromEvent(event, platform: _platform));

  /// Emits once per foreground cycle when the SDK is ready to send a session.
  ///
  /// Subscribe before [registerSessionReadyListener], then call [start] from
  /// the listener.
  Stream<void> get onSessionReady => _events
      .where((event) => event.name == 'onSessionReady')
      .map<void>((_) {});

  /// Initializes the SDK with [devKey] and, on iOS, [appId].
  ///
  /// Does not send a session.
  ///
  /// [appId] is required by the native iOS SDK and is not sent to Android.
  /// Input validation is performed by the native RPC layer.
  Future<void> init({
    required String devKey,
    String? appId,
  }) {
    return _invokeVoidRpc(
      'init',
      _isIOS ? {'devKey': devKey, 'appId': appId} : {'devKey': devKey},
    );
  }

  /// Registers the install and attribution conversion-data listener.
  ///
  /// Subscribe to [onConversionDataSuccess] and [onConversionDataFailure]
  /// before calling this method so the first result is not missed.
  Future<void> registerConversionListener() {
    return _invokeVoidRpc('registerConversionListener');
  }

  /// Unregisters the native Android conversion-data listener.
  ///
  /// This API is available only on Android. Call [registerConversionListener]
  /// again to resume receiving conversion-data events.
  Future<void> unregisterConversionListener() async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('unregisterConversionListener', 'Android');
      return;
    }
    return _invokeVoidRpc('unregisterConversionListener');
  }

  /// Registers the Unified Deep Linking listener.
  ///
  /// Subscribe to [onDeepLinkReceived] before calling this method so a launch
  /// deep link is not missed.
  Future<void> registerDeepLinkListener() {
    return _invokeVoidRpc(
      _isAndroid ? 'subscribeForDeepLink' : 'registerDeeplinkListener',
    );
  }

  /// Requests removal of the Unified Deep Linking listener on Android.
  Future<void> unregisterDeeplinkListener() async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('unregisterDeeplinkListener', 'Android');
      return;
    }
    return _invokeVoidRpc('unsubscribeForDeepLink');
  }

  /// Registers the session-ready listener.
  ///
  /// The SDK emits [onSessionReady] once per foreground cycle when it is ready
  /// to send a session. Subscribe before registering, and call [start] from the
  /// stream listener:
  ///
  /// ```dart
  /// appsFlyer.onSessionReady.listen((_) => appsFlyer.start());
  /// await appsFlyer.registerSessionReadyListener();
  /// ```
  Future<void> registerSessionReadyListener() {
    return _invokeVoidRpc('registerSessionReadyListener');
  }

  /// Removes the listener registered by [registerSessionReadyListener].
  Future<void> unregisterSessionReadyListener() {
    return _invokeVoidRpc('unregisterSessionReadyListener');
  }

  /// Whether all session-readiness conditions are currently met.
  ///
  /// Use this when [registerSessionReadyListener] was registered after the SDK
  /// became ready.
  Future<bool> isSessionReady() {
    return _invokeRpc<bool>('isSessionReady');
  }

  /// Sends a session ("Launch").
  ///
  /// Call once for each [onSessionReady] emission. Defer this call when the
  /// first session must wait for consent or another application condition.
  ///
  /// When [awaitResponse] is `false` (the default), the returned [Future]
  /// completes when the native SDK accepts the request. Delivery success or
  /// failure is not reported.
  ///
  /// When [awaitResponse] is `true`, the [Future] completes when the native
  /// request succeeds and throws [AppsFlyerException] when it fails. A timeout
  /// does not cancel the native request, which may still succeed later.
  Future<void> start({bool awaitResponse = false}) {
    return _invokeVoidRpc('start', {'awaitResponse': awaitResponse});
  }

  /// Enables or disables SDK debug logging.
  ///
  /// May be called before [init]. Call before [start] so the first session
  /// uses the selected setting.
  Future<void> enableDebug(bool enabled) {
    return _invokeVoidRpc('isDebug', {'isDebug': enabled});
  }

  /// Sets the Android SDK logging level.
  ///
  /// This API is available only on Android. Use [enableDebug] to enable or
  /// disable debug logging on both Android and iOS.
  ///
  /// ```dart
  /// await AppsFlyerSdk.instance.setLogLevel(AFLogLevel.debug);
  /// ```
  Future<void> setLogLevel(AFLogLevel logLevel) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setLogLevel', 'Android');
      return;
    }
    return _invokeVoidRpc(
      'setLogLevel',
      {'logLevel': logLevel.rpcValue},
    );
  }

  /// Sends an in-app event.
  ///
  /// [eventName] identifies the event. [eventValues] contains optional event
  /// parameters.
  ///
  /// When [awaitResponse] is `false` (the default), the returned [Future]
  /// completes when the native SDK accepts the request. Delivery success or
  /// failure is not reported.
  ///
  /// When [awaitResponse] is `true`, the [Future] completes when the native
  /// request succeeds and throws [AppsFlyerException] when it fails. A timeout
  /// does not cancel the native request, which may still succeed later.
  ///
  /// ```dart
  /// await AppsFlyerSdk.instance.logEvent(
  ///   'af_purchase',
  ///   eventValues: {'af_revenue': 9.99, 'af_currency': 'USD'},
  /// );
  /// ```
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? eventValues,
    bool awaitResponse = false,
  }) {
    return _invokeVoidRpc('logEvent', {
      'eventName': eventName,
      'eventValues': eventValues,
      'awaitResponse': awaitResponse,
    });
  }

  /// Logs ad revenue for a monetization or mediation network.
  ///
  /// [monetizationNetwork] identifies the source network.
  /// [mediationNetwork] identifies the mediation platform.
  /// [currencyIso4217Code] is the ISO 4217 currency code.
  /// [revenue] is the ad-revenue amount.
  /// [additionalParameters] contains optional ad-revenue values.
  ///
  /// The returned [Future] completes when the native SDK accepts the request.
  /// Throws [AppsFlyerException] on failure.
  Future<void> logAdRevenue({
    required String monetizationNetwork,
    required AFMediationNetwork mediationNetwork,
    required String currencyIso4217Code,
    required double revenue,
    Map<String, dynamic>? additionalParameters,
  }) {
    return _invokeVoidRpc('logAdRevenue', {
      'monetizationNetwork': monetizationNetwork,
      'mediationNetwork': mediationNetwork.rpcValue(isIOS: _isIOS),
      'currencyIso4217Code': currencyIso4217Code,
      'revenue': revenue,
      'additionalParameters': additionalParameters,
    });
  }

  /// Manually logs the user's location.
  ///
  /// [latitude] must be in the range -90 through 90 and [longitude] in the
  /// range -180 through 180. Values outside these ranges are rejected with an
  /// [AppsFlyerException].
  Future<void> logLocation({
    required double latitude,
    required double longitude,
  }) {
    return _invokeVoidRpc('logLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Manually logs a session on Android.
  ///
  /// Android only. For typical Flutter apps, use [start] when [onSessionReady]
  /// emits instead.
  Future<void> logSession() async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('logSession', 'Android');
      return;
    }
    return _invokeVoidRpc('logSession');
  }

  /// Sets your own customer user ID to cross-reference with the AppsFlyer ID.
  Future<void> setCustomerUserId(String customerId) {
    return _invokeVoidRpc('setCustomerUserId', {'customerId': customerId});
  }

  /// Sets the user's email.
  ///
  /// The SDK hashes the value with SHA-256 before sending it.
  Future<void> setUserEmail(String email) {
    return _invokeVoidRpc('setUserEmail', {'email': email});
  }

  /// Sets the user's phone number.
  ///
  /// [countryCode] is the dialing country code and [phoneNumber] is the local
  /// number. The SDK hashes the value with SHA-256 before sending it.
  Future<void> setUserPhone(String countryCode, String phoneNumber) {
    return _invokeVoidRpc('setUserPhone', {
      'countryCode': countryCode,
      'phoneNumber': phoneNumber,
    });
  }

  /// Sets the user's first name.
  ///
  /// The SDK hashes the value with SHA-256 before sending it.
  Future<void> setUserFirstName(String firstName) {
    return _invokeVoidRpc('setUserFirstName', {'firstName': firstName});
  }

  /// Sets the user's last name.
  ///
  /// The SDK hashes the value with SHA-256 before sending it.
  Future<void> setUserLastName(String lastName) {
    return _invokeVoidRpc('setUserLastName', {'lastName': lastName});
  }

  /// Sets the user's Facebook login ID (App-Scoped ID) for network sharing.
  ///
  /// Unlike the other `setUser*` methods, this value is not hashed. Pass `0`
  /// to clear the ID.
  Future<void> setUserFbLoginId(int fbLoginId) {
    return _invokeVoidRpc('setUserFbLoginId', {'fbLoginId': fbLoginId});
  }

  /// Clears all PII set through the `setUser*` methods.
  Future<void> clearUserPii() {
    return _invokeVoidRpc('clearUserPii');
  }

  /// Sets the currency used for in-app purchase revenue.
  ///
  /// Use a three-letter ISO 4217 currency code. The default is USD.
  Future<void> setCurrencyCode(String currencyCode) {
    return _invokeVoidRpc(
      'setCurrencyCode',
      {'currencyCode': currencyCode},
    );
  }

  /// Sets the minimum time between two launches for them to count as separate
  /// sessions.
  ///
  /// [seconds] is the minimum interval in seconds.
  Future<void> setMinTimeBetweenSessions(int seconds) {
    return _invokeVoidRpc(
      'setMinTimeBetweenSessions',
      {'seconds': seconds},
    );
  }

  /// Sets a custom host name and prefix.
  ///
  /// Use this only when instructed by AppsFlyer support.
  /// iOS requires both values to be non-empty. Android requires a non-empty
  /// [hostName] and permits an empty [hostPrefixName].
  Future<void> setHost(String hostPrefixName, String hostName) {
    return _invokeVoidRpc('setHost', {
      'hostPrefixName': hostPrefixName,
      'hostName': hostName,
    });
  }

  /// Returns the configured host name.
  ///
  /// Android only.
  Future<String> getHostName() {
    return _invokeRpc<String>('getHostName');
  }

  /// Returns the configured host prefix.
  ///
  /// Android only.
  Future<String> getHostPrefix() {
    return _invokeRpc<String>('getHostPrefix');
  }

  /// Sets additional custom data sent to AppsFlyer.
  ///
  /// Pass an empty map to clear previously supplied data.
  Future<void> setAdditionalData(Map<String, dynamic> customData) {
    return _invokeVoidRpc(
      'setAdditionalData',
      {'customData': customData},
    );
  }

  /// Sets the OneLink ID used as the base for links from [generateInviteLink].
  Future<void> setAppInviteOneLink(String oneLinkId) {
    return _invokeVoidRpc(
      'setAppInviteOneLink',
      {'oneLinkId': oneLinkId},
    );
  }

  /// Sets partner-specific data.
  ///
  /// [partnerId] identifies the partner and [data] contains the data
  /// supplied to that partner.
  Future<void> setPartnerData(
    String partnerId,
    Map<String, dynamic> data,
  ) {
    return _invokeVoidRpc('setPartnerData', {
      'partnerId': partnerId,
      'data': data,
    });
  }

  /// Blocks sharing of S2S events through postback or API with the specified
  /// partners.
  ///
  /// Pass `null` or an empty list to clear the filter. The plugin normalizes
  /// an empty list to `null` before sending the RPC request.
  Future<void> setSharingFilterForPartners(List<String>? partners) {
    return _invokeVoidRpc(
      'setSharingFilterForPartners',
      {'partners': partners != null && partners.isEmpty ? null : partners},
    );
  }

  /// Sets the out-of-store install source.
  ///
  /// Android only.
  Future<void> setOutOfStore(String sourceName) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setOutOfStore', 'Android');
      return;
    }
    return _invokeVoidRpc('setOutOfStore', {'sourceName': sourceName});
  }

  /// Returns the out-of-store install source.
  ///
  /// Android only.
  Future<String?> getOutOfStore() {
    return _invokeNullableRpc<String?>('getOutOfStore');
  }

  /// Manually marks the app as updated.
  ///
  /// Android only.
  Future<void> setIsUpdate(bool isUpdate) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setIsUpdate', 'Android');
      return;
    }
    return _invokeVoidRpc('setIsUpdate', {'isUpdate': isUpdate});
  }

  /// Overrides the device language reported to the SDK.
  ///
  /// iOS only.
  Future<void> setCurrentDeviceLanguage(String language) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setCurrentDeviceLanguage', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setCurrentDeviceLanguage',
      {'language': language},
    );
  }

  /// Sets a custom install ID to correlate the install with your own ID.
  ///
  /// On iOS, call before [init]; on Android, call after [init].
  ///
  /// Both platforms silently ignore the call unless the opt-in flag is set:
  /// `AppsFlyerAllowCustomInstallId = YES` in `Info.plist` (iOS) or
  /// `APPSFLYER_ALLOW_CUSTOM_INSTALL_ID = true` in `AndroidManifest.xml`
  /// (Android).
  Future<void> setInstallId(String installId) {
    return _invokeVoidRpc('setInstallId', {'installId': installId});
  }

  /// Attributes the install to an OEM or manufacturer preinstall campaign.
  ///
  /// Android only. Call before [start]. [mediaSource] is required; [campaign]
  /// and [siteId] are optional.
  Future<void> setPreinstallAttribution(
    String mediaSource, {
    String campaign = '',
    String siteId = '',
  }) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setPreinstallAttribution', 'Android');
      return;
    }
    return _invokeVoidRpc('setPreinstallAttribution', {
      'mediaSource': mediaSource,
      'campaign': campaign,
      'siteId': siteId,
    });
  }

  /// Overrides the app ID reported to AppsFlyer.
  ///
  /// Android only. Call before [start]. Throws [AppsFlyerException] when
  /// [appId] is empty.
  Future<void> setAppId(String appId) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setAppId', 'Android');
      return;
    }
    return _invokeVoidRpc('setAppId', {'appId': appId});
  }

  /// Sets GDPR and DMA consent data.
  ///
  /// Provide the current consent on every app start before [start]. Consent
  /// values are not persisted across sessions.
  ///
  /// When [isUserSubjectToGDPR] is `true`, [hasConsentForDataUsage] and
  /// [hasConsentForAdsPersonalization] are required.
  /// [hasConsentForAdStorage] is optional.
  Future<void> setConsentData({
    required bool isUserSubjectToGDPR,
    bool? hasConsentForDataUsage,
    bool? hasConsentForAdsPersonalization,
    bool? hasConsentForAdStorage,
  }) {
    if (isUserSubjectToGDPR && hasConsentForDataUsage == null) {
      throw ArgumentError.notNull('hasConsentForDataUsage');
    }
    if (isUserSubjectToGDPR && hasConsentForAdsPersonalization == null) {
      throw ArgumentError.notNull('hasConsentForAdsPersonalization');
    }
    return _invokeVoidRpc('setConsentData', {
      'isUserSubjectToGDPR': isUserSubjectToGDPR,
      'hasConsentForDataUsage': hasConsentForDataUsage,
      'hasConsentForAdsPersonalization': hasConsentForAdsPersonalization,
      'hasConsentForAdStorage': hasConsentForAdStorage,
    });
  }

  /// Enables or disables automatic collection of IAB TCF consent data.
  Future<void> enableTCFDataCollection(bool shouldCollect) {
    return _invokeVoidRpc(
      'enableTCFDataCollection',
      {'shouldCollect': shouldCollect},
    );
  }

  /// Anonymizes user data.
  Future<void> anonymizeUser(bool shouldAnonymize) {
    return _invokeVoidRpc(
      'anonymizeUser',
      {'shouldAnonymize': shouldAnonymize},
    );
  }

  /// Stops or resumes all SDK activity and communication with AppsFlyer
  /// servers.
  ///
  /// Pass `true` to stop the SDK and `false` to resume it.
  Future<void> stop(bool shouldStop) {
    return _invokeVoidRpc('stop', {'shouldStop': shouldStop});
  }

  /// Whether the SDK is currently stopped.
  ///
  /// Android only.
  Future<bool> isStopped() async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('isStopped', 'Android');
      return false;
    }
    return _invokeRpc<bool>('isStopped');
  }

  /// Disables collection of advertising identifiers.
  ///
  /// Pass `true` to disable collection of identifiers such as GAID, IDFA, and
  /// OAID. Collection is enabled by default.
  Future<void> setDisableAdvertisingIdentifiers(bool disable) {
    return _invokeVoidRpc(
      'setDisableAdvertisingIdentifiers',
      _isIOS ? {'disable': disable} : {'isDisable': disable},
    );
  }

  /// Disables Apple Search Ads attribution collection.
  ///
  /// iOS only. Call before [start].
  Future<void> setDisableCollectASA(bool disable) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setDisableCollectASA', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setDisableCollectASA',
      {'disable': disable},
    );
  }

  /// Enables or disables Android ID collection.
  ///
  /// Android only. Apps distributed through Google Play should follow Google
  /// Play policy when configuring this value.
  Future<void> setCollectAndroidID(bool isCollect) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setCollectAndroidID', 'Android');
      return;
    }
    return _invokeVoidRpc('setCollectAndroidID', {'isCollect': isCollect});
  }

  /// Disables collection of the network carrier and SIM operator names.
  ///
  /// Android only.
  Future<void> setDisableNetworkData(bool isDisable) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('setDisableNetworkData', 'Android');
      return;
    }
    return _invokeVoidRpc(
      'setDisableNetworkData',
      {'isDisable': isDisable},
    );
  }

  /// Disables App Set ID collection.
  ///
  /// Android only.
  Future<void> disableAppSetId() async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('disableAppSetId', 'Android');
      return;
    }
    return _invokeVoidRpc('disableAppSetId');
  }

  /// Disables SKAdNetwork attribution.
  ///
  /// iOS only. Pass `true` to disable SKAdNetwork.
  Future<void> setDisableSKAdNetwork(bool disable) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setDisableSKAdNetwork', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setDisableSKAdNetwork',
      {'disable': disable},
    );
  }

  /// Disables Apple Ads attribution.
  ///
  /// iOS only. Call before [start].
  Future<void> setDisableAppleAdsAttribution(bool disable) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setDisableAppleAdsAttribution', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setDisableAppleAdsAttribution',
      {'disable': disable},
    );
  }

  /// Disables collection of the Identifier for Vendor (IDFV).
  ///
  /// iOS only. Call before [start].
  Future<void> setDisableIDFVCollection(bool disable) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setDisableIDFVCollection', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setDisableIDFVCollection',
      {'disable': disable},
    );
  }

  /// Enables device-name collection.
  ///
  /// iOS only. Collection is disabled by default. Call before [start], and
  /// enable it only when your privacy policy covers collection of the device
  /// name.
  Future<void> setShouldCollectDeviceName(bool collect) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setShouldCollectDeviceName', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'setShouldCollectDeviceName',
      {'collect': collect},
    );
  }

  /// Validates and logs an in-app purchase.
  ///
  /// [purchase] is an [AFAndroidPurchaseDetails] or [AFIOSPurchaseDetails]
  /// instance for the current platform.
  /// [additionalParameters] contains optional values to include with the
  /// validation request.
  /// By default, Android waits for the native validation result. Set
  /// [awaitResponse] to `false` to start validation without a result callback
  /// and return an empty map. On iOS, [awaitResponse] is ignored and validation
  /// always completes before the [Future] resolves.
  ///
  /// When the native result is awaited, completes with the validation result
  /// or throws [AppsFlyerException] when validation fails. On Android with
  /// `awaitResponse: false`, native validation failures are not reported.
  Future<Map<String, dynamic>> validateAndLogInAppPurchase(
    AFPurchaseDetails purchase, {
    Map<String, String>? additionalParameters,
    bool awaitResponse = true,
  }) async {
    final params = purchase.toRpcMap(
      platform: _platform,
      additionalParameters: additionalParameters,
    );
    if (_isAndroid) {
      params['awaitResponse'] = awaitResponse;
    }
    final result = await _invokeNullableRpc<Map<Object?, Object?>?>(
      'validateAndLogInAppPurchase',
      params,
    );
    return result == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(result);
  }

  /// Enables sandbox mode for App Store receipt validation.
  ///
  /// iOS only.
  Future<void> setUseReceiptValidationSandbox(bool sandbox) {
    return _invokeVoidRpc(
      'setUseReceiptValidationSandbox',
      {'sandbox': sandbox},
    );
  }

  /// Enables sandbox mode for uninstall-measurement validation.
  ///
  /// iOS only. This is the uninstall-measurement companion to
  /// [setUseReceiptValidationSandbox].
  Future<void> setUseUninstallSandbox(bool sandbox) {
    return _invokeVoidRpc(
      'setUseUninstallSandbox',
      {'sandbox': sandbox},
    );
  }

  /// Logs a cross-promotion impression.
  ///
  /// Use the promoted app ID as shown in the AppsFlyer dashboard.
  /// [campaign] and [userParams] are optional.
  Future<void> logCrossPromoteImpression(
    String appId, {
    String campaign = '',
    Map<String, String>? userParams,
  }) {
    return _invokeVoidRpc('logCrossPromoteImpression', {
      'appId': appId,
      'campaign': campaign,
      'userParams': userParams,
    });
  }

  /// Logs a cross-promotion click and opens the promoted app's store page.
  ///
  /// [promotedAppId] is the app ID shown in the AppsFlyer dashboard.
  /// [campaign] and [userParams] are optional.
  Future<void> logAndOpenStore(
    String promotedAppId, {
    String campaign = '',
    Map<String, String>? userParams,
  }) {
    return _invokeVoidRpc('logAndOpenStore', {
      'promotedAppId': promotedAppId,
      'campaign': campaign,
      'userParams': userParams,
    });
  }

  /// Generates a OneLink user-invite URL.
  ///
  /// Configure the OneLink template with [setAppInviteOneLink] before
  /// generating a link. [parameters] contains optional channel, campaign,
  /// referrer, deep-link, branded-domain, and custom values.
  /// By default, Android waits for its asynchronous link-generation callback.
  /// Set [awaitResponse] to `false` to return the synchronously generated long
  /// link instead. On iOS, [awaitResponse] is ignored and link generation is
  /// always asynchronous.
  ///
  /// Completes with the generated URL, or throws [AppsFlyerException] on
  /// failure.
  ///
  /// ```dart
  /// final url = await AppsFlyerSdk.instance.generateInviteLink(
  ///   parameters: AppsFlyerInviteLinkParams(channel: 'whatsapp'),
  /// );
  /// ```
  Future<String> generateInviteLink({
    AppsFlyerInviteLinkParams? parameters,
    bool awaitResponse = true,
  }) async {
    final params = (parameters ?? const AppsFlyerInviteLinkParams()).toRpcMap(
      isIOS: _isIOS,
    );
    if (_isAndroid) {
      params['awaitResponse'] = awaitResponse;
    }
    return _invokeRpc<String>('generateInviteLink', params);
  }

  /// Logs the `af_invite` event when a user shares an invite.
  ///
  /// [channel] is the sharing channel, such as `"facebook"`.
  /// [eventParameters] contains optional additional event values.
  Future<void> logInvite(
    String channel, [
    Map<String, String>? eventParameters,
  ]) {
    return _invokeVoidRpc('logInvite', {
      'channel': channel,
      'eventParameters': eventParameters,
    });
  }

  /// Resolves [url] and delivers the result through [onDeepLinkReceived].
  ///
  /// The URL can be a full URL, OneLink, or Android intent-data string.
  /// On Android, set [shouldTriggerSession] to `true` to also enqueue a Launch
  /// for re-engagement. iOS ignores [shouldTriggerSession].
  Future<void> performDeepLinking(
    String url, {
    bool shouldTriggerSession = false,
  }) {
    return _invokeVoidRpc(
      _isAndroid ? 'performDeepLinking' : 'performOnAppAttributionWithURL',
      _isAndroid
          ? {
              'url': url,
              'shouldTriggerSession': shouldTriggerSession,
            }
          : {'url': url},
    );
  }

  /// Resolves OneLink URLs wrapped inside another Universal Link or App Link
  /// domain that you own.
  ///
  /// For example, pass `["click.example.com"]`. [urls] must be non-empty.
  Future<void> setResolveDeepLinkURLs(List<String> urls) {
    return _invokeVoidRpc('setResolveDeepLinkURLs', {'urls': urls});
  }

  /// Registers custom or branded OneLink domains.
  ///
  /// For example, pass `["click.greatapp.com"]`. [domains] must be non-empty.
  Future<void> setOneLinkCustomDomain(List<String> domains) {
    return _invokeVoidRpc(
      'setOneLinkCustomDomain',
      {'domains': domains},
    );
  }

  /// Sets the deep-link resolution timeout in milliseconds.
  ///
  /// Call before [init]. When this method is not called, the default is 3000 ms
  /// on Android and 60000 ms on iOS. Android requires a positive value; iOS
  /// accepts zero, but use a positive value for consistent behavior.
  Future<void> setDeepLinkTimeout(int timeout) {
    return _invokeVoidRpc(
      'setDeepLinkTimeout',
      {'timeout': timeout},
    );
  }

  /// Registers the ordered JSON key path of a OneLink nested in a push payload.
  ///
  /// For example, `["deeply", "nested", "link"]`. [deepLinkPath] must be
  /// non-empty. Call before [init].
  /// On iOS, also forward the notification payload with
  /// [handlePushNotification].
  Future<void> addPushNotificationDeepLinkPath(List<String> deepLinkPath) {
    return _invokeVoidRpc(
      'addPushNotificationDeepLinkPath',
      {'deepLinkPath': deepLinkPath},
    );
  }

  /// Enables or disables Facebook deferred app-link resolution.
  ///
  /// On iOS, the Facebook SDK must be linked for this integration.
  Future<void> enableFacebookDeferredApplinks(bool isEnabled) {
    return _invokeVoidRpc(
      'enableFacebookDeferredApplinks',
      {'isEnabled': isEnabled},
    );
  }

  /// Appends [parameters] to deep-link URLs containing [contains] before the SDK
  /// resolves them.
  ///
  /// [contains] must be non-empty. iOS also requires [parameters] to be
  /// non-empty.
  Future<void> appendParametersToDeepLinkingURL(
    String contains,
    Map<String, String> parameters,
  ) {
    return _invokeVoidRpc('appendParametersToDeepLinkingURL', {
      'contains': contains,
      'parameters': parameters,
    });
  }

  /// Sets or clears the Facebook deferred app-link URL directly.
  ///
  /// iOS only. Pass `null` to clear the current URL. Use this when the
  /// application already holds the deferred link. Invalid URLs and dangerous
  /// schemes such as `javascript:` are rejected with an
  /// [AppsFlyerException].
  Future<void> setFacebookDeferredAppLink(String? url) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('setFacebookDeferredAppLink', 'iOS');
      return;
    }
    return _invokeVoidRpc('setFacebookDeferredAppLink', {'url': url});
  }

  /// Measures an Android push-notification campaign.
  ///
  /// Android only. [campaign] and [pid] are required by the native SDK.
  Future<void> sendPushNotificationData({
    required String campaign,
    required String pid,
    bool isRetargeting = false,
    Map<String, dynamic>? additionalParameters,
  }) async {
    if (!_isAndroid) {
      _logUnsupportedPlatform('sendPushNotificationData', 'Android');
      return;
    }
    return _invokeVoidRpc('sendPushNotificationData', {
      'campaign': campaign,
      'pid': pid,
      'isRetargeting': isRetargeting,
      'additionalParameters': additionalParameters,
    });
  }

  /// Passes an APNs push-notification payload to the iOS SDK.
  ///
  /// iOS only. Pass the complete notification `userInfo` dictionary.
  Future<void> handlePushNotification(
    Map<String, dynamic> pushPayload,
  ) async {
    if (!_isIOS) {
      _logUnsupportedPlatform('handlePushNotification', 'iOS');
      return;
    }
    return _invokeVoidRpc(
      'handlePushNotification',
      {'pushPayload': pushPayload},
    );
  }

  /// Passes the device token to AppsFlyer for uninstall measurement.
  ///
  /// On Android, pass the FCM registration token. On iOS, pass the APNs device
  /// token as an even-length hexadecimal string. The same [token] parameter is
  /// used on both platforms.
  Future<void> updateServerUninstallToken(String token) {
    return _isAndroid
        ? _invokeVoidRpc('updateServerUninstallToken', {'token': token})
        : _invokeVoidRpc('registerUninstall', {'deviceToken': token});
  }

  /// Returns the native AppsFlyer SDK version.
  Future<String> getSdkVersion() {
    return _invokeRpc<String>('getSdkVersion');
  }

  /// Returns the AppsFlyer unique device ID created for this install.
  Future<String?> getAppsFlyerUID() {
    return _invokeNullableRpc<String?>('getAppsFlyerUID');
  }

  /// Whether the app was installed as an OEM or manufacturer preinstall.
  ///
  /// Android only.
  Future<bool> isPreInstalledApp() {
    return _invokeRpc<bool>('isPreInstalledApp');
  }

  /// Returns the Facebook attribution ID, if available.
  ///
  /// Android only.
  Future<String?> getAttributionId() {
    return _invokeNullableRpc<String?>('getAttributionId');
  }

  Future<void> _invokeVoidRpc(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    await _invokeNullableRpc<Object?>(method, params);
  }

  /// Calls [method] via the RPC channel and casts the result to [T].
  ///
  /// [T] may be nullable — pass e.g. `String?` when the native side may
  /// legitimately return no value.
  Future<T> _invokeNullableRpc<T>(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final dynamic result = await _methodChannel.invokeMethod<dynamic>(
        'executeRpc',
        <String, dynamic>{
          'method': method,
          'params': params ?? <String, dynamic>{},
        },
      );
      if (result != null && result is! T) {
        throw AppsFlyerException(
          message:
              'Unexpected RPC result type for $method: ${result.runtimeType}',
        );
      }
      return result as T;
    } on PlatformException catch (error) {
      throw AppsFlyerException.fromPlatformException(error);
    }
  }

  /// Calls [method] via the RPC channel and requires a non-null result.
  ///
  /// Throws [AppsFlyerException] if the native side unexpectedly returns no
  /// value.
  Future<T> _invokeRpc<T extends Object>(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    final result = await _invokeNullableRpc<T?>(method, params);
    if (result == null) {
      throw AppsFlyerException(message: '$method returned no value');
    }
    return result;
  }

  void _logIgnoredCall(String method, String reason) {
    debugPrint('AppsFlyer: $method ignored — $reason.');
  }

  void _logUnsupportedPlatform(String method, String supportedPlatform) {
    _logIgnoredCall(method, 'supported only on $supportedPlatform');
  }
}
