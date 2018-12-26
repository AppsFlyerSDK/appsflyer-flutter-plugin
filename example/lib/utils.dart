import 'dart:convert';

class Utils {
  static String formatJson(jsonObj) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObj);
  }
}
