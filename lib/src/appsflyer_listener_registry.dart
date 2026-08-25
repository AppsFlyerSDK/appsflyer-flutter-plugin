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
///
/// An event that arrives before its listener has ever been registered is held
/// and replayed on registration. Both platforms flush their whole native buffer
/// as soon as Dart attaches to `af-events`, which happens on the first
/// `register*Listener` call — without this buffer, every replayed event for a
/// listener registered later in the sequence would be delivered to nothing and
/// lost for good.
///
/// Holding covers that startup window only. Once a listener has been registered
/// the app has seen the event stream, so an event arriving after it unregisters
/// is dropped rather than replayed the next time it registers.
class _AppsFlyerListenerRegistry {
  /// Caps the held events, matching the native buffers
  /// (`AppsFlyerEventBus.MAX_PENDING_EVENTS` on Android, `kMaxPendingEvents` on
  /// iOS). Held events are the replay of those buffers, so the Dart side never
  /// needs to hold more than one native buffer's worth.
  static const int _maxPendingEvents = 64;

  final Map<String, void Function(_AppsFlyerEvent)> _callbacks =
      <String, void Function(_AppsFlyerEvent)>{};

  /// Events awaiting a callback, in arrival order across all event names.
  final List<_AppsFlyerEvent> _pending = <_AppsFlyerEvent>[];

  /// Event names the app has registered a callback for at least once.
  final Set<String> _everRegistered = <String>{};

  /// Registers [callback] for [eventName], replacing any previous callback, and
  /// replays any events held for that name.
  ///
  /// The replay runs in a microtask so the caller finishes registering before
  /// its callback fires — [AppsFlyerSdk.registerConversionListener] fills two
  /// slots per call, and a synchronous replay would invoke the app's callback
  /// midway through that.
  void on(String eventName, void Function(_AppsFlyerEvent) callback) {
    _callbacks[eventName] = callback;
    _everRegistered.add(eventName);
    if (_pending.any((event) => event.name == eventName)) {
      scheduleMicrotask(() => _replay(eventName));
    }
  }

  /// Drops the callback registered for [eventName], if any, along with any
  /// events held for it.
  void off(String eventName) {
    _callbacks.remove(eventName);
    _pending.removeWhere((event) => event.name == eventName);
  }

  /// Drops the callbacks registered for [eventNames] and returns the ones that
  /// were installed, so a caller can put them back with [restore].
  ///
  /// The `unregister*Listener` APIs use this pair to stay atomic: the callbacks
  /// come out before the native call and go back if it fails, so a throw leaves
  /// Dart exactly as it was. Nothing held is lost in between — [_hold] only
  /// keeps events for a listener that has never registered, and these have.
  Map<String, void Function(_AppsFlyerEvent)> take(
      Iterable<String> eventNames) {
    final taken = <String, void Function(_AppsFlyerEvent)>{};
    for (final eventName in eventNames) {
      final callback = _callbacks[eventName];
      if (callback != null) {
        taken[eventName] = callback;
      }
      off(eventName);
    }
    return taken;
  }

  /// Reinstates the callbacks returned by [take].
  void restore(Map<String, void Function(_AppsFlyerEvent)> callbacks) {
    callbacks.forEach(on);
  }

  /// Captures the callbacks currently installed for [eventNames], leaving them
  /// in place, so a caller about to replace them can undo that with [rollback].
  ///
  /// Unlike [take] this holds nothing back: the `register*Listener` APIs
  /// snapshot before a first registration too, and the events held for that
  /// startup window still have to be replayed once the call succeeds.
  Map<String, void Function(_AppsFlyerEvent)> snapshot(
      Iterable<String> eventNames) {
    final previous = <String, void Function(_AppsFlyerEvent)>{};
    for (final eventName in eventNames) {
      final callback = _callbacks[eventName];
      if (callback != null) {
        previous[eventName] = callback;
      }
    }
    return previous;
  }

  /// Undoes a registration of [eventNames] that failed, putting back whatever
  /// [snapshot] captured.
  ///
  /// A name with no entry in [previous] had no callback before and is dropped
  /// outright, which is what a failed first registration means. A name that had
  /// one gets it back, so a failed re-registration leaves the listener that was
  /// already working untouched instead of deleting it. The callback goes back
  /// through [_callbacks] rather than [on]: it has already been registered
  /// once, so nothing is held for it and there is nothing to replay.
  void rollback(
    Iterable<String> eventNames,
    Map<String, void Function(_AppsFlyerEvent)> previous,
  ) {
    for (final eventName in eventNames) {
      final callback = previous[eventName];
      if (callback == null) {
        off(eventName);
      } else {
        _callbacks[eventName] = callback;
      }
    }
  }

  /// Delivers [event] to its registered callback, holding it for replay if that
  /// listener has never been registered.
  void dispatch(_AppsFlyerEvent event) {
    final callback = _callbacks[event.name];
    if (callback != null) {
      _invokeListener(callback, event);
      return;
    }
    if (_everRegistered.contains(event.name)) {
      debugPrint(
        'AppsFlyer: no listener registered for ${event.name}; event dropped.',
      );
      return;
    }
    _hold(event);
  }

  void _hold(_AppsFlyerEvent event) {
    if (_pending.length >= _maxPendingEvents) {
      final dropped = _pending.removeAt(0);
      debugPrint(
        'AppsFlyer: pending event buffer full ($_maxPendingEvents); '
        'dropped the oldest held ${dropped.name}.',
      );
    }
    _pending.add(event);
  }

  void _replay(String eventName) {
    final replayed = <_AppsFlyerEvent>[];
    _pending.removeWhere((event) {
      if (event.name != eventName) {
        return false;
      }
      replayed.add(event);
      return true;
    });
    for (final event in replayed) {
      // Re-read per event: a replayed callback may unregister or replace itself.
      final callback = _callbacks[eventName];
      if (callback == null) {
        return;
      }
      _invokeListener(callback, event);
    }
  }

  void _invokeListener(
    void Function(_AppsFlyerEvent) callback,
    _AppsFlyerEvent event,
  ) {
    try {
      callback(event);
    } catch (error, stack) {
      debugPrint(
        'AppsFlyer: listener for ${event.name} threw: $error\n$stack',
      );
    }
  }
}
