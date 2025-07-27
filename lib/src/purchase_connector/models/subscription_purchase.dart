part of appsflyer_sdk;

@JsonSerializable()
class SubscriptionPurchase {

  String acknowledgementState;
  CanceledStateContext? canceledStateContext;
  ExternalAccountIdentifiers? externalAccountIdentifiers;
  String kind;
  String latestOrderId;
  List<SubscriptionPurchaseLineItem> lineItems;
  String? linkedPurchaseToken;
  PausedStateContext? pausedStateContext;
  String regionCode;
  String startTime;
  SubscribeWithGoogleInfo? subscribeWithGoogleInfo;
  String subscriptionState;
  TestPurchase? testPurchase;

  SubscriptionPurchase(
      this.acknowledgementState,
      this.canceledStateContext,
      this.externalAccountIdentifiers,
      this.kind,
      this.latestOrderId,
      this.lineItems,
      this.linkedPurchaseToken,
      this.pausedStateContext,
      this.regionCode,
      this.startTime,
      this.subscribeWithGoogleInfo,
      this.subscriptionState,
      this.testPurchase
      );



  factory SubscriptionPurchase.fromJson(Map<String, dynamic> json) => _$SubscriptionPurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPurchaseToJson(this);

}


@JsonSerializable()
class CanceledStateContext {

  DeveloperInitiatedCancellation? developerInitiatedCancellation;
  ReplacementCancellation? replacementCancellation;
  SystemInitiatedCancellation? systemInitiatedCancellation;
  UserInitiatedCancellation? userInitiatedCancellation;

  CanceledStateContext(
      this.developerInitiatedCancellation,
      this.replacementCancellation,
      this.systemInitiatedCancellation,
      this.userInitiatedCancellation
      );



  factory CanceledStateContext.fromJson(Map<String, dynamic> json) => _$CanceledStateContextFromJson(json);

  Map<String, dynamic> toJson() => _$CanceledStateContextToJson(this);

}

@JsonSerializable()
class DeveloperInitiatedCancellation{
  DeveloperInitiatedCancellation();
  factory DeveloperInitiatedCancellation.fromJson(Map<String, dynamic> json) => _$DeveloperInitiatedCancellationFromJson(json);

  Map<String, dynamic> toJson() => _$DeveloperInitiatedCancellationToJson(this);
}

@JsonSerializable()
class ReplacementCancellation{
  ReplacementCancellation();
  factory ReplacementCancellation.fromJson(Map<String, dynamic> json) => _$ReplacementCancellationFromJson(json);

  Map<String, dynamic> toJson() => _$ReplacementCancellationToJson(this);
}

@JsonSerializable()
class SystemInitiatedCancellation{
  SystemInitiatedCancellation();
  factory SystemInitiatedCancellation.fromJson(Map<String, dynamic> json) => _$SystemInitiatedCancellationFromJson(json);

  Map<String, dynamic> toJson() => _$SystemInitiatedCancellationToJson(this);
}


@JsonSerializable()
class UserInitiatedCancellation {

  CancelSurveyResult? cancelSurveyResult;
  String cancelTime;

  UserInitiatedCancellation(
      this.cancelSurveyResult,
      this.cancelTime
      );



  factory UserInitiatedCancellation.fromJson(Map<String, dynamic> json) => _$UserInitiatedCancellationFromJson(json);

  Map<String, dynamic> toJson() => _$UserInitiatedCancellationToJson(this);

}

@JsonSerializable()
class CancelSurveyResult {

  String reason;
  String reasonUserInput;

  CancelSurveyResult(
      this.reason,
      this.reasonUserInput
      );



  factory CancelSurveyResult.fromJson(Map<String, dynamic> json) => _$CancelSurveyResultFromJson(json);

  Map<String, dynamic> toJson() => _$CancelSurveyResultToJson(this);

}

@JsonSerializable()
class ExternalAccountIdentifiers {

  String externalAccountId;
  String obfuscatedExternalAccountId;
  String obfuscatedExternalProfileId;

  ExternalAccountIdentifiers(
      this.externalAccountId,
      this.obfuscatedExternalAccountId,
      this.obfuscatedExternalProfileId
      );



  factory ExternalAccountIdentifiers.fromJson(Map<String, dynamic> json) => _$ExternalAccountIdentifiersFromJson(json);

