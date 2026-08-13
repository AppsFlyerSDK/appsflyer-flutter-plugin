part of appsflyer_sdk;

/// Routes native RPC events to the single callback registered for their event
/// name.
///
/// One callback slot per event name, replaced on re-registration — the same
/// contract as the native SDKs, which hold one listener reference per event
/// type (`AppsFlyerLib.registerConversionListener` on Android,
/// `deepLinkDelegate`/`setSessionReadyListener:` on iOS).
///
/// Internal to [AppsFlyerSdk]. The plugin exposes no stream or sink a host app
/// can reach, so one native event can never fan out to several app callbacks.
class _AppsFlyerListenerRegistry {
  final Map<String, void Function(_AppsFlyerEvent)> _callbacks =
      <String, void Function(_AppsFlyerEvent)>{};

  /// Registers [callback] for [eventName], replacing any previous callback.
  void on(String eventName, void Function(_AppsFlyerEvent) callback) {
    _callbacks[eventName] = callback;
  }

  /// Drops the callback registered for [eventName], if any.
  void off(String eventName) {
    _callbacks.remove(eventName);
  }

  /// Delivers [event] to its registered callback.
  ///
  /// An event with no registered callback is logged rather than silently
  /// discarded: both platforms replay events buffered before Dart attached, so
  /// this is the expected signal that a native event arrived for a listener the
  /// app has not registered (or has already unregistered).
  void dispatch(_AppsFlyerEvent event) {
    final callback = _callbacks[event.name];
    if (callback == null) {
      debugPrint(
        'AppsFlyer: no listener registered for ${event.name}; event dropped.',
      );
      return;
    }
    callback(event);
  }
}
