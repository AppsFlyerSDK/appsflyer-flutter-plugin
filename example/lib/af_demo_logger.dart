import 'dart:io';

import 'package:flutter/foundation.dart';

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

  final List<String> lines = [];

  void log(String method, String message) {
    final line = '[AF_QA][$method] $message';
    debugPrint(line);
    _writeToFile(line);
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
    _writeToFile(line);
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
  void _writeToFile(String line) {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return;
      final dir = Platform.isIOS ? '$home/Documents' : '/data/data/com.appsflyer.android.deviceid/files';
      Directory(dir).createSync(recursive: true);
      File('$dir/af_qa_logs.txt')
          .writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
