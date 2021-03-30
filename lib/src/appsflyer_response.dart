import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

typedef ObjectConverter<T> = T Function(Map<String, dynamic>? json);
typedef DataResponse = void Function(Map<String, dynamic>? json);
typedef UnknownResponse = void Function(dynamic data);

/// Either a [AppsFlyerData] or [AppsFlyerUnknown] object
///
/// Use the [map] or [when] methods on this class to handle responses
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
  T? map<T>(ObjectConverter<T> builder) {
    final hasData = this is AppsFlyerData;

    if (hasData) {
      final json = payload as Map<String, dynamic>?;

      return builder(json);
    }

    return null;
  }

  /// Provides a convenient way of handling both known and unknown values
  /// returned from the platform.
  ///
  /// See also: [map] to handle only known responses
  void when({
    required DataResponse data,
    required UnknownResponse other,
  }) {
    switch (runtimeType) {
      case AppsFlyerData:
        final json = payload as Map<String, dynamic>?;

        data(json);
        break;
      case AppsFlyerUnknown:
        other(payload);
        break;
    }
  }
}

/// A successful response from the native Platform
///
///
/// Use [map] to convert the [payload] returned by the Platform into an object
/// of your choosing
///
/// ## Example
///
/// ```dart
/// ..onDeepLinking((AppsFlyerResponse response) {
///     final deepLink = response.map((json) {
///         if(json != null) return DeepLinkResponse.fromJson(json);
///
///         return null;
///     });
///
///     print(deepLink?.toString() ?? 'Deep Link Does Not Exist');
/// });
/// ```
///
/// Platform Responses: [PlatformResponse.onAppOpenAttribution],
/// [PlatformResponse.onDeepLinking], [PlatformResponse.validatePurchase],
/// [PlatformResponse.generateInviteLinkSuccess]
class AppsFlyerData extends AppsFlyerResponse<Map<String, dynamic>?> {
  const AppsFlyerData({
    required String status,
    required Map<String, dynamic>? payload,
  }) : super(status: status, payload: payload);
}

/// Unknown responses from the Platform
///
/// Unstructured data returned from to the AppsFlyer SDK by the Platform
class AppsFlyerUnknown extends AppsFlyerResponse<dynamic> {
  const AppsFlyerUnknown(dynamic payload)
      : super(status: 'unknown', payload: payload);
}

/// Base information returned from Deep Linking callbacks
///
/// ## Examples
///
/// ### Example 1: Standalone
/// ```dart
/// import 'appsflyer_sdk/appsflyer_sdk.dart';
///
/// ...
///
/// ..onDeepLinking((AppsFlyerResponse response) {
///     final deepLink = response.map((json) {
///         if(json != null) return OneLinkBase.fromJson(json);
///
///         return null;
///     });
///
///     print(deepLink?.toString() ?? 'Deep Link Does Not Exist');
/// });
/// ```
///
/// ### Example 2: Custom Properties (Composition)
///
/// #### Setup
/// ```dart
/// class DeepLinkResponse with Diagnosticable {
///  final OneLinkBase base;
///  // Add your custom attributes below here
///  final String product; // example attribute
///  final String branch; // example attribute
///
///  DeepLinkResponse._({
///    @required this.base,
///    @required this.product,
///    @required this.branch,
///  });
///
///  /// Convert JSON data to a [DeepLinkResponse]
///  static DeepLinkResponse fromJson(Map<String, dynamic> json) {
///    try {
///      final base = OneLinkBase.fromJson(json);
///      // Your custom attributes
///      final product = json['product'];
///      final branch = json['branch'];
///
///      final result = DeepLinkResponse._(
///        base: base,
///        product: product,
///        branch: branch,
///      );
///
///      debugPrint('$DeepLinkResponse created! $result');
///
///      return result;
///    } catch (e) {
///      debugPrint('$DeepLinkResponse creation failed: $e');
///    }
///
///    return null;
///  }
///
///  /// Prints the information below when [toString] is called
///  ///
///  /// Extremely helpful for debugging
///  @override
///  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
///    super.debugFillProperties(properties);
///    properties.add(DiagnosticsNode.message('$base'));
///    // Your custom attributes
///    properties.add(DiagnosticsNode.message('product: $product'));
///    properties.add(DiagnosticsNode.message('branch: $branch'));
///  }
///}
/// ```
///
/// #### Usage
///
/// ```dart
/// ..onDeepLinking((AppsFlyerResponse response) {
///     final deepLink = response.map((json) {
///         if(json != null) return DeepLinkResponse.fromJson(json);
///
///         return null;
///     });
///
///     print(deepLink?.toString() ?? 'Deep Link Does Not Exist');
/// });
/// ```
class OneLinkBase with Diagnosticable {
  final String campaign;
  final String mediaSource;
  final bool isDeferred;

  OneLinkBase._({
    required this.campaign,
    required this.mediaSource,
    required this.isDeferred,
  });

  /// Convert JSON data to a [OneLinkBase]
  static OneLinkBase fromJson(Map<String, dynamic> json) {
    final campaign = json['campaign'];
    final mediaSource = json['media_source'];
    final isDeferred = json['is_deferred'];

    return OneLinkBase._(
      campaign: campaign,
      mediaSource: mediaSource,
      isDeferred: isDeferred,
    );
  }

  /// Prints the information below when [toString] is called
  ///
  /// Extremely helpful for debugging
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message('campaign: $campaign'));
    properties.add(DiagnosticsNode.message('mediaSource: $mediaSource'));
    properties.add(DiagnosticsNode.message('isDeferred: $isDeferred'));
  }
}

/// Information when the app is installed
///
/// Platform Response: [PlatformResponse.onInstallConversionData]
class AppInstallResponse with Diagnosticable {
  final DateTime installTime;
  final String status;
  final String message;
  final bool isFirstLaunch;

  AppInstallResponse._({
    required this.installTime,
    required this.status,
    required this.message,
    required this.isFirstLaunch,
  });

  static AppInstallResponse fromJson(Map<String, dynamic> json) {
    final installTime = json['install_time'];
    final status = json['af_status'];
    final message = json['af_message'];
    final isFirstLaunch = json['is_first_launch'];

    return AppInstallResponse._(
      installTime: DateTime.parse(installTime),
      status: status,
      message: message,
      isFirstLaunch: isFirstLaunch,
    );
  }

  /// Prints the information below when [toString] is called
  ///
  /// Extremely helpful for debugging
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(
        'InstallTime: ${installTime.toIso8601String()}'));
    properties.add(DiagnosticsNode.message('status: $status'));
    properties.add(DiagnosticsNode.message('message: $message'));
    properties.add(DiagnosticsNode.message('isFirstLaunch: $isFirstLaunch'));
  }
}
