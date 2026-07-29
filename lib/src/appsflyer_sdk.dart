part of appsflyer_sdk;

class AppsflyerSdk {
  static AppsflyerSdk? _instance;
  final MethodChannel _methodChannel;

  final AppsFlyerOptions? _afOptions;
  final Map? _mapOptions;

  /// Returns the singleton [AppsflyerSdk] instance, configured with [options].
  ///
  /// [options] must be an [AppsFlyerOptions] or a configuration [Map] (see
  /// `doc/api-reference.md`); any other type throws an [ArgumentError]. The instance is a
  /// singleton — [options] passed to later calls are ignored.
  factory AppsflyerSdk(dynamic options) {
    if (_instance == null) {
      MethodChannel methodChannel =
          const MethodChannel(AppsflyerConstants.AF_METHOD_CHANNEL);

      if (options is AppsFlyerOptions) {
        _instance = AppsflyerSdk.private(methodChannel, afOptions: options);
      } else if (options is Map) {
        _instance = AppsflyerSdk.private(methodChannel, mapOptions: options);
      } else {
        throw ArgumentError.value(options, 'options',
            'Must be an AppsFlyerOptions instance or a Map of configuration values');
      }
    }
    return _instance!;
  }

  @visibleForTesting
  AppsflyerSdk.private(this._methodChannel,
      {AppsFlyerOptions? afOptions, Map? mapOptions})
      : _afOptions = afOptions,
        _mapOptions = mapOptions;

  /// Sends a single `{method, params}` RPC to the native bridge.
  Future<T?> _executeRpc<T>(String method, [Map<String, dynamic>? params]) {
    return _methodChannel.invokeMethod<T>(
      'executeRpc',
      <String, dynamic>{
        'method': method,
        'params': params ?? <String, dynamic>{}
      },
    );
  }

  /// Runs an RPC whose result is reported through optional [onSuccess] /
  /// [onError] callbacks. With no callback the call is fire-and-forget.
  void _executeRequest(
    String method,
    Map<String, dynamic>? params, {
    RequestSuccessListener? onSuccess,
    RequestErrorListener? onError,
  }) {
    final bool wantsResult = onSuccess != null || onError != null;
    final Future<dynamic> future = _executeRpc(method, <String, dynamic>{
      ...?params,
      'awaitResponse': wantsResult,
    });
    if (!wantsResult) {
      return;
    }
    future.then((dynamic _) => onSuccess?.call()).catchError((Object e) {
      int errorCode = 0;
      String errorMessage = e.toString();
      if (e is PlatformException) {
        errorCode = int.tryParse(e.code) ?? 0;
        errorMessage = e.message ?? '';
      }
      onError?.call(errorCode, errorMessage);
    });
  }

