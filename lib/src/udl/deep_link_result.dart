part of appsflyer_sdk;

class DeepLinkResult {
  final DeepLinkError? _error;
  final DeepLink? _deepLink;
  final Status _status;

  DeepLinkResult(this._error, this._deepLink, this._status);

  DeepLinkError? get error => _error;

  DeepLink? get deepLink => _deepLink;

  Status get status => _status;

  Map<String, dynamic> toJson() => {
        'status': _status.toShortString(),
        'error': _error?.toShortString(),
        'deepLink': _deepLink?.clickEvent,
      };

  @override
  String toString() {
    return "DeepLinkResult:${jsonEncode(toJson())}";
  }
}

enum DeepLinkError {
  TIMEOUT,
  NETWORK,
  HTTP_STATUS_CODE,
  UNEXPECTED,
  DEVELOPER_ERROR
}

enum Status { FOUND, NOT_FOUND, ERROR, PARSE_ERROR }

extension ParseStatusToString on Status {
  String toShortString() {
    return toString().split('.').last;
  }
}

extension ParseErrorToString on DeepLinkError {
  String toShortString() {
    return toString().split('.').last;
  }
}

extension ParseEnumFromString on String {
  Status? statusFromString() {
    for (final status in Status.values) {
      if (status.toShortString() == this) return status;
    }
    return null;
  }

  DeepLinkError? errorFromString() {
    for (final error in DeepLinkError.values) {
      if (error.toShortString() == this) return error;
    }
    return null;
  }
}
