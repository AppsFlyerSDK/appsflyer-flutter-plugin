import 'package:flutter/foundation.dart';

/// Centralized logger for the AppsFlyer demo app.
///
/// Every call emits a [debugPrint] line tagged with [AF_DEMO] so QA can
/// filter Android logcat / iOS simulator logs with "AF_DEMO".
///
/// The same lines are also appended to [lines] so the in-app log panel can
/// render them without any additional tooling.
class AfDemoLogger extends ChangeNotifier {
  static final AfDemoLogger _instance = AfDemoLogger._();
  AfDemoLogger._();
  factory AfDemoLogger() => _instance;

  final List<String> lines = [];

  void log(String method, String message) {
    final line = '[AF_QA][$method] $message';
    debugPrint(line);
    lines.add(line);
    notifyListeners();
  }

  void logResult(String method, dynamic result) {
    log(method, 'result: $result');
  }

  void logError(String method, dynamic error) {
    log(method, 'error: $error');
  }

  void logCalling(String method) {
    log(method, 'calling...');
  }

  void logCallback(String callbackName, dynamic payload) {
    final line = '[AF_QA][CALLBACK][$callbackName] received: $payload';
    debugPrint(line);
    lines.add(line);
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}