  /// Validates [AppsFlyerOptions] and converts them to a map acceptable for the AppsFlyer SDK.
  Map<String, dynamic> _validateAFOptions(AppsFlyerOptions options) {
    Map<String, dynamic> validatedOptions = {};

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

  // ---------------------------------------------------------------------------
  // Lifecycle & session
  // ---------------------------------------------------------------------------

  /// Initializes the SDK with the constructor options.
  ///
  /// Initialization alone does not send a session — call [startSDK] for that.
  ///
  /// To receive conversion data or deep links you must do **both**: pass the
  /// flag here *and* register the paired listener before calling [initSdk] —
  /// [registerConversionDataCallback] with [onInstallConversionData], and
  /// [registerOnDeepLinkingCallback] with [onDeepLinking]. A flag without its
  /// listener (or vice versa) delivers nothing.
  Future<dynamic> initSdk(
      {bool registerConversionDataCallback = false,
      bool registerOnDeepLinkingCallback = false}) async {
    Map<String, dynamic>? validatedOptions;
    if (_mapOptions != null) {
      validatedOptions = _validateMapOptions(_mapOptions!);
    } else if (_afOptions != null) {
      validatedOptions = _validateAFOptions(_afOptions!);
    }

    if (validatedOptions == null) {
      throw StateError(
          'AppsflyerSdk was constructed without valid options; cannot initialize the SDK.');
    }

    validatedOptions[AppsflyerConstants.AF_GCD] = registerConversionDataCallback;
    validatedOptions[AppsflyerConstants.AF_UDL] = registerOnDeepLinkingCallback;

    return _executeRpc('init', validatedOptions);
  }

  /// Sends a session ("Launch").
  ///
  /// Must be called once per foreground cycle — the SDK resets its started flag
  /// whenever the app is backgrounded — typically from the
  /// [registerSessionReadyListener] callback. Defer the call to gate the first
  /// session (e.g. on consent). Calling it again within the same foreground
  /// cycle is a no-op.
  ///
  /// Optionally pass [onSuccess] / [onError] to observe the request result;
  /// without them the call is fire-and-forget.
  void startSDK({
    RequestSuccessListener? onSuccess,
    RequestErrorListener? onError,
  }) {
    _executeRequest('start', null, onSuccess: onSuccess, onError: onError);
  }

  /// Registers a callback invoked, once per foreground cycle, when the SDK is
  /// ready to send a session. Call [startSDK] from inside it:
  ///
  /// ```dart
  /// appsflyer.registerSessionReadyListener((_) => appsflyer.startSDK());
  /// ```
  ///
  /// Register before [initSdk] so the first signal is not missed; use
  /// [isSessionReady] if you register later. The callback receives a
  /// `{status, payload}` map.
  void registerSessionReadyListener(MultiUseCallback callback) {
    _startListening(callback, "onSessionReady");
  }

  /// Removes the Dart observer added by [registerSessionReadyListener].
  ///
  /// Observer-only: stops Dart-side routing but leaves the SDK's session-ready
  /// listener active, so you can re-register later.
  void unregisterSessionReadyListener() {
    _stopListening("onSessionReady");
  }

  /// Whether all session-readiness conditions are currently met.
  ///
  /// Useful when [registerSessionReadyListener] was attached late. Never throws
  /// — a bridge failure resolves to `false`.
  Future<bool> isSessionReady() async {
    try {
      final bool? result = await _executeRpc<bool>('isSessionReady');
      return result ?? false;
    } on PlatformException {
      // A readiness probe should never throw; treat a bridge/RPC failure as "not ready".
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Attribution & conversion
  // ---------------------------------------------------------------------------

  /// Listens for install / attribution conversion data (GCD).
  ///
  /// Requires **both** this callback and `registerConversionDataCallback: true`
  /// in [initSdk]; register before [initSdk] so the first result is not missed.
  ///
  /// The callback receives a `{status, payload}` map (identical on both
  /// platforms): `status` is `"success"` or `"failure"`; `payload` is the
  /// conversion-data map on success or an error map on failure (may be `null`).
  /// Call [unregisterConversionDataListener] to stop receiving it.
  void onInstallConversionData(MultiUseCallback callback) {
    _startListening(callback, "onInstallConversionData");
  }

  /// Removes the Dart observer added by [onInstallConversionData].
  ///
  /// Observer-only: stops Dart-side routing but leaves the native SDK listener
  /// in place. Rarely needed — GCD is delivered once per install.
  void unregisterConversionDataListener() {
    _stopListening("onInstallConversionData");
  }

  /// Returns the Facebook (Katana) attribution ID, if any.
  ///
  /// Android only — resolves to `null` on iOS.
  Future<String?> getAttributionId() async {
    if (Platform.isAndroid) {
      return _executeRpc<String>('getAttributionId');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Deep linking (UDL / OneLink)
  // ---------------------------------------------------------------------------

  /// Handles Unified Deep Linking (UDL) results.
  ///
  /// Requires **both** this callback and `registerOnDeepLinkingCallback: true`
  /// in [initSdk]; register before [initSdk] so a launch deep link is not missed.
  void onDeepLinking(UDLCallback callback) {
    _startListeningToUDL(callback, "onDeepLinking");
  }

  /// Resolves [url] (full URL, OneLink, or intent-data string) and routes the
  /// result to the [onDeepLinking] listener. Works for intent and non-intent
  /// sources (e.g. Firebase Messaging).
  ///
  /// [shouldTriggerSession] (default `false`): when `true`, also enqueues a
  /// Launch for re-engagement. Android only — ignored on iOS.
  void performDeepLinking(String url, {bool shouldTriggerSession = false}) {
    if (Platform.isAndroid) {
      _executeRpc('performDeepLinking',
          {'url': url, 'shouldTriggerSession': shouldTriggerSession});
    } else {
      _executeRpc('performOnAppAttributionWithURL', {'url': url});
    }
  }

  /// Resolves OneLink URLs wrapped inside another Universal Link / App Link
  /// domain you own (e.g. `"click.example.com"`).
  ///
  /// [urls] must be non-empty.
  void setResolveDeepLinkURLs(List<String> urls) {
    _executeRpc('setResolveDeepLinkURLs', {'urls': urls});
  }

  /// Registers custom / branded OneLink domains (e.g. `"click.greatapp.com"`) so
  /// the SDK resolves links served from them.
  ///
  /// [brandDomains] must be non-empty.
  void setOneLinkCustomDomain(List<String> brandDomains) {
    _executeRpc('setOneLinkCustomDomain', {'domains': brandDomains});
  }

  /// Sets the deep-link resolution timeout, in milliseconds. Call before
  /// [initSdk].
  ///
  /// Default when unset differs by platform: 3000 ms on Android, 60000 ms on iOS.
  void setDeepLinkTimeout(int timeoutMs) {
    _executeRpc('setDeepLinkTimeout', {'timeout': timeoutMs});
  }

  /// Registers the ordered JSON key-path of a OneLink nested in a push payload
  /// (e.g. `["deeply", "nested", "link"]`), resolved via [onDeepLinking].
  ///
  /// Call before [initSdk]. [deeplinkPath] must be non-empty. On iOS you must
  /// also forward the payload via [sendPushNotificationData].
  void addPushNotificationDeepLinkPath(List<String> deeplinkPath) {
    _executeRpc(
        'addPushNotificationDeepLinkPath', {'deepLinkPath': deeplinkPath});
  }

  /// Enables/disables interop with Facebook's deferred app-link resolution.
  ///
  /// On iOS requires the Facebook SDK to be linked, otherwise enabling is a
  /// no-op.
  void enableFacebookDeferredApplinks(bool isEnabled) {
    _executeRpc('enableFacebookDeferredApplinks', {'isEnabled': isEnabled});
  }

  /// Appends [parameters] to any deep-link URL containing [contains], before the
  /// SDK resolves it.
  ///
  /// [contains] must be non-empty; iOS also requires a non-empty [parameters].
  void appendParametersToDeepLinkingURL(
      String contains, Map<String, String> parameters) {
    _executeRpc('appendParametersToDeepLinkingURL',
        {'contains': contains, 'parameters': parameters});
  }

  /// Sets (or clears, with `null`) the Facebook deferred app-link URL directly,
  /// bypassing the Facebook SDK fetch. iOS only.
  ///
  /// Unsafe URL schemes (e.g. `javascript:`) are rejected. Complements
  /// [enableFacebookDeferredApplinks] — use this only when you already hold the
  /// deferred link.
  void setFacebookDeferredAppLink(String? url) {
    if (Platform.isIOS) {
      _executeRpc('setFacebookDeferredAppLink', {'url': url});
    }
  }

  // ---------------------------------------------------------------------------
  // In-app events & revenue
  // ---------------------------------------------------------------------------

  /// Sends an in-app event.
  ///
  /// Without a callback the call is fire-and-forget. Passing [onSuccess] /
  /// [onError] reports the SDK request result (e.g. error codes 41/42 when
  /// logged before the SDK is initialized/started) and makes the native call
  /// block until it completes (up to ~10s).
  void logEvent(
    String eventName,
    Map? eventValues, {
    RequestSuccessListener? onSuccess,
    RequestErrorListener? onError,
  }) {
    _executeRequest(
      'logEvent',
      {'eventName': eventName, 'eventValues': eventValues},
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Logs ad revenue for a monetization / mediation network.
  ///
  /// Required [AdRevenueData] fields: `monetizationNetwork`, `mediationNetwork`,
  /// `currencyIso4217Code` (ISO 4217), `revenue`. Prefer the [AFMediationNetwork]
  /// enum for `mediationNetwork`; an unknown value is rejected natively.
  ///
  /// Fire-and-forget: errors (including a rejected `mediationNetwork`) are not
  /// surfaced to Dart, so always pass a known value.
  void logAdRevenue(AdRevenueData adRevenueData) {
    _executeRpc('logAdRevenue', adRevenueData.toMap());
  }

  /// Manually logs the user's location.
  ///
  /// [latitude] must be in −90..90 and [longitude] in −180..180 (out-of-range is
  /// rejected natively). Fire-and-forget.
  void logLocation(double latitude, double longitude) {
    _executeRpc('logLocation', {'latitude': latitude, 'longitude': longitude});
  }

  /// Manually logs a session (for background utility apps). Android only — on
  /// iOS use [startSDK].
  void logSession() {
    if (Platform.isAndroid) {
      _executeRpc('logSession', {});
    }
  }

  // ---------------------------------------------------------------------------
  // User identity & hashed PII
  // ---------------------------------------------------------------------------

  /// Sets your own customer user ID to cross-reference with the AppsFlyer ID.
  void setCustomerUserId(String id) {
    _executeRpc('setCustomerUserId', {'customerId': id});
  }

  /// Sets the user's email. The SDK hashes the value (SHA-256) before sending it.
  void setUserEmail(String email) {
    _executeRpc('setUserEmail', {'email': email});
  }

  /// Sets the user's phone number. The SDK hashes the value (SHA-256) before sending it.
  void setUserPhone(String countryCode, String phoneNumber) {
    _executeRpc('setUserPhone',
        {'countryCode': countryCode, 'phoneNumber': phoneNumber});
  }

  /// Sets the user's first name. The SDK hashes the value (SHA-256) before sending it.
  void setUserFirstName(String firstName) {
    _executeRpc('setUserFirstName', {'firstName': firstName});
  }

  /// Sets the user's last name. The SDK hashes the value (SHA-256) before sending it.
  void setUserLastName(String lastName) {
    _executeRpc('setUserLastName', {'lastName': lastName});
  }

  /// Sets the user's Facebook login id (App-Scoped ID) for network sharing.
  ///
  /// Passed as a `String` to preserve 64-bit precision; a non-numeric value is
  /// ignored (no call). Unlike the other `setUser*` setters it is **not hashed**.
  /// `"0"` is the unset sentinel (clears the id).
  void setUserFbLoginId(String fbLoginId) {
    final int? numericId = int.tryParse(fbLoginId);
    if (numericId == null) {
      return;
    }
    _executeRpc('setUserFbLoginId', {'fbLoginId': numericId});
  }

  /// Clears all PII set via the `setUser*` setters.
  void clearUserPii() {
    _executeRpc('clearUserPii');
  }

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Sets the currency code for in-app purchase revenue (3-letter ISO 4217;
  /// default USD).
  void setCurrencyCode(String currencyCode) {
    _executeRpc('setCurrencyCode', {'currencyCode': currencyCode});
  }

  /// Sets the minimum time (seconds) between two launches for them to count as
  /// separate sessions.
  void setMinTimeBetweenSessions(int seconds) {
    _executeRpc('setMinTimeBetweenSessions', {'seconds': seconds});
  }

  /// Sets a custom host name and prefix (for switching HTTPS environments).
  ///
  /// No-op if either value is empty.
  void setHost(String hostPrefix, String hostName) {
    if (hostPrefix.isEmpty || hostName.isEmpty) {
      return;
    }
    _executeRpc(
        'setHost', {'hostPrefixName': hostPrefix, 'hostName': hostName});
  }

  /// Returns the host name. Android only (`null` on iOS).
  Future<String?> getHostName() async {
    if (Platform.isAndroid) {
      return _executeRpc<String>('getHostName');
    }
    return null;
  }

  /// Returns the host prefix. Android only (`null` on iOS).
  Future<String?> getHostPrefix() async {
    if (Platform.isAndroid) {
      return _executeRpc<String>('getHostPrefix');
    }
    return null;
  }

  /// Sets additional custom data sent to AppsFlyer. Pass an empty map to clear.
  void setAdditionalData(Map<String, dynamic> customData) {
    _executeRpc('setAdditionalData', {'customData': customData});
  }

  /// Sets the OneLink ID used as the base for links from [generateInviteLink].
  ///
  /// [callback] is optional and only signals that the setter ran (static
  /// `"success"`, no payload).
  Future<void> setAppInviteOneLinkID(String oneLinkID,
      [MultiUseCallback? callback]) async {
    if (callback != null) {
      _startListening(callback, "setAppInviteOneLinkIDCallback");
    }
    await _executeRpc('setAppInviteOneLink', {'oneLinkId': oneLinkID});
  }

  /// Sets the partner-specific data.
  void setPartnerData(String partnerId, Map<String, Object> partnerData) {
    _executeRpc(
        'setPartnerData', {'partnerId': partnerId, 'data': partnerData});
  }

  /// Blocks sharing of S2S events via postback/API with the given partners
  /// (e.g. to satisfy GDPR/CCPA or user opt-outs).
  void setSharingFilterForPartners(List<String> partners) {
    _executeRpc('setSharingFilterForPartners', {'partners': partners});
  }

  /// Sets the out-of-store install source. Android only.
  void setOutOfStore(String sourceName) {
    if (Platform.isAndroid) {
      _executeRpc('setOutOfStore', {'sourceName': sourceName});
    }
  }

  /// Returns the out-of-store install source. Android only (`null` on iOS).
  Future<String?> getOutOfStore() async {
    if (Platform.isAndroid) {
      return _executeRpc<String>('getOutOfStore');
    }
    return null;
  }

  /// Manually marks the app as updated. Android only.
  void setIsUpdate(bool isUpdate) {
    if (Platform.isAndroid) {
      _executeRpc('setIsUpdate', {'isUpdate': isUpdate});
    }
  }

  /// Overrides the device language reported to the SDK. iOS only.
  void setCurrentDeviceLanguage(String language) {
    if (Platform.isIOS) {
      _executeRpc('setCurrentDeviceLanguage', {'language': language});
    }
  }

  /// Sets a custom install id to correlate the install with your own id (e.g.
  /// for server-side reconciliation). Call before [startSDK].
  void setInstallId(String installId) {
    _executeRpc('setInstallId', {'installId': installId});
  }

  /// Attributes the install to an OEM/manufacturer preinstall deal. Call before
  /// [startSDK]. Android only.
  void setPreinstallAttribution(
      String mediaSource, String campaign, String siteId) {
    if (Platform.isAndroid) {
      _executeRpc('setPreinstallAttribution', {
        'mediaSource': mediaSource,
        'campaign': campaign,
        'siteId': siteId,
      });
    }
  }

  /// Overrides the app ID reported to AppsFlyer. Android only (on iOS the app ID
  /// is set at init). An empty [appId] is ignored. Call before [startSDK].
  void setAppId(String appId) {
    if (Platform.isAndroid && appId.isNotEmpty) {
      _executeRpc('setAppId', {'appId': appId});
    }
  }

  // ---------------------------------------------------------------------------
  // Privacy & data collection
  // ---------------------------------------------------------------------------

  /// Sets GDPR / DMA consent.
  ///
  /// [isUserSubjectToGDPR] is required. When `true`, [consentForDataUsage] and
  /// [consentForAdsPersonalization] are also required and omitting either throws
  /// an [ArgumentError]; when `false` they are ignored. [hasConsentForAdStorage]
  /// is always optional.
  ///
  /// Provide the current consent on every app start (before [startSDK]) — it is
  /// not persisted across sessions.
  void setConsentDataV2({
    required bool isUserSubjectToGDPR,
    bool? consentForDataUsage,
    bool? consentForAdsPersonalization,
    bool? hasConsentForAdStorage,
  }) {
    if (isUserSubjectToGDPR &&
        (consentForDataUsage == null ||
            consentForAdsPersonalization == null)) {
      throw ArgumentError(
          'consentForDataUsage and consentForAdsPersonalization are required '
          'when isUserSubjectToGDPR is true.');
    }
    _executeRpc('setConsentData', <String, dynamic>{
      'isUserSubjectToGDPR': isUserSubjectToGDPR,
      'hasConsentForDataUsage': consentForDataUsage,
      'hasConsentForAdsPersonalization': consentForAdsPersonalization,
      'hasConsentForAdStorage': hasConsentForAdStorage,
    });
  }

  @Deprecated('Use setConsentDataV2 instead')
  void setConsentData(AppsFlyerConsent consentData) {
    _executeRpc('setConsentData', consentData.toMap());
  }

  /// Enables automatic collection of TCF (IAB consent) data.
  void enableTCFDataCollection(bool shouldCollect) {
    _executeRpc('enableTCFDataCollection', {'shouldCollect': shouldCollect});
  }

  /// Anonymizes user data (opt-out of logging for a specific user).
  void anonymizeUser(bool shouldAnonymize) {
    _executeRpc('anonymizeUser', {'shouldAnonymize': shouldAnonymize});
  }

  /// Stops all SDK activity and communication with AppsFlyer servers (e.g. for
  /// legal/privacy compliance). Reversible by calling with `false`.
  void stop(bool isStopped) {
    _executeRpc('stop', {'shouldStop': isStopped});
  }

  /// Whether the SDK is currently stopped (see [stop]). Android only (`null` on
  /// iOS).
  Future<bool?> isStopped() async {
    if (Platform.isAndroid) {
      return _executeRpc<bool>('isStopped');
    }
    return null;
  }

  /// Disables collection of advertising identifiers (GAID / IDFA / OAID). Pass
  /// `true` to disable (collection is on by default).
  void setDisableAdvertisingIdentifiers(bool disable) {
    _executeRpc('setDisableAdvertisingIdentifiers',
        Platform.isIOS ? {'disable': disable} : {'isDisable': disable});
  }

  /// Opts out of Android ID collection. Android only.
  ///
  /// Apps with Google Play Services should disable this to comply with Play
  /// policy.
  void setCollectAndroidId(bool isCollect) {
    if (Platform.isAndroid) {
      _executeRpc('setCollectAndroidID', {'isCollect': isCollect});
    }
  }

  /// Disables transfer of user-specific data over the network. Android only.
  void setDisableNetworkData(bool disable) {
    if (Platform.isAndroid) {
      _executeRpc('setDisableNetworkData', {'isDisable': disable});
    }
  }

  /// Opts out of AppSet ID collection. Android only.
  void disableAppSetId() {
    if (Platform.isAndroid) {
      _executeRpc('disableAppSetId');
    }
  }

  /// Disables SKAdNetwork attribution. iOS only.
  ///
  /// Pass `true` to disable — the parameter's semantics are "disable", matching
  /// the native flag (`true` suppresses SKAdNetwork).
  void disableSKAdNetwork(bool disable) {
    if (Platform.isIOS) {
      _executeRpc('setDisableSKAdNetwork', {'disable': disable});
    }
  }

  /// Disables Apple Search Ads (AdServices) attribution. iOS only. Set before
  /// [startSDK].
  ///
  /// The iOS SDK needs **both** this and [AppsFlyerOptions.disableCollectASA] to
  /// fully suppress Apple Search Ads attribution.
  void disableAppleAdsAttribution(bool disable) {
    if (Platform.isIOS) {
      _executeRpc('setDisableAppleAdsAttribution', {'disable': disable});
    }
  }

  /// Disables IDFV (Identifier for Vendor) collection. iOS only. Set before
  /// [startSDK].
  void disableIDFVCollection(bool disable) {
    if (Platform.isIOS) {
      _executeRpc('setDisableIDFVCollection', {'disable': disable});
    }
  }

  /// Enables device-name collection. iOS only. Set before [startSDK].
  ///
  /// Opt-in: off by default and the device name is PII, so enable only if your
  /// privacy policy covers it.
  void setShouldCollectDeviceName(bool collect) {
    if (Platform.isIOS) {
      _executeRpc('setShouldCollectDeviceName', {'collect': collect});
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase validation
  // ---------------------------------------------------------------------------

  /// Validates and logs an in-app purchase (validation API V2).
  ///
  /// Completes with the validation result, or throws if validation fails.
  Future<Map<String, dynamic>> validateAndLogInAppPurchaseV2(
      AFPurchaseDetails purchaseDetails,
      {Map<String, String>? additionalParameters}) async {
    final dynamic params = Platform.isIOS
        ? <String, dynamic>{
            'product': {'productId': purchaseDetails.productId},
            'transaction': {
              'transactionId': purchaseDetails.purchaseToken,
              'purchaseType':
                  purchaseDetails.purchaseType == AFPurchaseType.subscription
                      ? 'subscription'
                      : 'oneTimePurchase',
            },
            'additionalParameters': additionalParameters,
          }
        : <String, dynamic>{
            ...purchaseDetails.toMap(),
            'additionalParameters': additionalParameters,
            'awaitResponse': true,
          };

    final result = await _executeRpc('validateAndLogInAppPurchase', params);
    return result == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(result as Map);
  }

  /// Enables sandbox mode for App Store receipt validation. iOS only.
  void useReceiptValidationSandbox(bool isSandboxEnabled) {
    if (Platform.isIOS) {
      _executeRpc(
          'setUseReceiptValidationSandbox', {'sandbox': isSandboxEnabled});
    }
  }

  /// Enables sandbox mode for uninstall-measurement validation. iOS only.
  /// Companion of [useReceiptValidationSandbox].
  void useUninstallSandbox(bool isSandboxEnabled) {
    if (Platform.isIOS) {
      _executeRpc('setUseUninstallSandbox', {'sandbox': isSandboxEnabled});
    }
  }

  // ---------------------------------------------------------------------------
  // Cross-promotion & invite
  // ---------------------------------------------------------------------------

  /// Logs a cross-promotion impression. Use the promoted app ID as shown in the
  /// AppsFlyer dashboard.
  void logCrossPromotionImpression(String appId, String campaign, Map? data) {
    _executeRpc('logCrossPromoteImpression',
        {'appId': appId, 'campaign': campaign, 'userParams': data});
  }

  /// Logs a cross-promotion click and opens the promoted app's store page.
  void logCrossPromotionAndOpenStore(
      String appId, String campaign, Map? params) {
    _executeRpc('logAndOpenStore', {
      'promotedAppId': appId,
      'campaign': campaign,
      'userParams': params,
    });
  }

  /// Generates a OneLink invite URL (User Invite).
  ///
  /// The result is delivered to the callbacks (not the `void` return): [success]
  /// gets `{"status": "success", "payload": {"userInviteURL": "<url>"}}`;
  /// [error] gets a plain `String` message. Only the most recent [success] /
  /// [error] pair is retained.
  void generateInviteLink(
    AppsFlyerInviteLinkParams? parameters,
    MultiUseCallback success,
    MultiUseCallback error,
  ) {
    _startListening(success, "generateInviteLinkSuccess");
    _startListening(error, "generateInviteLinkFailure");

    _executeRpc(
        'generateInviteLink', _translateInviteLinkParamsToRpc(parameters));
  }

  /// Maps [AppsFlyerInviteLinkParams] to the RPC param shape.
  Map<String, dynamic> _translateInviteLinkParamsToRpc(
      AppsFlyerInviteLinkParams? params) {
    if (params == null) {
      return <String, dynamic>{};
    }
    final String customerIdKey =
        Platform.isIOS ? 'referrerCustomerId' : 'customerId';
    return <String, dynamic>{
      'channel': params.channel,
      'campaign': params.campaign,
      'referrerName': params.referrerName,
      'referrerImageUrl': params.referrerImageUrl,
      customerIdKey: params.customerID,
      'baseDeepLink': params.baseDeepLink,
      'brandDomain': params.brandDomain,
      'userParams': params.customParams,
    };
  }

  /// Logs the `af_invite` event when a user shares an invite (typically the link
  /// from [generateInviteLink]).
  ///
  /// [channel] is the sharing channel (e.g. `"facebook"`); [eventParameters] are
  /// optional extra parameters. Fire-and-forget.
  void logInvite(String channel, [Map? eventParameters]) {
    _executeRpc('logInvite', <String, dynamic>{
      'channel': channel,
      'eventParameters': eventParameters,
    });
  }

  // ---------------------------------------------------------------------------
  // Push & uninstall
  // ---------------------------------------------------------------------------

  /// Measures push-notification campaigns.
  ///
  /// [userInfo] shape differs per platform: on Android, a map with `campaign`
  /// and `pid` (required) plus optional `isRetargeting` / `additionalParameters`;
  /// on iOS, the raw APNs `userInfo` dictionary (a null/empty payload is
  /// rejected).
  void sendPushNotificationData(Map? userInfo) {
    if (Platform.isAndroid) {
      _executeRpc('sendPushNotificationData', <String, dynamic>{
        'campaign': userInfo?['campaign']?.toString() ?? '',
        'pid': userInfo?['pid']?.toString() ?? '',
        'isRetargeting': userInfo?['isRetargeting'] == true,
        'additionalParameters': userInfo?['additionalParameters'],
      });
    } else {
      _executeRpc('handlePushNotification', {'pushPayload': userInfo});
    }
  }

  /// Passes the device token for uninstall measurement.
  ///
  /// Token format differs per platform: on Android, the FCM registration token
  /// as-is; on iOS, the APNs token **hex-encoded** (even-length) — a non-hex
  /// string is rejected silently.
  void updateServerUninstallToken(String token) {
    if (Platform.isAndroid) {
      _executeRpc('updateServerUninstallToken', {'token': token});
    } else {
      _executeRpc('registerUninstall', {'deviceToken': token});
    }
  }

  // ---------------------------------------------------------------------------
  // Getters & utilities
  // ---------------------------------------------------------------------------

  /// Returns the native AppsFlyer SDK version.
  Future<String?> getSDKVersion() async {
    return _executeRpc<String>('getSdkVersion');
  }

  /// Returns the AppsFlyer unique device ID (created per install).
  Future<String?> getAppsFlyerUID() async {
    return _executeRpc<String>('getAppsFlyerUID');
  }

  /// Whether the install was an OEM/manufacturer preinstall. Android only
  /// (`null` on iOS). See [setPreinstallAttribution].
  Future<bool?> isPreInstalledApp() async {
    if (Platform.isAndroid) {
      return _executeRpc<bool>('isPreInstalledApp');
    }
    return null;
  }

  /// Returns the Flutter plugin version.
  String getVersionNumber() {
    return AppsflyerConstants.PLUGIN_VERSION;
  }
}
