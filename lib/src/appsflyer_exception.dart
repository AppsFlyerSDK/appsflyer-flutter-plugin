part of appsflyer_sdk;

/// An error reported by an AppsFlyer SDK operation.
class AppsFlyerException implements Exception {
  /// The numeric error code reported by the native SDK, when available.
  ///
  /// Native RPC failures use HTTP-style codes (`400`, `422`, `500`, …). When the
  /// platform supplies a non-numeric code, [code] is `null` and [message]
  /// carries the failure text.
  final int? code;

  /// The human-readable error message.
  final String message;

  /// Creates an AppsFlyer SDK exception.
  const AppsFlyerException({
    this.code,
    required this.message,
  });

  /// Converts a Flutter [PlatformException] from the native bridge.
  factory AppsFlyerException.fromPlatformException(PlatformException error) {
    return AppsFlyerException(
      code: int.tryParse(error.code),
      message: error.message ?? 'Native request failed',
    );
  }

  @override
  String toString() => 'AppsFlyerException: [$code] $message';
}
