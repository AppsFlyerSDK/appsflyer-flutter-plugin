import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef ObjectConverter<T> = T Function(Map<String, dynamic>? data);
typedef DataResponse = void Function(Map<String, dynamic>? data);
typedef UnknownResponse = void Function(dynamic data);

/// Either a [AppsFlyerData] or [AppsFlyerUnknown] object
///
/// Use the [then] or [when] methods on this class to handle responses
abstract class AppsFlyerResponse<T> extends Equatable with Diagnosticable {
  final String status;
  final T payload;

  const AppsFlyerResponse({required this.status, required this.payload});

  @override
  List<Object?> get props => [status, payload];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(status));
    properties.add(DiagnosticsNode.message('$payload'));
  }

  /// Convert the successful response into the object of your choosing
  ///
  /// Note: throws an error when the object cannot be converted
  T? then<T>(ObjectConverter<T> fromJson) {
    if (runtimeType is AppsFlyerData) {
      return fromJson(payload as Map<String, dynamic>?);
    }

    return null;
  }

  /// Provides a convenient way of handling both known and unknown values
  /// returned from the platform.
  ///
  /// See also: [then] to handle only known responses
  void when({
    required DataResponse data,
    required UnknownResponse other,
  }) {
    switch (runtimeType) {
      case AppsFlyerData:
        assert(payload is Map<String, dynamic>?);
        data(payload as Map<String, dynamic>?);
        break;
      case AppsFlyerUnknown:
        other(payload);
        break;
    }
  }
}

class AppsFlyerData extends AppsFlyerResponse<Map<String, dynamic>?> {
  const AppsFlyerData({
    required String status,
    required Map<String, dynamic>? payload,
  }) : super(status: status, payload: payload);
}

class AppsFlyerUnknown extends AppsFlyerResponse<dynamic> {
  const AppsFlyerUnknown(dynamic payload)
      : super(status: 'unknown', payload: payload);
}
