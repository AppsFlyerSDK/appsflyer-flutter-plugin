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
      AppsflyerConstants.LOG_SUBS_KEY: config.logSubscriptions,
      AppsflyerConstants.LOG_IN_APP_KEY: config.logInApps,
      AppsflyerConstants.SANDBOX_KEY: config.sandbox,
      AppsflyerConstants.STORE_KIT_VERSION_KEY: config.storeKitVersion.value,
    };

    print("[AppsFlyer_PC_Debug] Sending config to native: $configMap");
    print(
        "[AppsFlyer_PC_Debug] Keys being sent: ${AppsflyerConstants.LOG_SUBS_KEY}, ${AppsflyerConstants.LOG_IN_APP_KEY}, ${AppsflyerConstants.SANDBOX_KEY}");

    _methodChannel.invokeMethod(AppsflyerConstants.CONFIGURE_KEY, configMap);
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
      MethodChannel methodChannel =
          const MethodChannel(AppsflyerConstants.AF_PURCHASE_CONNECTOR_CHANNEL);
      _instance = _PurchaseConnectorImpl._internal(methodChannel, config);
    } else if (_instance != null && config != null) {
      debugPrint(AppsflyerConstants.RE_CONFIGURE_ERROR_MSG);
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
  Future<void> _methodCallHandler(MethodCall call) async {
    dynamic callMap = jsonDecode(call.arguments);

    switch (call.method) {
      case AppsflyerConstants
          .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
        _handleSubscriptionPurchaseValidationResultListenerOnResponse(callMap);
        break;
      case AppsflyerConstants
          .SUBSCRIPTION_PURCHASE_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _handleSubscriptionPurchaseValidationResultListenerOnFailure(callMap);
        break;
      case AppsflyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_RESPONSE:
        _handleInAppValidationResultListenerOnResponse(callMap);
        break;
      case AppsflyerConstants.IN_APP_VALIDATION_RESULT_LISTENER_ON_FAILURE:
        _handleInAppValidationResultListenerOnFailure(callMap);
        break;
      case AppsflyerConstants.DID_RECEIVE_PURCHASE_REVENUE_VALIDATION_INFO:
        _handleDidReceivePurchaseRevenueValidationInfo(callMap);
        break;
      default:
        throw ArgumentError("Method not found: ${call.method}");
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
    var validationInfo = callbackData[AppsflyerConstants.VALIDATION_INFO]
        as Map<String, dynamic>?;
    var errorMap =
        callbackData[AppsflyerConstants.ERROR] as Map<String, dynamic>?;
    var error = errorMap != null ? IosError.fromJson(errorMap) : null;

    if (_didReceivePurchaseRevenueValidationInfo != null) {
      _didReceivePurchaseRevenueValidationInfo!(validationInfo, error);
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
    } else {}
  }

  /// Handles failure for a validation result listener.
  ///
  /// [callbackData] is the callback data expected in the form of a map.
  /// [onFailureCallback] is a function to be called on failure.
  void _handleValidationResultListenerOnFailure(
      dynamic callbackData, OnFailure? onFailureCallback) {
    var resultMsg = callbackData[AppsflyerConstants.RESULT] as String;
    var errorMap =
        callbackData[AppsflyerConstants.ERROR] as Map<String, dynamic>?;
    var error = errorMap != null ? JVMThrowable.fromJson(errorMap) : null;
    if (onFailureCallback != null) {
      onFailureCallback(resultMsg, error);
    }
  }
}
