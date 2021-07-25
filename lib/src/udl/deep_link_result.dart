part of appsflyer_sdk;


class DeepLinkResult {
  final Error? _error;
  final DeepLink? _deepLink;
  final Status _status;

  DeepLinkResult(this._error, this._deepLink, this._status);

  Error? get error => _error;

  DeepLink? get deepLink => _deepLink;

  Status get status => _status;

  DeepLinkResult.fromJson(Map<String, dynamic> json)
      : _error = json['error'],
        _status = json['status'],
        _deepLink = json['deepLink'];

  Map<String, dynamic> toJson() =>
      {
        'status': _status.toShortString(),
        'error': _error?.toShortString(),
        'deepLink': _deepLink?.clickEvent,
      };

  @override
  String toString() {
    return "DeepLinkResult:${jsonEncode(toJson())}";
  }


}

enum Error {
  TIMEOUT,
  NETWORK,
  HTTP_STATUS_CODE,
  UNEXPECTED,
  DEVELOPER_ERROR
}
enum Status {
  FOUND,
  NOT_FOUND,
  ERROR,
  PARSE_ERROR
}

extension ParseStatusToString on Status {
  String toShortString() {
    return this.toString().split('.').last;
  }
}

extension ParseErrorToString on Error {
  String toShortString() {
    return this.toString().split('.').last;
  }
}

extension ParseEnumFromString on String {
  Status? statusFromString() {
    return Status.values.firstWhere(
            (s) => _describeEnum(s) == this, orElse: null);
  }

  Error? errorFromString() {
    return Error.values.firstWhere((e) => _describeEnum(e) == this,
        orElse: null);
  }

  String _describeEnum(Object enumEntry) {
    final String description = enumEntry.toString();
    final int indexOfDot = description.indexOf('.');
    assert(
    indexOfDot != -1 && indexOfDot < description.length - 1,
    'The provided object "$enumEntry" is not an enum.',
    );
    return description.substring(indexOfDot + 1);
  }
}