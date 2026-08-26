part of appsflyer_sdk;

/// Called with install and attribution conversion data (GCD).
typedef OnConversionDataSuccess = void Function(Map<String, dynamic> data);

/// Called when the native SDK fails to retrieve conversion data.
///
/// The payload shape differs by platform: Android reports `{"error": String}`
/// with no error code; iOS reports `{"error": String, "code": int}`.
typedef OnConversionDataFailure = void Function(Map<String, dynamic> error);

/// Called with a Unified Deep Linking result.
typedef OnDeepLinkReceived = void Function(DeepLinkResult result);

/// Called once per foreground cycle when the SDK is ready to send a session.
typedef OnSessionReady = void Function();

/// Whether the plugin's own diagnostics are printed.
///
/// Debug builds print them. Release builds stay quiet until the app opts in
/// through [AppsFlyerSdk.enableDebug], the same switch that turns on native SDK
/// logging, so both layers answer to one setting.
bool _pluginLoggingEnabled = false;

/// Prints [message] when plugin logging is on.
///
/// `debugPrint` itself is not compiled out of release builds, so every call site
/// goes through here instead.
void _log(String message) {
  if (kDebugMode || _pluginLoggingEnabled) {
    debugPrint(message);
  }
}

/// Throws [AppsFlyerException] when this isolate cannot reach the platform
/// channels.
///
/// Platform channels are bound to the root isolate. A background isolate — the
/// one a push handler or a scheduled background task runs in — reaches them
/// only after calling `BackgroundIsolateBinaryMessenger.ensureInitialized`
/// with the root isolate's token; both cases are allowed here.
///
/// Without this check the underlying `StateError` escapes the event stream's
/// subscribe callback rather than the returned [Future], which no `try`/`catch`
/// around the call can intercept, and it terminates the isolate.
void _ensureIsolateCanReachPlatform() {
  if (RootIsolateToken.instance != null) {
    return;
  }
  try {
    BackgroundIsolateBinaryMessenger.instance;
  } catch (_) {
    throw const AppsFlyerException(
      message:
          'AppsFlyerSdk was called from a background isolate that cannot '
          'reach the platform channels. Call the SDK from the main isolate, '
          'or initialize the background isolate with '
          'BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken) '
          'before calling it. AppsFlyerSdk.instance is per-isolate, so the '
          'instance in a background isolate is not the one you configured.',
    );
  }
}

