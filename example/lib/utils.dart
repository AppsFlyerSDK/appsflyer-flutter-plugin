import 'dart:convert';

import 'package:flutter/foundation.dart';

class Utils {
  static String formatJson(jsonObj) {
    final encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObj);
  }

  static String prettyPrintDiagnosticable(Diagnosticable diagnosticable) {
    return '$diagnosticable'
        // newline after opening pairs
        .splitMapJoin(
          RegExp(r'[\(\{,]'),
          onMatch: (match) => '${match[0]}\n',
        )
        // newline before closing pairs
        .splitMapJoin(
          RegExp(r'[\)\}]'),
          onMatch: (match) => '\n${match[0]}',
        )
        // left pad key/value lines
        .splitMapJoin(
          RegExp(r'.*?:'),
          onMatch: (match) => '  ${match[0]}',
        );
  }
}
