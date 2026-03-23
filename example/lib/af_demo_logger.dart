import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized logger for the AppsFlyer demo app.
///
/// Every call emits a [debugPrint] line tagged with [AF_QA] so QA can
/// filter Android logcat / iOS simulator logs.
///
/// On iOS, logs are also written to Documents/af_qa_logs.txt so the CI
/// script can read them directly from the simulator's host filesystem:
///   ~/Library/Developer/CoreSimulator/Devices/{UDID}/data/
///     Containers/Data/Application/*/Documents/af_qa_logs.txt
class AfDemoLogger extends ChangeNotifier {
  static final AfDemoLogger _instance = AfDemoLogger._();
  AfDemoLogger._();
  factory AfDemoLogger() => _instance;

  /// Serializes file writes so concurrent log calls don't interleave lines.
  Future<void> _writeLock = Future.value();

  final List<String> lines = [];

  void log(String method, String message) {
    final line = '[AF_QA][$method] $message';
    debugPrint(line);
    _writeLock = _writeLock.then((_) => _writeToFile(line));
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
    _writeLock = _writeLock.then((_) => _writeToFile(line));
    lines.add(line);
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }

  /// Writes log line to a file readable from the host during CI.
  /// On iOS simulator the file lands at:
  ///   ~/Library/Developer/CoreSimulator/Devices/{UDID}/data/
  ///     Containers/Data/Application/*/Documents/af_qa_logs.txt
  Future<void> _writeToFile(String line) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/af_qa_logs.txt')
          .writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