  Map<String, dynamic> toJson() => _$ExternalAccountIdentifiersToJson(this);

}

@JsonSerializable()
class SubscriptionPurchaseLineItem {

  AutoRenewingPlan? autoRenewingPlan;
  DeferredItemReplacement? deferredItemReplacement;
  String expiryTime;
  OfferDetails? offerDetails;
  PrepaidPlan? prepaidPlan;
  String productId;

  SubscriptionPurchaseLineItem(
      this.autoRenewingPlan,
      this.deferredItemReplacement,
      this.expiryTime,
      this.offerDetails,
      this.prepaidPlan,
      this.productId
      );



  factory SubscriptionPurchaseLineItem.fromJson(Map<String, dynamic> json) => _$SubscriptionPurchaseLineItemFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPurchaseLineItemToJson(this);

}

@JsonSerializable()
class OfferDetails {

  List<String>? offerTags;
  String basePlanId;
  String? offerId;

  OfferDetails(
      this.offerTags,
      this.basePlanId,
      this.offerId
      );



  factory OfferDetails.fromJson(Map<String, dynamic> json) => _$OfferDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$OfferDetailsToJson(this);

}

@JsonSerializable()
class AutoRenewingPlan {

  bool? autoRenewEnabled;
  SubscriptionItemPriceChangeDetails? priceChangeDetails;

  AutoRenewingPlan(
      this.autoRenewEnabled,
      this.priceChangeDetails
      );



  factory AutoRenewingPlan.fromJson(Map<String, dynamic> json) => _$AutoRenewingPlanFromJson(json);

  Map<String, dynamic> toJson() => _$AutoRenewingPlanToJson(this);

}

@JsonSerializable()
class SubscriptionItemPriceChangeDetails {

  String expectedNewPriceChargeTime;
  Money? newPrice;
  String priceChangeMode;
  String priceChangeState;

  SubscriptionItemPriceChangeDetails(
      this.expectedNewPriceChargeTime,
      this.newPrice,
      this.priceChangeMode,
      this.priceChangeState
      );



  factory SubscriptionItemPriceChangeDetails.fromJson(Map<String, dynamic> json) => _$SubscriptionItemPriceChangeDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionItemPriceChangeDetailsToJson(this);

}

@JsonSerializable()
class Money {

  String currencyCode;
  int nanos;
  int units;

  Money(
      this.currencyCode,
      this.nanos,
      this.units
      );



  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  Map<String, dynamic> toJson() => _$MoneyToJson(this);

}
@JsonSerializable()
class DeferredItemReplacement {

  String productId;

  DeferredItemReplacement(
      this.productId
      );



  factory DeferredItemReplacement.fromJson(Map<String, dynamic> json) => _$DeferredItemReplacementFromJson(json);

  Map<String, dynamic> toJson() => _$DeferredItemReplacementToJson(this);

}

@JsonSerializable()
class PrepaidPlan {

  String? allowExtendAfterTime;

  PrepaidPlan(
      this.allowExtendAfterTime
      );



  factory PrepaidPlan.fromJson(Map<String, dynamic> json) => _$PrepaidPlanFromJson(json);

  Map<String, dynamic> toJson() => _$PrepaidPlanToJson(this);

}

@JsonSerializable()
class PausedStateContext {

  String autoResumeTime;

  PausedStateContext(
      this.autoResumeTime
      );



  factory PausedStateContext.fromJson(Map<String, dynamic> json) => _$PausedStateContextFromJson(json);

  Map<String, dynamic> toJson() => _$PausedStateContextToJson(this);

}
@JsonSerializable()
class SubscribeWithGoogleInfo {

  String emailAddress;
  String familyName;
  String givenName;
  String profileId;
  String profileName;

  SubscribeWithGoogleInfo(
      this.emailAddress,
      this.familyName,
      this.givenName,
      this.profileId,
      this.profileName
      );



  factory SubscribeWithGoogleInfo.fromJson(Map<String, dynamic> json) => _$SubscribeWithGoogleInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SubscribeWithGoogleInfoToJson(this);

}

@JsonSerializable()
class TestPurchase{
  TestPurchase();
  factory TestPurchase.fromJson(Map<String, dynamic> json) => _$TestPurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$TestPurchaseToJson(this);
}