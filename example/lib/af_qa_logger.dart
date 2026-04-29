import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// QA log emitter consumed by `scripts/af-smoke-runner.sh`.
///
/// Every line emitted via [log] is prefixed with `[AF_QA]` so the smoke runner
/// can grep for it. Lines are also appended to `af_qa_logs.txt` under the
/// app's Documents directory on both iOS and Android. The runner pulls that
/// file off the device:
///   - iOS: `xcrun simctl get_app_container`
///   - Android: `adb shell run-as <package> cat app_flutter/af_qa_logs.txt`
///     (works because `flutter build apk --debug` sets `android:debuggable=true`)
///
/// On Android, Flutter 3.41 debug APKs launched via `adb shell am start` (i.e.
/// without an attached `flutter run` host) do not forward Dart `debugPrint`
/// output to logcat, so the file is the only reliable source of QA markers.
class AfQaLogger {
  static File? _file;
  static bool _initialized = false;

  /// Resolve the QA log file once at startup. Safe to call multiple times.
  ///
  /// We do NOT keep an [IOSink] around: its writes are buffered and the smoke
  /// runner kills the process before a flush ever happens. Each [log] call
  /// instead does a synchronous append so every marker is on disk immediately.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File('${docs.path}/af_qa_logs.txt');
      file.writeAsStringSync(
        '[AF_QA][LOGGER] init: ${file.path}\n',
        mode: FileMode.append,
        flush: true,
      );
      _file = file;
    } catch (e) {
      _file = null;
      debugPrint('[AF_QA][LOGGER] init failed: $e');
    }
  }

  /// Emit a single QA log line. Tag goes between brackets, message after.
  static void log(String tag, String message) {
    final line = '[AF_QA][$tag] $message';
    debugPrint(line);
    final file = _file;
    if (file != null) {
      try {
        file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      } catch (_) {}
    }
  }

  /// Helper for `[AF_QA][<method>] result: <value>` lines.
  static void result(String method, Object? value) {
    log(method, 'result: $value');
  }

  /// Helper for `[AF_QA][<method>] error: <err>` lines.
  static void error(String method, Object err) {
    log(method, 'error: $err');
  }

  /// Helper for `[AF_QA][CALLBACK][<name>] received: <payload>` lines.
  static void callback(String name, Object? payload) {
    log('CALLBACK][$name', 'received: $payload');
  }

  /// Helper for `[AF_QA][AUTO_APIS] <message>` lines.
  static void autoApis(String message) {
    log('AUTO_APIS', message);
  }
}
