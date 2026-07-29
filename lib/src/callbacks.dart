part of appsflyer_sdk;

// Unified event transport for both platforms. The native layer (Android via the
// `com.appsflyer.pluginbridge` RpcEventNotifier, iOS via the AppsFlyerRPC bridge event handler)
// normalizes every SDK callback into the same `{id, status, data}` JSON envelope and forwards it on
// this EventChannel. Dart therefore has a single decode/route path and dispatches each event to the
// app callback registered for its "id"; unregistered events are ignored (native forwards them all).
const _eventChannel = EventChannel(AppsflyerConstants.AF_EVENTS_CHANNEL);

typedef MultiUseCallback = void Function(dynamic msg);
typedef UDLCallback = void Function(DeepLinkResult deepLinkResult);
typedef CancelListening = void Function();
typedef RequestSuccessListener = void Function();
typedef RequestErrorListener = void Function(
    int errorCode, String errorMessage);

Map<String, MultiUseCallback> _callbacksById =
    <String, void Function(dynamic)>{};
UDLCallback? _udlCallback;

// Single broadcast subscription to the af-events stream, shared by every registered callback and
// kept alive for the plugin's lifetime.
StreamSubscription<dynamic>? _eventsSub;

void _ensureEventSubscription() {
  _eventsSub ??= _eventChannel.receiveBroadcastStream().listen(
    _dispatchCallListener,
    onError: (dynamic error) {
      _logAfEvent('af-events stream error', error);
    },
  );
}

// Centralized, debug-friendly logging for the event transport (replaces `print`:
// structured and filterable via the `AppsFlyer` log name, and quiet in release).
void _logAfEvent(String message, [Object? error, StackTrace? stackTrace]) {
  developer.log(message,
      name: 'AppsFlyer', error: error, stackTrace: stackTrace);
}

// Decodes a single event payload (a JSON string, identical on both platforms) and routes it to the
// app callback registered for its "id". Decoding/parsing is guarded so a malformed native payload
// can never throw out of here — an exception thrown in a stream's onData is an uncaught Zone error,
// not routed to onError. The app callback itself is invoked *outside* those guards, so genuine
// app-side errors surface instead of being silently swallowed. Callback lookups are null-safe
// because the native layer forwards all events, even those the app did not register for.
void _dispatchCallListener(dynamic rawArgs) {
  Map? callMap;
  try {
    final decoded = jsonDecode(rawArgs as String);
    if (decoded is Map) {
      callMap = decoded;
    }
  } catch (e, st) {
    _logAfEvent('failed to decode af-event', e, st);
    return;
  }
  if (callMap == null) {
    _logAfEvent('ignored malformed af-event: $rawArgs');
    return;
  }

  final String? id = callMap['id'] as String?;
  switch (id) {
    case "onInstallConversionData":
    case "generateInviteLinkSuccess":
    case "onSessionReady":
      Map? payload;
      try {
        final data = callMap['data'];
        payload = data is String ? jsonDecode(data) as Map? : data as Map?;
      } catch (e, st) {
        _logAfEvent('failed to decode "$id" payload', e, st);
        return;
      }
      _callbacksById[id]
          ?.call({"status": callMap['status'], "payload": payload});
      break;
    case "onDeepLinking":
      final DeepLinkResult dp;
      try {
        final error = (callMap["deepLinkError"] as String?)?.errorFromString();
        final status =
            (callMap["deepLinkStatus"] as String?)?.statusFromString() ??
                Status.PARSE_ERROR;
        final map = callMap["deepLinkObj"] as Map<String, dynamic>?;
        final deepLink = map != null ? DeepLink(map) : null;
        dp = DeepLinkResult(error, deepLink, status);
      } catch (e, st) {
        _logAfEvent('failed to parse onDeepLinking event', e, st);
        return;
      }
      _udlCallback?.call(dp);
      break;
    default:
      _callbacksById[id]?.call(callMap['data']);
      break;
  }
}

Future<CancelListening> _startListening(
    MultiUseCallback callback, String callbackName) async {
  _callbacksById[callbackName] = callback;
  _ensureEventSubscription();

  return () {
    _callbacksById.remove(callbackName);
  };
}

/// Removes a previously registered observer without tearing down the SDK-level
/// listener. Used by [AppsflyerSdk.unregisterSessionReadyListener] and
/// [AppsflyerSdk.unregisterConversionDataListener].
///
/// Both platforms forward all events and Dart gates by registration, so dropping
/// the routing entry is sufficient; any SDK-level unregistration goes through its
/// dedicated RPC method.
Future<void> _stopListening(String callbackName) async {
  _callbacksById.remove(callbackName);
}

Future<CancelListening> _startListeningToUDL(
    UDLCallback callback, String callbackName) async {
  _udlCallback = callback;
  _ensureEventSubscription();

  return () {
    _udlCallback = null;
    _callbacksById.remove(callbackName);
  };
}