/// The AppsFlyer SDK entry point.
///
/// Use the shared [instance] to configure and initialize the SDK. Each event
/// takes its callback as an argument to its `register*Listener` method; the
/// plugin holds one callback per event and replaces it on re-registration, the
/// same contract as the native SDKs.
///
/// **Multi-engine hosts:** the native SDK and plugin transport are
/// process-scoped. When more than one Flutter engine is alive, only the engine
/// whose event subscription attached most recently receives native events,
/// and the last `register*Listener()` from any engine wins at the native layer.
/// Integrate from one primary engine. See `doc/getting-started.md#multi-engine`.
///
/// Initialization does not send a session. Register the session-ready listener
/// and call [start] from its callback:
///
/// ```dart
/// final appsFlyer = AppsFlyerSdk.instance;
///
/// await appsFlyer.init(
///   devKey: 'YOUR_DEV_KEY',
///   appId: 'YOUR_APP_ID',
/// );
/// await appsFlyer.registerSessionReadyListener(() async {
///   await appsFlyer.start();
/// });
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
    this._eventChannel, {
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform;

  final TargetPlatform _platform;

  bool get _isIOS => _platform == TargetPlatform.iOS;

  bool get _isAndroid => _platform == TargetPlatform.android;

  /// Returns the Flutter plugin version.
  String get pluginVersion => _AppsFlyerConstants.PLUGIN_VERSION;

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final _AppsFlyerListenerRegistry _listeners = _AppsFlyerListenerRegistry();
  StreamSubscription<dynamic>? _eventSubscription;

  /// Attaches the plugin's single `af-events` subscription on first use.
  ///
  /// Deferred until the first registration so nothing is read from the native
  /// buffers before the app has asked for events. Both platforms replay their
  /// whole buffer on attach, including events for listeners registered later in
  /// the sequence; [_AppsFlyerListenerRegistry] holds those until their
  /// callback arrives.
  void _ensureEventsSubscribed() {
    _ensureIsolateCanReachPlatform();
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _handleNativeEvent,
      onError: (Object error, StackTrace stackTrace) {
        _log('AppsFlyer: event stream error (${_describeError(error)}).');
      },
    );
  }

  void _handleNativeEvent(dynamic value) {
    final _AppsFlyerEvent event;
    try {
      if (value is! String) {
        throw FormatException(
          'AppsFlyer event must be a JSON string, got ${value.runtimeType}',
        );
      }
      event = _AppsFlyerEvent.fromNative(value);
    } catch (error) {
      _log(
        'AppsFlyer: dropped malformed native event (${_describeError(error)}).',
      );
      return;
    }
    _listeners.dispatch(event);
  }

  /// Describes [error] without reproducing the payload that produced it.
  ///
  /// `FormatException.toString()` appends an excerpt of the string it failed to
  /// parse, and a native [PlatformException] carries the event body in its
  /// `message` and `details`. That body holds attribution data — click and
  /// deep-link identifiers among it — and these lines reach the host app's log
  /// in release builds, so only the type and the platform error code are named.
  static String _describeError(Object error) {
    if (error is PlatformException) {
      return '${error.runtimeType}: ${error.code}';
    }
    return '${error.runtimeType}';
  }

  /// Initializes the SDK with [devKey] and, on iOS, [appId].
  ///
  /// Does not send a session.
  ///
  /// If your app handles deep links, call [registerDeepLinkListener] before
  /// this method; the other `register*Listener` methods are called after it.
  ///
  /// [appId] is required by the native iOS SDK and is not sent to Android.
  /// Input validation is performed by the native layer.
  Future<void> init({required String devKey, String? appId}) {
    return _invokeVoidRpc(
      'init',
      _isIOS ? {'devKey': devKey, 'appId': appId} : {'devKey': devKey},
    );
  }

  /// Registers the install and attribution conversion-data listener.
  ///
  /// [onConversionDataSuccess] receives the conversion data (GCD).
  /// [onConversionDataFail] receives retrieval failures: this registration can
  /// succeed while the native SDK still fails to retrieve conversion data.
  ///
  /// Both callbacks are optional; pass the ones you need. Calling this again
  /// replaces both.
  ///
  /// Throws [AppsFlyerException] when the native call fails. Neither callback
  /// is installed in that case, and callbacks from an earlier successful call
  /// stay in place, so a failed call changes nothing.
  Future<void> registerConversionListener({
    OnConversionDataSuccess? onConversionDataSuccess,
    OnConversionDataFailure? onConversionDataFail,
  }) async {
    _ensureEventsSubscribed();
    const eventNames = [
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_SUCCESS,
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_FAIL,
    ];
    final previous = _listeners.snapshot(eventNames);
    _listeners.on(
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_SUCCESS,
      (event) => onConversionDataSuccess?.call(event.data),
    );
    _listeners.on(
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_FAIL,
      (event) => onConversionDataFail?.call(event.data),
    );
    try {
      await _invokeVoidRpc('registerConversionListener');
    } catch (error) {
      _listeners.rollback(eventNames, previous);
      rethrow;
    }
  }

  /// Unregisters the native Android conversion-data listener and drops the
  /// callbacks passed to [registerConversionListener].
  ///
  /// This API is available only on Android. Call [registerConversionListener]
  /// again to resume receiving conversion-data events.
  ///
  /// Throws [AppsFlyerException] when the native call fails, including on iOS,
  /// where the SDK has no matching operation. The callbacks are left in place in
  /// that case, so a failed call changes nothing.
  Future<void> unregisterConversionListener() async {
    final restore = _listeners.take(const [
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_SUCCESS,
      _AppsFlyerConstants.EVENT_CONVERSION_DATA_FAIL,
    ]);
    try {
      await _invokeVoidRpc('unregisterConversionListener');
    } catch (error) {
      _listeners.restore(restore);
      rethrow;
    }
  }

  /// Registers the Unified Deep Linking listener.
  ///
  /// [onDeepLinking] receives every resolved deep link, deferred or direct. It
  /// is optional, so the native listener can be registered on its own. Calling
  /// this again replaces the callback.
  ///
  /// Call this **before** [init]. On Android, [init] hands the launch intent to
  /// the native SDK, which decides once per install whether to send the deferred
  /// deep-link resolution request; registering afterwards means that request is
  /// never sent for that install, and the skipped state persists across
  /// launches. Direct links are unaffected. Registration before [init] is
  /// supported on both platforms.
  ///
  /// Throws [AppsFlyerException] when the native call fails. The callback is
  /// not installed in that case, and a callback from an earlier successful
  /// call stays in place, so a failed call changes nothing.
  Future<void> registerDeepLinkListener({
    OnDeepLinkReceived? onDeepLinking,
  }) async {
    _ensureEventsSubscribed();
    void dispatch(_AppsFlyerEvent event) => onDeepLinking?.call(
      DeepLinkResult._fromEvent(event, platform: _platform),
    );
    // Android emits onDeepLinking, iOS emits onDeepLinkReceived.
    const eventNames = [
      _AppsFlyerConstants.EVENT_DEEP_LINKING,
      _AppsFlyerConstants.EVENT_DEEP_LINK_RECEIVED,
    ];
    final previous = _listeners.snapshot(eventNames);
    _listeners.on(_AppsFlyerConstants.EVENT_DEEP_LINKING, dispatch);
    _listeners.on(_AppsFlyerConstants.EVENT_DEEP_LINK_RECEIVED, dispatch);
    try {
      await _invokeVoidRpc(
        _isAndroid ? 'subscribeForDeepLink' : 'registerDeeplinkListener',
      );
    } catch (error) {
      _listeners.rollback(eventNames, previous);
      rethrow;
    }
  }

  /// Requests removal of the Unified Deep Linking listener on Android and drops
  /// the callback passed to [registerDeepLinkListener].
  ///
  /// Throws [AppsFlyerException] when the native call fails, including on iOS,
  /// where the SDK has no matching operation. The callback is left in place in
  /// that case, so a failed call changes nothing.
  Future<void> unregisterDeepLinkListener() async {
    final restore = _listeners.take(const [
      _AppsFlyerConstants.EVENT_DEEP_LINKING,
      _AppsFlyerConstants.EVENT_DEEP_LINK_RECEIVED,
    ]);
    try {
      await _invokeVoidRpc('unsubscribeForDeepLink');
    } catch (error) {
      _listeners.restore(restore);
      rethrow;
    }
  }

  /// Registers the session-ready listener.
  ///
  /// The SDK invokes [onReady] once per foreground cycle when it is ready to
  /// send a session. Call [start] from that callback:
  ///
  /// ```dart
  /// await appsFlyer.registerSessionReadyListener(() => appsFlyer.start());
  /// ```
  ///
  /// Calling this again replaces the callback, so [start] is never issued twice
  /// for one readiness event.
  ///
  /// Throws [AppsFlyerException] when the native call fails. The callback is
  /// not installed in that case, and a callback from an earlier successful
  /// call stays in place, so a failed call changes nothing.
  Future<void> registerSessionReadyListener(OnSessionReady onReady) async {
    _ensureEventsSubscribed();
    const eventNames = [_AppsFlyerConstants.EVENT_SESSION_READY];
    final previous = _listeners.snapshot(eventNames);
    _listeners.on(_AppsFlyerConstants.EVENT_SESSION_READY, (_) => onReady());
    try {
      await _invokeVoidRpc('registerSessionReadyListener');
    } catch (error) {
      _listeners.rollback(eventNames, previous);
      rethrow;
    }
  }

  /// Removes the listener registered by [registerSessionReadyListener] and
  /// drops its callback.
  ///
  /// Throws [AppsFlyerException] when the native call fails, leaving the
  /// callback in place, so a failed call changes nothing.
  Future<void> unregisterSessionReadyListener() async {
    final restore = _listeners.take(const [
      _AppsFlyerConstants.EVENT_SESSION_READY,
    ]);
    try {
      await _invokeVoidRpc('unregisterSessionReadyListener');
    } catch (error) {
      _listeners.restore(restore);
      rethrow;
    }
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
  /// Call once for each [registerSessionReadyListener] callback invocation.
  /// Defer this call when the first session must wait for consent or another
  /// application condition.
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

  /// Collects the open/web referrer from the launcher activity's intent.
  ///
  /// **Android only.** Call before [start] so the referrer reaches the first
  /// session. Requires an attached activity: when the plugin has none, the
  /// native layer rejects the call with [AppsFlyerException] (code `422`).
  Future<void> collectDataFromLauncherActivity() {
    return _invokeVoidRpc('collectDataFromLauncherActivity');
  }

  /// Enables or disables SDK debug logging, native and plugin alike.
  ///
  /// May be called before [init]. Call before [start] so the first session
  /// uses the selected setting.
  ///
  /// The plugin's own diagnostics follow this setting in release builds; debug
  /// builds always print them. The setting applies to the calling isolate.
  Future<void> enableDebug(bool enabled) async {
    final previous = _pluginLoggingEnabled;
    _pluginLoggingEnabled = enabled;
    try {
      await _invokeVoidRpc('isDebug', {'isDebug': enabled});
    } catch (error) {
      _pluginLoggingEnabled = previous;
      rethrow;
    }
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
    return _invokeVoidRpc('setLogLevel', {'logLevel': logLevel.rpcValue});
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
  /// Android only. For typical Flutter apps, call [start] from the
  /// [registerSessionReadyListener] callback instead.
  Future<void> logSession() async {
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
    return _invokeVoidRpc('setCurrencyCode', {'currencyCode': currencyCode});
  }

  /// Sets the minimum time between two launches for them to count as separate
  /// sessions.
  ///
  /// [seconds] is the minimum interval in seconds.
  Future<void> setMinTimeBetweenSessions(int seconds) {
    return _invokeVoidRpc('setMinTimeBetweenSessions', {'seconds': seconds});
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
  /// Returns an empty string on iOS when [setHost] has not been called.
  Future<String> getHostName() {
    return _invokeRpc<String>('getHostName');
  }

  /// Returns the configured host prefix.
  ///
  /// Returns an empty string on iOS when [setHost] has not been called.
  Future<String> getHostPrefix() {
    return _invokeRpc<String>('getHostPrefix');
  }

  /// Sets additional custom data sent to AppsFlyer.
  ///
  /// Pass an empty map to clear previously supplied data.
  Future<void> setAdditionalData(Map<String, dynamic> customData) {
    return _invokeVoidRpc('setAdditionalData', {'customData': customData});
  }

  /// Sets the OneLink ID used as the base for links from [generateInviteLink].
  Future<void> setAppInviteOneLink(String oneLinkId) {
    return _invokeVoidRpc('setAppInviteOneLink', {'oneLinkId': oneLinkId});
  }

  /// Sets partner-specific data.
  ///
  /// [partnerId] identifies the partner and [data] contains the data
  /// supplied to that partner.
  Future<void> setPartnerData(String partnerId, Map<String, dynamic> data) {
    return _invokeVoidRpc('setPartnerData', {
      'partnerId': partnerId,
      'data': data,
    });
  }

  /// Blocks sharing of S2S events through postback or API with the specified
  /// partners.
  ///
  /// Pass `null` or an empty list to clear the filter. The plugin normalizes
  /// an empty list to `null` before sending the native request, so the two are
  /// interchangeable.
  Future<void> setSharingFilterForPartners(List<String>? partners) {
    return _invokeVoidRpc('setSharingFilterForPartners', {
      'partners': partners != null && partners.isEmpty ? null : partners,
    });
  }

  /// Sets the out-of-store install source.
  ///
  /// Android only.
  Future<void> setOutOfStore(String sourceName) async {
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
    return _invokeVoidRpc('setIsUpdate', {'isUpdate': isUpdate});
  }

  /// Overrides the device language reported to the SDK.
  ///
  /// iOS only.
  Future<void> setCurrentDeviceLanguage(String language) async {
    return _invokeVoidRpc('setCurrentDeviceLanguage', {'language': language});
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
    return _invokeVoidRpc('setAppId', {'appId': appId});
  }

  /// Sets GDPR and DMA consent data.
  ///
  /// Provide the current consent on every app start before [start]. Consent
  /// values are not persisted across sessions.
  ///
  /// [isUserSubjectToGDPR] is always required. When it is `false`, the other
  /// three fields may be omitted or `null` (non-GDPR users). When it is `true`,
  /// supply meaningful values for the consent fields before the first
  /// [start].
  Future<void> setConsentData({
    required bool isUserSubjectToGDPR,
    bool? hasConsentForDataUsage,
    bool? hasConsentForAdsPersonalization,
    bool? hasConsentForAdStorage,
  }) {
    return _invokeVoidRpc('setConsentData', {
      'isUserSubjectToGDPR': isUserSubjectToGDPR,
      'hasConsentForDataUsage': hasConsentForDataUsage,
      'hasConsentForAdsPersonalization': hasConsentForAdsPersonalization,
      'hasConsentForAdStorage': hasConsentForAdStorage,
    });
  }

  /// Enables or disables automatic collection of IAB TCF consent data.
  Future<void> enableTCFDataCollection(bool shouldCollect) {
    return _invokeVoidRpc('enableTCFDataCollection', {
      'shouldCollect': shouldCollect,
    });
  }

  /// Anonymizes user data.
  Future<void> anonymizeUser(bool shouldAnonymize) {
    return _invokeVoidRpc('anonymizeUser', {
      'shouldAnonymize': shouldAnonymize,
    });
  }

  /// Stops or resumes all SDK activity and communication with AppsFlyer
  /// servers.
  ///
  /// Pass `true` to stop the SDK and `false` to resume it.
  Future<void> stop(bool shouldStop) {
    return _invokeVoidRpc('stop', {'shouldStop': shouldStop});
  }

  /// Whether the SDK is currently stopped.
  Future<bool> isStopped() async {
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
    return _invokeVoidRpc('setDisableCollectASA', {'disable': disable});
  }

  /// Enables or disables Android ID collection.
  ///
  /// Android only. Apps distributed through Google Play should follow Google
  /// Play policy when configuring this value.
  Future<void> setCollectAndroidID(bool isCollect) async {
    return _invokeVoidRpc('setCollectAndroidID', {'isCollect': isCollect});
  }

  /// Disables collection of the network carrier and SIM operator names.
  ///
  /// Android only.
  Future<void> setDisableNetworkData(bool isDisable) async {
    return _invokeVoidRpc('setDisableNetworkData', {'isDisable': isDisable});
  }

  /// Disables App Set ID collection.
  ///
  /// Android only.
  Future<void> disableAppSetId() async {
    return _invokeVoidRpc('disableAppSetId');
  }

  /// Disables SKAdNetwork attribution.
  ///
  /// iOS only. Pass `true` to disable SKAdNetwork.
  Future<void> setDisableSKAdNetwork(bool disable) async {
    return _invokeVoidRpc('setDisableSKAdNetwork', {'disable': disable});
  }

  /// Disables Apple Ads attribution.
  ///
  /// iOS only. Call before [start].
  Future<void> setDisableAppleAdsAttribution(bool disable) async {
    return _invokeVoidRpc('setDisableAppleAdsAttribution', {
      'disable': disable,
    });
  }

  /// Disables collection of the Identifier for Vendor (IDFV).
  ///
  /// iOS only. Call before [start].
  Future<void> setDisableIDFVCollection(bool disable) async {
    return _invokeVoidRpc('setDisableIDFVCollection', {'disable': disable});
  }

  /// Enables device-name collection.
  ///
  /// iOS only. Collection is disabled by default. Call before [start], and
  /// enable it only when your privacy policy covers collection of the device
  /// name.
  Future<void> setShouldCollectDeviceName(bool collect) async {
    return _invokeVoidRpc('setShouldCollectDeviceName', {'collect': collect});
  }

  /// Validates and logs an in-app purchase.
  ///
  /// [purchase] is an [AFAndroidPurchaseDetails] or [AFIOSPurchaseDetails]
  /// instance for the current platform.
  /// [additionalParameters] contains optional values to include with the
  /// validation request.
  ///
  /// Both platforms always wait for the native validation result: the [Future]
  /// completes with that result, or throws [AppsFlyerException] when validation
  /// fails. Android times out after 5 seconds, iOS after 30.
  Future<Map<String, dynamic>> validateAndLogInAppPurchase(
    AFPurchaseDetails purchase, {
    Map<String, String>? additionalParameters,
  }) async {
    final params = purchase.toRpcMap(
      platform: _platform,
      additionalParameters: additionalParameters,
    );
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
    return _invokeVoidRpc('setUseReceiptValidationSandbox', {
      'sandbox': sandbox,
    });
  }

  /// Enables sandbox mode for uninstall-measurement validation.
  ///
  /// iOS only. This is the uninstall-measurement companion to
  /// [setUseReceiptValidationSandbox].
  Future<void> setUseUninstallSandbox(bool sandbox) {
    return _invokeVoidRpc('setUseUninstallSandbox', {'sandbox': sandbox});
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

  /// Resolves [url] and delivers the result to the [registerDeepLinkListener]
  /// callback.
  ///
  /// The URL can be a full URL, OneLink, or Android intent-data string.
  /// On Android, set [shouldTriggerSession] to `true` to also enqueue a Launch
  /// for re-engagement. iOS ignores [shouldTriggerSession].
  Future<void> performDeepLinking(
    String url, {
    bool shouldTriggerSession = false,
  }) {
    return _invokeVoidRpc(
      'performDeepLinking',
      _isAndroid
          ? {'url': url, 'shouldTriggerSession': shouldTriggerSession}
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
    return _invokeVoidRpc('setOneLinkCustomDomain', {'domains': domains});
  }

  /// Sets the deep-link resolution timeout in milliseconds.
  ///
  /// Call before [init]. When this method is not called, the default is 3000 ms
  /// on Android and 60000 ms on iOS. Android requires a positive value; iOS
  /// accepts zero, but use a positive value for consistent behavior.
  Future<void> setDeepLinkTimeout(int timeout) {
    return _invokeVoidRpc('setDeepLinkTimeout', {'timeout': timeout});
  }

  /// Registers the ordered JSON key path of a OneLink nested in a push payload.
  ///
  /// For example, `["deeply", "nested", "link"]`. [deepLinkPath] must be
  /// non-empty. Call before [init].
  /// On iOS, also forward the notification payload with
  /// [handlePushNotification].
  Future<void> addPushNotificationDeepLinkPath(List<String> deepLinkPath) {
    return _invokeVoidRpc('addPushNotificationDeepLinkPath', {
      'deepLinkPath': deepLinkPath,
    });
  }

  /// Enables or disables Facebook deferred app-link resolution.
  ///
  /// On iOS, the Facebook SDK must be linked for this integration.
  Future<void> enableFacebookDeferredApplinks(bool isEnabled) {
    return _invokeVoidRpc('enableFacebookDeferredApplinks', {
      'isEnabled': isEnabled,
    });
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
  Future<void> handlePushNotification(Map<String, dynamic> pushPayload) async {
    return _invokeVoidRpc('handlePushNotification', {
      'pushPayload': pushPayload,
    });
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
    _ensureIsolateCanReachPlatform();
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
}
