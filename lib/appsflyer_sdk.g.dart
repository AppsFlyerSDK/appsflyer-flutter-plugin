// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appsflyer_sdk.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionPurchase _$SubscriptionPurchaseFromJson(
        Map<String, dynamic> json) =>
    SubscriptionPurchase(
      json['acknowledgementState'] as String,
      json['canceledStateContext'] == null
          ? null
          : CanceledStateContext.fromJson(
              json['canceledStateContext'] as Map<String, dynamic>),
      json['externalAccountIdentifiers'] == null
          ? null
          : ExternalAccountIdentifiers.fromJson(
              json['externalAccountIdentifiers'] as Map<String, dynamic>),
      json['kind'] as String,
      json['latestOrderId'] as String,
      (json['lineItems'] as List<dynamic>)
          .map((e) =>
              SubscriptionPurchaseLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['linkedPurchaseToken'] as String?,
      json['pausedStateContext'] == null
          ? null
          : PausedStateContext.fromJson(
              json['pausedStateContext'] as Map<String, dynamic>),
      json['regionCode'] as String,
      json['startTime'] as String,
      json['subscribeWithGoogleInfo'] == null
          ? null
          : SubscribeWithGoogleInfo.fromJson(
              json['subscribeWithGoogleInfo'] as Map<String, dynamic>),
      json['subscriptionState'] as String,
      json['testPurchase'] == null
          ? null
          : TestPurchase.fromJson(json['testPurchase'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubscriptionPurchaseToJson(
        SubscriptionPurchase instance) =>
    <String, dynamic>{
      'acknowledgementState': instance.acknowledgementState,
      'canceledStateContext': instance.canceledStateContext,
      'externalAccountIdentifiers': instance.externalAccountIdentifiers,
      'kind': instance.kind,
      'latestOrderId': instance.latestOrderId,
      'lineItems': instance.lineItems,
      'linkedPurchaseToken': instance.linkedPurchaseToken,
      'pausedStateContext': instance.pausedStateContext,
      'regionCode': instance.regionCode,
      'startTime': instance.startTime,
      'subscribeWithGoogleInfo': instance.subscribeWithGoogleInfo,
      'subscriptionState': instance.subscriptionState,
      'testPurchase': instance.testPurchase,
    };

CanceledStateContext _$CanceledStateContextFromJson(
        Map<String, dynamic> json) =>
    CanceledStateContext(
      json['developerInitiatedCancellation'] == null
          ? null
          : DeveloperInitiatedCancellation.fromJson(
              json['developerInitiatedCancellation'] as Map<String, dynamic>),
      json['replacementCancellation'] == null
          ? null
          : ReplacementCancellation.fromJson(
              json['replacementCancellation'] as Map<String, dynamic>),
      json['systemInitiatedCancellation'] == null
          ? null
          : SystemInitiatedCancellation.fromJson(
              json['systemInitiatedCancellation'] as Map<String, dynamic>),
      json['userInitiatedCancellation'] == null
          ? null
          : UserInitiatedCancellation.fromJson(
              json['userInitiatedCancellation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CanceledStateContextToJson(
        CanceledStateContext instance) =>
    <String, dynamic>{
      'developerInitiatedCancellation': instance.developerInitiatedCancellation,
      'replacementCancellation': instance.replacementCancellation,
      'systemInitiatedCancellation': instance.systemInitiatedCancellation,
      'userInitiatedCancellation': instance.userInitiatedCancellation,
    };

DeveloperInitiatedCancellation _$DeveloperInitiatedCancellationFromJson(
        Map<String, dynamic> json) =>
    DeveloperInitiatedCancellation();

Map<String, dynamic> _$DeveloperInitiatedCancellationToJson(
        DeveloperInitiatedCancellation instance) =>
    <String, dynamic>{};

ReplacementCancellation _$ReplacementCancellationFromJson(
        Map<String, dynamic> json) =>
    ReplacementCancellation();

Map<String, dynamic> _$ReplacementCancellationToJson(
        ReplacementCancellation instance) =>
    <String, dynamic>{};

SystemInitiatedCancellation _$SystemInitiatedCancellationFromJson(
        Map<String, dynamic> json) =>
    SystemInitiatedCancellation();

Map<String, dynamic> _$SystemInitiatedCancellationToJson(
        SystemInitiatedCancellation instance) =>
    <String, dynamic>{};

UserInitiatedCancellation _$UserInitiatedCancellationFromJson(
        Map<String, dynamic> json) =>
    UserInitiatedCancellation(
      json['cancelSurveyResult'] == null
          ? null
          : CancelSurveyResult.fromJson(
              json['cancelSurveyResult'] as Map<String, dynamic>),
      json['cancelTime'] as String,
    );

Map<String, dynamic> _$UserInitiatedCancellationToJson(
        UserInitiatedCancellation instance) =>
    <String, dynamic>{
      'cancelSurveyResult': instance.cancelSurveyResult,
      'cancelTime': instance.cancelTime,
    };

CancelSurveyResult _$CancelSurveyResultFromJson(Map<String, dynamic> json) =>
    CancelSurveyResult(
      json['reason'] as String,
      json['reasonUserInput'] as String,
    );

Map<String, dynamic> _$CancelSurveyResultToJson(CancelSurveyResult instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'reasonUserInput': instance.reasonUserInput,
    };

ExternalAccountIdentifiers _$ExternalAccountIdentifiersFromJson(
        Map<String, dynamic> json) =>
    ExternalAccountIdentifiers(
      json['externalAccountId'] as String,
      json['obfuscatedExternalAccountId'] as String,
      json['obfuscatedExternalProfileId'] as String,
    );

Map<String, dynamic> _$ExternalAccountIdentifiersToJson(
        ExternalAccountIdentifiers instance) =>
    <String, dynamic>{
      'externalAccountId': instance.externalAccountId,
      'obfuscatedExternalAccountId': instance.obfuscatedExternalAccountId,
      'obfuscatedExternalProfileId': instance.obfuscatedExternalProfileId,
    };

SubscriptionPurchaseLineItem _$SubscriptionPurchaseLineItemFromJson(
        Map<String, dynamic> json) =>
    SubscriptionPurchaseLineItem(
      json['autoRenewingPlan'] == null
          ? null
          : AutoRenewingPlan.fromJson(
              json['autoRenewingPlan'] as Map<String, dynamic>),
      json['deferredItemReplacement'] == null
          ? null
          : DeferredItemReplacement.fromJson(
              json['deferredItemReplacement'] as Map<String, dynamic>),
      json['expiryTime'] as String,
      json['offerDetails'] == null
          ? null
          : OfferDetails.fromJson(json['offerDetails'] as Map<String, dynamic>),
      json['prepaidPlan'] == null
          ? null
          : PrepaidPlan.fromJson(json['prepaidPlan'] as Map<String, dynamic>),
      json['productId'] as String,
    );

Map<String, dynamic> _$SubscriptionPurchaseLineItemToJson(
        SubscriptionPurchaseLineItem instance) =>
    <String, dynamic>{
      'autoRenewingPlan': instance.autoRenewingPlan,
      'deferredItemReplacement': instance.deferredItemReplacement,
      'expiryTime': instance.expiryTime,
      'offerDetails': instance.offerDetails,
      'prepaidPlan': instance.prepaidPlan,
      'productId': instance.productId,
    };

OfferDetails _$OfferDetailsFromJson(Map<String, dynamic> json) => OfferDetails(
      (json['offerTags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      json['basePlanId'] as String,
      json['offerId'] as String?,
    );

Map<String, dynamic> _$OfferDetailsToJson(OfferDetails instance) =>
    <String, dynamic>{
      'offerTags': instance.offerTags,
      'basePlanId': instance.basePlanId,
      'offerId': instance.offerId,
    };

AutoRenewingPlan _$AutoRenewingPlanFromJson(Map<String, dynamic> json) =>
    AutoRenewingPlan(
      json['autoRenewEnabled'] as bool?,
      json['priceChangeDetails'] == null
          ? null
          : SubscriptionItemPriceChangeDetails.fromJson(
              json['priceChangeDetails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AutoRenewingPlanToJson(AutoRenewingPlan instance) =>
    <String, dynamic>{
      'autoRenewEnabled': instance.autoRenewEnabled,
      'priceChangeDetails': instance.priceChangeDetails,
    };

SubscriptionItemPriceChangeDetails _$SubscriptionItemPriceChangeDetailsFromJson(
        Map<String, dynamic> json) =>
    SubscriptionItemPriceChangeDetails(
      json['expectedNewPriceChargeTime'] as String,
      json['newPrice'] == null
          ? null
          : Money.fromJson(json['newPrice'] as Map<String, dynamic>),
      json['priceChangeMode'] as String,
      json['priceChangeState'] as String,
    );

Map<String, dynamic> _$SubscriptionItemPriceChangeDetailsToJson(
        SubscriptionItemPriceChangeDetails instance) =>
    <String, dynamic>{
      'expectedNewPriceChargeTime': instance.expectedNewPriceChargeTime,
      'newPrice': instance.newPrice,
      'priceChangeMode': instance.priceChangeMode,
      'priceChangeState': instance.priceChangeState,
    };

Money _$MoneyFromJson(Map<String, dynamic> json) => Money(
      json['currencyCode'] as String,
      (json['nanos'] as num).toInt(),
      (json['units'] as num).toInt(),
    );

Map<String, dynamic> _$MoneyToJson(Money instance) => <String, dynamic>{
      'currencyCode': instance.currencyCode,
      'nanos': instance.nanos,
      'units': instance.units,
    };

DeferredItemReplacement _$DeferredItemReplacementFromJson(
        Map<String, dynamic> json) =>
    DeferredItemReplacement(
      json['productId'] as String,
    );

Map<String, dynamic> _$DeferredItemReplacementToJson(
        DeferredItemReplacement instance) =>
    <String, dynamic>{
      'productId': instance.productId,
    };

PrepaidPlan _$PrepaidPlanFromJson(Map<String, dynamic> json) => PrepaidPlan(
      json['allowExtendAfterTime'] as String?,
    );

Map<String, dynamic> _$PrepaidPlanToJson(PrepaidPlan instance) =>
    <String, dynamic>{
      'allowExtendAfterTime': instance.allowExtendAfterTime,
    };

PausedStateContext _$PausedStateContextFromJson(Map<String, dynamic> json) =>
    PausedStateContext(
      json['autoResumeTime'] as String,
    );

Map<String, dynamic> _$PausedStateContextToJson(PausedStateContext instance) =>
    <String, dynamic>{
      'autoResumeTime': instance.autoResumeTime,
    };

SubscribeWithGoogleInfo _$SubscribeWithGoogleInfoFromJson(
        Map<String, dynamic> json) =>
    SubscribeWithGoogleInfo(
      json['emailAddress'] as String,
      json['familyName'] as String,
      json['givenName'] as String,
      json['profileId'] as String,
      json['profileName'] as String,
    );

Map<String, dynamic> _$SubscribeWithGoogleInfoToJson(
        SubscribeWithGoogleInfo instance) =>
    <String, dynamic>{
      'emailAddress': instance.emailAddress,
      'familyName': instance.familyName,
      'givenName': instance.givenName,
      'profileId': instance.profileId,
      'profileName': instance.profileName,
    };

TestPurchase _$TestPurchaseFromJson(Map<String, dynamic> json) =>
    TestPurchase();

Map<String, dynamic> _$TestPurchaseToJson(TestPurchase instance) =>
    <String, dynamic>{};

InAppPurchaseValidationResult _$InAppPurchaseValidationResultFromJson(
        Map<String, dynamic> json) =>
    InAppPurchaseValidationResult(
      json['success'] as bool,
      json['productPurchase'] == null
          ? null
          : ProductPurchase.fromJson(
              json['productPurchase'] as Map<String, dynamic>),
      json['failureData'] == null
          ? null
          : ValidationFailureData.fromJson(
              json['failureData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InAppPurchaseValidationResultToJson(
        InAppPurchaseValidationResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'productPurchase': instance.productPurchase,
      'failureData': instance.failureData,
    };

ProductPurchase _$ProductPurchaseFromJson(Map<String, dynamic> json) =>
    ProductPurchase(
      json['kind'] as String,
      json['purchaseTimeMillis'] as String,
      (json['purchaseState'] as num).toInt(),
      (json['consumptionState'] as num).toInt(),
      json['developerPayload'] as String,
      json['orderId'] as String,
      (json['purchaseType'] as num).toInt(),
      (json['acknowledgementState'] as num).toInt(),
      json['purchaseToken'] as String,
      json['productId'] as String,
      (json['quantity'] as num).toInt(),
      json['obfuscatedExternalAccountId'] as String,
      json['obfuscatedExternalProfileId'] as String,
      json['regionCode'] as String,
    );

Map<String, dynamic> _$ProductPurchaseToJson(ProductPurchase instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'purchaseTimeMillis': instance.purchaseTimeMillis,
      'purchaseState': instance.purchaseState,
      'consumptionState': instance.consumptionState,
      'developerPayload': instance.developerPayload,
      'orderId': instance.orderId,
      'purchaseType': instance.purchaseType,
      'acknowledgementState': instance.acknowledgementState,
      'purchaseToken': instance.purchaseToken,
      'productId': instance.productId,
      'quantity': instance.quantity,
      'obfuscatedExternalAccountId': instance.obfuscatedExternalAccountId,
      'obfuscatedExternalProfileId': instance.obfuscatedExternalProfileId,
      'regionCode': instance.regionCode,
    };

SubscriptionValidationResult _$SubscriptionValidationResultFromJson(
        Map<String, dynamic> json) =>
    SubscriptionValidationResult(
      json['success'] as bool,
      json['subscriptionPurchase'] == null
          ? null
          : SubscriptionPurchase.fromJson(
              json['subscriptionPurchase'] as Map<String, dynamic>),
      json['failureData'] == null
          ? null
          : ValidationFailureData.fromJson(
              json['failureData'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubscriptionValidationResultToJson(
        SubscriptionValidationResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'subscriptionPurchase': instance.subscriptionPurchase,
      'failureData': instance.failureData,
    };

ValidationFailureData _$ValidationFailureDataFromJson(
        Map<String, dynamic> json) =>
    ValidationFailureData(
      (json['status'] as num).toInt(),
      json['description'] as String,
    );

Map<String, dynamic> _$ValidationFailureDataToJson(
        ValidationFailureData instance) =>
    <String, dynamic>{
      'status': instance.status,
      'description': instance.description,
    };

JVMThrowable _$JVMThrowableFromJson(Map<String, dynamic> json) => JVMThrowable(
      json['type'] as String,
      json['message'] as String,
      json['stacktrace'] as String,
      json['cause'] == null
          ? null
          : JVMThrowable.fromJson(json['cause'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JVMThrowableToJson(JVMThrowable instance) =>
    <String, dynamic>{
      'type': instance.type,
      'message': instance.message,
      'stacktrace': instance.stacktrace,
      'cause': instance.cause,
    };

IosError _$IosErrorFromJson(Map<String, dynamic> json) => IosError(
      json['localizedDescription'] as String,
      json['domain'] as String,
      (json['code'] as num).toInt(),
    );

Map<String, dynamic> _$IosErrorToJson(IosError instance) => <String, dynamic>{
      'localizedDescription': instance.localizedDescription,
      'domain': instance.domain,
      'code': instance.code,
    };
