part of appsflyer_sdk;
/// Exception thrown when the configuration is missing.
class MissingConfigurationException implements Exception {
  final String message;

  MissingConfigurationException(
      {this.message = AppsflyerConstants.MISSING_CONFIGURATION_EXCEPTION_MSG});

  @override
  String toString() => 'ConfigurationException: $message';
}
