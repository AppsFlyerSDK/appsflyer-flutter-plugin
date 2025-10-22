part of appsflyer_sdk;

/// Type definition for a general purpose listener.
typedef PurchaseConnectorListener = Function(dynamic);

/// Type definition for a listener which gets called when the `PurchaseConnectorImpl` receives purchase revenue validation info for iOS.
typedef DidReceivePurchaseRevenueValidationInfo = Function(
    Map<String, dynamic>? validationInfo, IosError? error);

/// Invoked when a 200 OK response is received from the server.
/// Note: An INVALID purchase is considered to be a successful response and will also be returned by this callback.
///
/// [result] Server's response.
typedef OnResponse<T> = Function(Map<String, T>? result);

/// Invoked when a network exception occurs or a non 200/OK response is received from the server.
///
/// [result] The server's response.
/// [error] The exception that occurred during execution.
typedef OnFailure = Function(String result, JVMThrowable? error);
