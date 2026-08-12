part of appsflyer_sdk;

/// Internal native RPC event: event name plus normalized payload.
@immutable
class _AppsFlyerEvent {
  /// The native event name, such as `onConversionDataSuccess`.
  final String name;

  /// The event-specific payload.
  ///
  /// Events without a map payload use an empty map.
  final Map<String, dynamic> data;

  /// Creates an AppsFlyer event with the supplied name and payload.
  const _AppsFlyerEvent({
    required this.name,
    required this.data,
  });

  /// Parses a native RPC event JSON envelope.
  ///
  /// Android and iOS RPC 7.x always emit a JSON object with `event` and `data`
  /// (`data` is a map, or JSON `null` for Android `onSessionReady`). The Flutter
  /// bridge forwards that payload as a JSON [json]. Malformed input — a non-object
  /// envelope, or a missing, empty, or non-string `event` field — throws
  /// [FormatException] and is dropped by the plugin stream transformer.
  factory _AppsFlyerEvent.fromNative(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('AppsFlyer event must be a JSON object');
    }
    final envelope = Map<String, dynamic>.from(decoded);
    final rawEvent = envelope['event'];
    if (rawEvent is! String || rawEvent.isEmpty) {
      throw const FormatException(
        'AppsFlyer event must include a non-empty event name',
      );
    }
    final rawData = envelope['data'];
    return _AppsFlyerEvent(
      name: rawEvent,
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{},
    );
  }
}
