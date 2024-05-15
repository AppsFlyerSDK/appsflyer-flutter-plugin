import 'dart:convert';

class Utils {
  static String formatJson(jsonObj) {
    // ignore: prefer_final_locals
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObj);
  }
}
