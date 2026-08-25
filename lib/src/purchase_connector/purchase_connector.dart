part of appsflyer_sdk;

/// Interface representing a purchase connector.
abstract class PurchaseConnector {
  /// Starts observing transactions.
  void startObservingTransactions();

  /// Stops observing transactions.
  void stopObservingTransactions();

  /// Sets the listener for Android subscription validation results.
  ///
  /// [onResponse] Function to be executed when a successful response is received.
  /// [onFailure] Function to be executed when a failure occurs (network exception or non 200/OK response from the server).
  void setSubscriptionValidationResultListener(
      OnResponse<SubscriptionValidationResult>? onResponse,
      OnFailure? onFailure);

  /// Sets the listener for Android in-app validation results.
  ///
  /// [onResponse] Function to be executed when a successful response is received.
  /// [onFailure] Function to be executed when a failure occurs (network exception or non 200/OK response from the server).

  void setInAppValidationResultListener(
      OnResponse<InAppPurchaseValidationResult>? onResponse,
      OnFailure? onFailure);

  /// Sets the listener for iOS subscription and  in-app validation results.
  /// Parameter:
  ///   [callback] the function to be executed when `DidReceivePurchaseRevenueValidationInfo` is called.
  void setDidReceivePurchaseRevenueValidationInfo(
      DidReceivePurchaseRevenueValidationInfo? callback);

  /// Creates a new PurchaseConnector instance.
  /// Parameter:
  ///   [config] the configuration to be used when creating a new `PurchaseConnector` instance.
  factory PurchaseConnector({PurchaseConnectorConfiguration? config}) =>
      _PurchaseConnectorImpl(config: config);
}

/// The implementation of the PurchaseConnector.
///
/// This class is responsible for establishing a connection with Appsflyer purchase connector,
/// starting/stopping observing transactions, setting listeners for various validation results.
class _PurchaseConnectorImpl implements PurchaseConnector {
  /// Singleton instance of the PurchaseConnectorImpl.
  static _PurchaseConnectorImpl? _instance;

  /// Method channel to communicate with the Appsflyer Purchase Connector.
  final MethodChannel _methodChannel;

  /// Response handler for SubscriptionValidationResult (Android).
  OnResponse<SubscriptionValidationResult>? _arsOnResponse;

  /// Failure handler for SubscriptionValidationResult (Android).
  OnFailure? _arsOnFailure;

  /// Response handler for InAppPurchaseValidationResult (Android).
  OnResponse<InAppPurchaseValidationResult>? _viapOnResponse;

  /// Failure handler for InAppPurchaseValidationResult (Android).
  OnFailure? _viapOnFailure;

  /// Callback handler for receiving validation info for iOS.
  DidReceivePurchaseRevenueValidationInfo?
      _didReceivePurchaseRevenueValidationInfo;

  /// Internal constructor. Initializes the instance and sets up method call handler.
  _PurchaseConnectorImpl._internal(
      this._methodChannel, PurchaseConnectorConfiguration config) {
    _methodChannel.setMethodCallHandler(_methodCallHandler);

    final configMap = {
      _AppsFlyerConstants.LOG_SUBS_KEY: config.logSubscriptions,
      _AppsFlyerConstants.LOG_IN_APP_KEY: config.logInApps,
      _AppsFlyerConstants.SANDBOX_KEY: config.sandbox,
      _AppsFlyerConstants.STORE_KIT_VERSION_KEY: config.storeKitVersion.value,
    };

    _methodChannel.invokeMethod(_AppsFlyerConstants.CONFIGURE_KEY, configMap);
  }

