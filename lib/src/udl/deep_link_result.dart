part of appsflyer_sdk;

/// The outcome of native Unified Deep Linking resolution.
enum DeepLinkStatus {
  found,
  notFound,
  error,
  unknown,
}

/// Platform-specific deep-link failure information.
///
/// Android reports a stable error type such as `NETWORK`; iOS reports a
/// localized error message. The fields intentionally remain optional so the
/// platform distinction is not hidden.
@immutable
class DeepLinkFailure {
  final String? type;
  final String? message;

  const DeepLinkFailure({this.type, this.message});

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
      };
}

@immutable
class DeepLinkResult {
  final DeepLinkStatus status;
  final DeepLink? deepLink;
  final DeepLinkFailure? error;

  const DeepLinkResult({
    required this.status,
    this.deepLink,
    this.error,
  });

  factory DeepLinkResult._fromEvent(
    _AppsFlyerEvent event, {
    required TargetPlatform platform,
  }) {
    final data = event.data;
    final rawStatus = data['status']?.toString();
    final normalizedStatus = rawStatus?.replaceAll('_', '').toLowerCase();
    final DeepLinkStatus status;
    if (normalizedStatus == 'found') {
      status = DeepLinkStatus.found;
    } else if (normalizedStatus == 'notfound') {
      status = DeepLinkStatus.notFound;
    } else if (normalizedStatus == 'error' || normalizedStatus == 'failure') {
      status = DeepLinkStatus.error;
    } else {
      status = DeepLinkStatus.unknown;
    }

    final rawDeepLink = data['deepLink'];
    final deepLinkMap = _decodeDeepLink(rawDeepLink);
    final rawError = data['error'];
    final error = rawError == null
        ? null
        : platform == TargetPlatform.android
            ? DeepLinkFailure(type: rawError.toString())
            : DeepLinkFailure(message: rawError.toString());

    return DeepLinkResult(
      status: status,
      deepLink: deepLinkMap == null ? null : DeepLink(deepLinkMap),
      error: error,
    );
  }

  static Map<String, dynamic>? _decodeDeepLink(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is! String || value.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'error': error?.toJson(),
        'deepLink': deepLink?.clickEvent,
      };

  @override
  String toString() => 'DeepLinkResult: ${jsonEncode(toJson())}';
}
