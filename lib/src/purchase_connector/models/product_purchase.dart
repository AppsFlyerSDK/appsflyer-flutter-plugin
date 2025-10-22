part of appsflyer_sdk;

@JsonSerializable()
class ProductPurchase {
  String kind;
  String purchaseTimeMillis;
  int purchaseState;
  int consumptionState;
  String developerPayload;
  String orderId;
  int purchaseType;
  int acknowledgementState;
  String purchaseToken;
  String productId;
  int quantity;
  String obfuscatedExternalAccountId;
  String obfuscatedExternalProfileId;
  String regionCode;

  ProductPurchase(
      this.kind,
      this.purchaseTimeMillis,
      this.purchaseState,
      this.consumptionState,
      this.developerPayload,
      this.orderId,
      this.purchaseType,
      this.acknowledgementState,
      this.purchaseToken,
      this.productId,
      this.quantity,
      this.obfuscatedExternalAccountId,
      this.obfuscatedExternalProfileId,
      this.regionCode);

  factory ProductPurchase.fromJson(Map<String, dynamic> json) =>
      _$ProductPurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$ProductPurchaseToJson(this);
}
