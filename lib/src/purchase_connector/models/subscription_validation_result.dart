part of appsflyer_sdk;

@JsonSerializable()
class SubscriptionValidationResult {

  bool success;
  SubscriptionPurchase? subscriptionPurchase;
  ValidationFailureData? failureData;

  SubscriptionValidationResult(
      this.success,
      this.subscriptionPurchase,
      this.failureData
      );



  factory SubscriptionValidationResult.fromJson(Map<String, dynamic> json) => _$SubscriptionValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionValidationResultToJson(this);

}