  /// Factory constructor.
  ///
  /// This factory ensures that only a single instance of `PurchaseConnectorImpl` is used throughout the program
  /// by implementing the Singleton design pattern. If an instance already exists, it's returned.
  ///
  /// The [config] parameter is optional and is used only when creating the first instance of `PurchaseConnectorImpl`.
  /// Once an instance is created, the same instance will be returned in subsequent calls, and the [config]
  /// parameter will be ignored. Thus, it's valid to call this factory without a config if an instance already exists.
  ///
  /// If there is no existing instance and the [config] is not provided, a `MissingConfigurationException` will be thrown.
  factory _PurchaseConnectorImpl({PurchaseConnectorConfiguration? config}) {
    if (_instance == null && config == null) {
      // no instance exist and config not provided. We Can't create instance without config
      throw MissingConfigurationException();
    } else if (_instance == null && config != null) {
      // no existing instance. Create new instance and apply config
      MethodChannel methodChannel = const MethodChannel(
          _AppsFlyerConstants.AF_PURCHASE_CONNECTOR_CHANNEL);
      _instance = _PurchaseConnectorImpl._internal(methodChannel, config);
    } else if (_instance != null && config != null) {
      debugPrint(_AppsFlyerConstants.RE_CONFIGURE_ERROR_MSG);
    }

    return _instance!;
  }

  /// Starts observing the transactions.
  @override
  void startObservingTransactions() {
    _methodChannel.invokeMethod("startObservingTransactions");
  }

  /// Stops observing the transactions.
  @override
  void stopObservingTransactions() {
    _methodChannel.invokeMethod("stopObservingTransactions");
  }

  /// Sets the function to be executed when iOS validation info is received.
  @override
  void setDidReceivePurchaseRevenueValidationInfo(
      DidReceivePurchaseRevenueValidationInfo? callback) {
    _didReceivePurchaseRevenueValidationInfo = callback;
  }

  /// Sets the listener for Android in-app validation results.
  ///
  /// [onResponse] Function to be executed when a successful response is received.
  /// [onFailure] Function to be executed when a failure occurs (network exception or non 200/OK response from the server).
  @override
  void setInAppValidationResultListener(
      OnResponse<InAppPurchaseValidationResult>? onResponse,
      OnFailure? onFailure) {
    _viapOnResponse = onResponse;
    _viapOnFailure = onFailure;
  }

  /// Sets the listener for Android subscription validation results.
  ///
  /// [onResponse] Function to be executed when a successful response is received.
  /// [onFailure] Function to be executed when a failure occurs (network exception or non 200/OK response from the server).
  @override
  void setSubscriptionValidationResultListener(
      OnResponse<SubscriptionValidationResult>? onResponse,
      OnFailure? onFailure) {
    _arsOnResponse = onResponse;
    _arsOnFailure = onFailure;
  }

  /// Method call handler for different operations. Called by the _methodChannel.
  ///
  /// Every branch below parses a payload the native layer built from a Google
  /// Play or StoreKit response. A parse failure must never escape: this is an
  /// async platform-message handler, so a throw here becomes an unhandled
  /// asynchronous error that no `try`/`catch` in the host app can intercept,
  /// and the app is left with neither a success nor a failure callback. Parse
  /// failures are routed to the listener's `onFailure` instead — see
  /// [_reportParseFailure].
  Future<void> _methodCallHandler(MethodCall call) async {
    try {
      _dispatchMethodCall(call);
    } catch (error) {
      _reportParseFailure(call.method, error);
    }
  }

  void _dispatchMethodCall(MethodCall call) {
    // Native may send either a JSON string or an already-decoded Map; handle both.
    final dynamic rawArgs = call.arguments;
    final dynamic callMap = rawArgs is String ? jsonDecode(rawArgs) : rawArgs;

    switch (call.method) {
      case _AppsFlyerConstants
            .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
        _handleSubscriptionPurchaseValidationResultListenerOnResponse(callMap);
        break;
      case _AppsFlyerConstants
            .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _handleSubscriptionPurchaseValidationResultListenerOnFailure(callMap);
        break;
      case _AppsFlyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
        _handleInAppValidationResultListenerOnResponse(callMap);
        break;
      case _AppsFlyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _handleInAppValidationResultListenerOnFailure(callMap);
        break;
      case _AppsFlyerConstants.DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO:
        _handleDidReceivePurchaseRevenueValidationInfo(callMap);
        break;
      default:
        // Unknown callback name — log instead of throwing inside a platform
        // message handler (an uncaught throw here becomes an unhandled async error).
        debugPrint("PurchaseConnector: unknown method ${call.method}");
    }
  }

