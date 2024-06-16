part of appsflyer_sdk;

@JsonSerializable()
class InAppPurchaseValidationResult {

  bool success;
  ProductPurchase? productPurchase;
  ValidationFailureData? failureData;

  InAppPurchaseValidationResult(
      this.success,
      this.productPurchase,
      this.failureData
      );



  factory InAppPurchaseValidationResult.fromJson(Map<String, dynamic> json) => _$InAppPurchaseValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$InAppPurchaseValidationResultToJson(this);

}

@JsonSerializable()
class InAppPurchaseValidationResultMap{
  Map<String, InAppPurchaseValidationResult> result;

  InAppPurchaseValidationResultMap(this.result);
  factory InAppPurchaseValidationResultMap.fromJson(Map<String, dynamic> json) => _$InAppPurchaseValidationResultMapFromJson(json);

  Map<String, dynamic> toJson() => _$InAppPurchaseValidationResultMapToJson(this);

}
