part of appsflyer_sdk;

@JsonSerializable()
class SubscriptionValidationResult {
  bool success;
  SubscriptionPurchase? subscriptionPurchase;
  ValidationFailureData? failureData;

  SubscriptionValidationResult(
      this.success, this.subscriptionPurchase, this.failureData);

  factory SubscriptionValidationResult.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionValidationResultToJson(this);
}

@JsonSerializable()
class SubscriptionValidationResultMap {
  Map<String, SubscriptionValidationResult> result;

  SubscriptionValidationResultMap(this.result);
  factory SubscriptionValidationResultMap.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionValidationResultMapFromJson(json);

  Map<String, dynamic> toJson() =>
      _$SubscriptionValidationResultMapToJson(this);
}