  /// Handles response for the subscription purchase validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  void _handleSubscriptionPurchaseValidationResultListenerOnResponse(
      dynamic callbackData) {
    _handleValidationResultListenerOnResponse<SubscriptionValidationResult>(
      {"result": callbackData},
      _arsOnResponse,
      (value) => SubscriptionValidationResultMap.fromJson(value).result,
    );
  }

  /// Handles response for the in-app validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  void _handleInAppValidationResultListenerOnResponse(dynamic callbackData) {
    _handleValidationResultListenerOnResponse<InAppPurchaseValidationResult>(
      {"result": callbackData},
      _viapOnResponse,
      (value) => InAppPurchaseValidationResultMap.fromJson(value).result,
    );
  }

  /// Handles failure for the subscription purchase validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  void _handleSubscriptionPurchaseValidationResultListenerOnFailure(
      Map<String, dynamic> callbackData) {
    _handleValidationResultListenerOnFailure(callbackData, _arsOnFailure);
  }

  /// Handles failure for the in-app validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  void _handleInAppValidationResultListenerOnFailure(dynamic callbackData) {
    _handleValidationResultListenerOnFailure(callbackData, _viapOnFailure);
  }

  /// Handles the reception of purchase revenue validation info.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  void _handleDidReceivePurchaseRevenueValidationInfo(dynamic callbackData) {
    var validationInfo = callbackData[_AppsFlyerConstants.VALIDATION_INFO]
        as Map<String, dynamic>?;
    var errorMap =
        callbackData[_AppsFlyerConstants.ERROR] as Map<String, dynamic>?;
    var error = errorMap != null ? IosError.fromJson(errorMap) : null;

    if (_didReceivePurchaseRevenueValidationInfo != null) {
      _didReceivePurchaseRevenueValidationInfo!(validationInfo, error);
    }
  }

  /// Routes a payload that could not be parsed to the failure callback of the
  /// listener the call was addressed to, so a malformed payload surfaces as a
  /// reported failure rather than as silence.
  ///
  /// The message carries the callback name and the error type only. The payload
  /// itself is never interpolated: it holds purchase and account identifiers,
  /// and this string reaches the host app's log in release builds.
  void _reportParseFailure(String method, Object error) {
    final message =
        'PurchaseConnector: could not parse the payload for $method '
        '(${error.runtimeType})';
    debugPrint(message);
    switch (method) {
      case _AppsFlyerConstants
            .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
      case _AppsFlyerConstants
            .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _arsOnFailure?.call(message, null);
        break;
      case _AppsFlyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
      case _AppsFlyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _viapOnFailure?.call(message, null);
        break;
      case _AppsFlyerConstants.DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO:
        _didReceivePurchaseRevenueValidationInfo?.call(null, null);
        break;
    }
  }

  /// Handles the response for a validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  /// [onResponse] is a function to be called upon response.
  /// [converter] is a function used for converting `[callbackData]` to result type `T`
  void _handleValidationResultListenerOnResponse<T>(dynamic callbackData,
      OnResponse<T>? onResponse, Map<String, T>? Function(dynamic) converter) {
    Map<String, T>? res = converter(callbackData);
    if (onResponse != null) {
      onResponse(res);
    }
  }

  /// Handles failure for a validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  /// [onFailureCallback] is a function to be called on failure.
  void _handleValidationResultListenerOnFailure(
      dynamic callbackData, OnFailure? onFailureCallback) {
    // A failure payload that is itself malformed must still reach the app: the
    // native layer is already reporting an error, so losing this call would
    // hide the very failure it announces.
    var resultMsg = callbackData[_AppsFlyerConstants.RESULT] as String? ??
        'PurchaseConnector: validation failed, no description supplied';
    var errorMap =
        callbackData[_AppsFlyerConstants.ERROR] as Map<String, dynamic>?;
    var error = errorMap != null ? JVMThrowable.fromJson(errorMap) : null;
    if (onFailureCallback != null) {
      onFailureCallback(resultMsg, error);
    }
  }
}
