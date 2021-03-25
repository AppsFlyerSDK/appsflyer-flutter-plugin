import 'dart:convert';

class Utils {
  static String formatJson(jsonObj) {
    final encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObj);
  }
}
