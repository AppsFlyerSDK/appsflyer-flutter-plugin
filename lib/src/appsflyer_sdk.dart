import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appsflyer_constants.dart';
import 'appsflyer_invite_link_params.dart';
import 'appsflyer_options.dart';
import 'callbacks.dart';
import 'platform_enums.dart';

class AppsflyerSdk {
  static final Callbacks callbacks = Callbacks();
  static AppsflyerSdk? _instance;
  final MethodChannel _methodChannel;
  final AppsFlyerOptions? afOptions;

  StreamController? _afGCDStreamController;
  StreamController? _afUDLStreamController;
  StreamController? _afOpenAttributionStreamController;
  StreamController? _afValidtaPurchaseController;
  EventChannel _eventChannel;

  @mustCallSuper
  void dispose() {
    [
      _afGCDStreamController,
      _afUDLStreamController,
      _afOpenAttributionStreamController,
      _afValidtaPurchaseController
    ].forEach((controller) => controller?.close());
  }

  ///Returns the [AppsflyerSdk] instance, initialized with a custom options
  ///provided by the user
  factory AppsflyerSdk(AppsFlyerOptions options) {
    if (_instance == null) {
      const eventChannel = EventChannel(AppsflyerConstants.afEventsChannel);
      const methodChannel = MethodChannel(AppsflyerConstants.afMethodChannel);

      _instance = AppsflyerSdk._(
        methodChannel,
        eventChannel,
        afOptions: options,
      );
    }

    return _instance!;
  }

  factory AppsflyerSdk.fromMap(Map<String, dynamic> options) {
    if (_instance == null) {
      const eventChannel = EventChannel(AppsflyerConstants.afEventsChannel);
      const methodChannel = MethodChannel(AppsflyerConstants.afMethodChannel);

      _instance = AppsflyerSdk._(
        methodChannel,
        eventChannel,
        afOptions: _toAFOptions(options),
      );
    }

    return _instance!;
  }

  AppsflyerSdk._(
    this._methodChannel,
    this._eventChannel, {
    this.afOptions,
  });

  @visibleForTesting
  AppsflyerSdk.private(
    this._methodChannel,
    this._eventChannel,
    Map<String, dynamic> mapOptions,
  ) : afOptions = AppsflyerSdk.fromMap(mapOptions).afOptions;

  static AppsFlyerOptions _toAFOptions(Map<String, dynamic> options) {
    final afOptions = <String, dynamic>{};
    //validations
    final String devKey = options[AppsflyerConstants.afDevKey];

    afOptions[AppsflyerConstants.afDevKey] = devKey;

    final String? appInviteOneLink =
        options[AppsflyerConstants.afInviteOneLink];

    afOptions[AppsflyerConstants.afInviteOneLink] = appInviteOneLink;

    if (options[AppsflyerConstants.disableCollectASA] != null) {
      afOptions[AppsflyerConstants.disableCollectASA] =
          options[AppsflyerConstants.disableCollectASA];
    }

    if (options[AppsflyerConstants.disableAdvertisingIdentifier] != null) {
      afOptions[AppsflyerConstants.disableAdvertisingIdentifier] =
          options[AppsflyerConstants.disableAdvertisingIdentifier];
    }

    if (Platform.isIOS) {
      if (options[AppsflyerConstants.afTimeToWaitForAttUserAuthorization] !=
          null) {
        final double timeToWaitForATTUserAuthorization =
            options[AppsflyerConstants.afTimeToWaitForAttUserAuthorization];

        afOptions[AppsflyerConstants.afTimeToWaitForAttUserAuthorization] =
            timeToWaitForATTUserAuthorization;
      }

      final String appID = options[AppsflyerConstants.afAppId];
      final exp = RegExp(r'^\d{8,11}$');
      assert(exp.hasMatch(appID));
      afOptions[AppsflyerConstants.afAppId] = appID;
    }

    afOptions[AppsflyerConstants.afIsDebug] =
        options.containsKey(AppsflyerConstants.afIsDebug)
            ? options[AppsflyerConstants.afIsDebug]
            : false;

    final String afDevKey = afOptions[AppsflyerConstants.afDevKey];
    final bool afShowDebug = afOptions[AppsflyerConstants.afIsDebug];
    final String? afAppId = afOptions[AppsflyerConstants.afAppId];
    final double? afTimeToWaitForAttUserAuthorization =
        afOptions[AppsflyerConstants.afTimeToWaitForAttUserAuthorization];
    final String? afInviteOneLink =
        afOptions[AppsflyerConstants.afInviteOneLink];
    final bool? disableAdvertisingIdentifier =
        afOptions[AppsflyerConstants.disableAdvertisingIdentifier];
    final bool? disableCollectASA =
        afOptions[AppsflyerConstants.disableCollectASA];

    return AppsFlyerOptions(
      afDevKey: afDevKey,
      showDebug: afShowDebug,
      appId: afAppId ?? '',
      timeToWaitForATTUserAuthorization: afTimeToWaitForAttUserAuthorization,
      appInviteOneLink: afInviteOneLink,
      disableAdvertisingIdentifier: disableAdvertisingIdentifier,
      disableCollectASA: disableCollectASA,
    );
  }

  // Accessing AppsFlyer Conversion Data from the SDK
  void _registerConversionDataCallback() {
    if (_afGCDStreamController == null) {
      _afGCDStreamController = StreamController<Map>(onCancel: () {
        _afGCDStreamController?.close();
      });
    }
  }

  Stream<Map>? get conversionDataStream {
    return _afGCDStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  // Accessing AppsFlyer attribution, referred from deep linking
  void _registerOnAppOpenAttributionCallback() {
    if (_afOpenAttributionStreamController == null) {
      _afOpenAttributionStreamController = StreamController<Map>(onCancel: () {
        _afOpenAttributionStreamController?.close();
      });
    }
  }

  Stream<Map>? get appOpenAttributionStream {
    return _afOpenAttributionStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  // Unified deeplink: Accessing AppsFlyer deeplink attributes
  void _registerUDLCallback() {
    if (_afUDLStreamController == null) {
      _afUDLStreamController = StreamController<Map>(onCancel: () {
        _afUDLStreamController?.close();
      });
      _registerUDLListener();
    }
  }

  Stream<Map>? get onDeepLinkingStream {
    return _afUDLStreamController?.stream.asBroadcastStream()
        as Stream<Map<dynamic, dynamic>>?;
  }

  ///Returns `Stream`. Accessing AppsFlyer purchase validation data
  // ignore: unused_element
  Stream<dynamic> _registerValidatePurchaseStream() {
    if (_afValidtaPurchaseController == null) {
      _afValidtaPurchaseController = StreamController(onCancel: () {
        _afValidtaPurchaseController!.close();
      });

      _registerPurchaseValidateListener();
    }
    return _afValidtaPurchaseController!.stream;
  }

  ///initialize the SDK, using the options initialized from the constructor|
  Future<dynamic> initSdk({
    bool registerConversionDataCallback = false,
    bool registerOnAppOpenAttributionCallback = false,
    bool registerOnDeepLinkingCallback = false,
  }) async {
    return Future.delayed(Duration(seconds: 0)).then(
      (_) {
        if (registerConversionDataCallback) _registerConversionDataCallback();
        if (registerOnAppOpenAttributionCallback) {
          _registerOnAppOpenAttributionCallback();
        }

        if (registerConversionDataCallback ||
            registerOnAppOpenAttributionCallback) {
          _registerGCDListener();
        }

        if (registerOnDeepLinkingCallback) {
          _registerUDLCallback();
        }

        final initSdk = PlatformMethod.initSdk.asString();
        return _methodChannel.invokeMethod(initSdk, afOptions?.toJson());
      },
    );
  }

  Future<String?> getSDKVersion() async {
    final getSDKVersion = PlatformMethod.getSDKVersion.asString();
    return _methodChannel.invokeMethod(getSDKVersion);
  }

  ///These in-app events help you to log how loyal users discover your app, and attribute them to specific
  ///campaigns/media-sources. Please take the time define the event/s you want to measure to allow you
  ///to send ROI (Return on Investment) and LTV (Lifetime Value).
  ///- The `logEvent` method allows you to send in-app events to AppsFlyer analytics. This method allows you to add events dynamically by adding them directly to the application code.
  Future<bool?> logEvent(String eventName, Map eventValues) async {
    // ignore: unnecessary_null_comparison
    assert(eventValues != null);

    return _methodChannel.invokeMethod(
        "logEvent", {'eventName': eventName, 'eventValues': eventValues});
  }

  void setHost(String hostPrefix, String hostName) {
    _methodChannel.invokeMethod(
        "setHost", {'hostPrefix': hostPrefix, 'hostName': hostName});
  }

  /// Opt-out of collection of IMEI.
  /// If the app does NOT contain Google Play Services, device IMEI is collected by the SDK.
  /// However, apps with Google play services should avoid IMEI collection as this is in violation of the Google Play policy.
  void setCollectIMEI({required bool isCollect}) {
    final setCollectIMEI = PlatformMethod.setCollectIMEI.asString();
    _methodChannel.invokeMethod(setCollectIMEI, {'isCollect': isCollect});
  }

  /// Opt-out of collection of Android ID.
  /// If the app does NOT contain Google Play Services, Android ID is collected by the SDK.
  /// However, apps with Google play services should avoid Android ID collection as this is in violation of the Google Play policy.
  void setCollectAndroidId({required bool isCollect}) {
    final setCollectAndroidId = PlatformMethod.setCollectAndroidId.asString();
    _methodChannel.invokeMethod(setCollectAndroidId, {'isCollect': isCollect});
  }

  Future<String?> getHostName() async {
    final getHostName = PlatformMethod.getHostName.asString();
    return _methodChannel.invokeMethod(getHostName);
  }

  Future<String?> getHostPrefix() async {
    final getHostPrefix = PlatformMethod.getHostPrefix.asString();
    return _methodChannel.invokeMethod(getHostPrefix);
  }

  void setAndroidIdData(String androidId) {
    final setAndroidIdData = PlatformMethod.setAndroidIdData.asString();
    _methodChannel.invokeMethod(setAndroidIdData, {'androidId': androidId});
  }

  void setMinTimeBetweenSessions(int seconds) {
    assert(seconds >= 0, "the minimum timeout must be a positive number");
    final setMinTimeBetweenSessions =
        PlatformMethod.setMinTimeBetweenSessions.asString();
    _methodChannel
        .invokeMethod(setMinTimeBetweenSessions, {'seconds': seconds});
  }

  void setImeiData(String imei) {
    final setImeiData = PlatformMethod.setImeiData.asString();
    _methodChannel.invokeMethod(setImeiData, {'imei': imei});
  }

  /// Setting user local currency code for in-app purchases.
  /// The currency code should be a 3 character ISO 4217 code. (default is USD).
  /// You can set the currency code for all events by calling the following method.
  void setCurrencyCode(String currencyCode) {
    final setCurrencyCode = PlatformMethod.setCurrencyCode.asString();
    _methodChannel
        .invokeMethod(setCurrencyCode, {'currencyCode': currencyCode});
  }

  /// Setting your own customer ID enables you to cross-reference your own unique ID with AppsFlyer’s unique ID and the other devices’ IDs.
  /// This ID is available in AppsFlyer CSV reports along with Postback APIs for cross-referencing with your internal IDs.
  void setCustomerUserId(String id) {
    final setCustomerUserId = PlatformMethod.setCustomerUserId.asString();
    _methodChannel.invokeMethod(setCustomerUserId, {'id': id});
  }

  void setIsUpdate({required bool isUpdate}) {
    final setIsUpdate = PlatformMethod.setIsUpdate.asString();
    _methodChannel.invokeMethod(setIsUpdate, {'isUpdate': isUpdate});
  }

  /// Once this API is invoked, our SDK no longer communicates with our servers and stops functioning.
  /// In some extreme cases you might want to shut down all SDK activity due to legal and privacy compliance.
  /// This can be achieved with the stop API.
  void stop({required bool isStopped}) {
    final stop = PlatformMethod.stop.asString();
    _methodChannel.invokeMethod(stop, {'isStopped': isStopped});
  }

  void enableLocationCollection({required bool flag}) {
    final enableLocationCollection =
        PlatformMethod.enableLocationCollection.asString();
    _methodChannel.invokeMethod(enableLocationCollection, {'flag': flag});
  }

  ///Please use updateServerUninstallToken instead
  @deprecated
  void enableUninstallTracking(String senderId) {
    print("Please use updateServerUninstallToken instead");
  }

  ///Manually pass the Firebase / GCM Device Token for Uninstall measurement.
  void updateServerUninstallToken(String token) {
    final updateServerUninstallToken =
        PlatformMethod.updateServerUninstallToken.asString();
    _methodChannel.invokeMethod(updateServerUninstallToken, {'token': token});
  }

  ///Set the user emails and encrypt them.
  void setUserEmails(List<String> emails, [EmailCryptType? cryptType]) {
    if (cryptType != null) {
      final cryptTypeInt = EmailCryptType.values.indexOf(cryptType);
      final setUserEmailsWithCryptType =
          PlatformMethod.setUserEmailsWithCryptType.asString();
      _methodChannel.invokeMethod(setUserEmailsWithCryptType,
          {'emails': emails, 'cryptType': cryptTypeInt});
    } else {
      final setUserEmails = PlatformMethod.setUserEmails.asString();
      _methodChannel.invokeMethod(setUserEmails, {'emails': emails});
    }
  }

  ///Get AppsFlyer's unique device ID is created for every new install of an app.
  Future<String?> getAppsFlyerUID() async {
    final getAppsFlyerUID = PlatformMethod.getAppsFlyerUID.asString();
    return _methodChannel.invokeMethod(getAppsFlyerUID);
  }

  ///Set to true if you want to delay sdk init until CUID is set
  void waitForCustomerUserId({required bool wait}) {
    final waitForCustomerUserId =
        PlatformMethod.waitForCustomerUserId.asString();
    _methodChannel.invokeMethod(waitForCustomerUserId, {'wait': wait});
  }

  Future<dynamic> validateAndLogInAppAndroidPurchase(
      String publicKey,
      String signature,
      String purchaseData,
      String price,
      String currency,
      Map<String, String>? additionalParameters) {
    final validateAndLogInAppAndroidPurchase =
        PlatformMethod.validateAndLogInAppAndroidPurchase.asString();
    return _methodChannel.invokeMethod(validateAndLogInAppAndroidPurchase, {
      'publicKey': publicKey,
      'signature': signature,
      'purchaseData': purchaseData,
      'price': price,
      'currency': currency,
      'additionalParameters': additionalParameters
    });
  }

  ///Accessing AppsFlyer purchase validation data
  Future<dynamic> validateAndLogInAppIosPurchase(
      String productIdentifier,
      String price,
      String currency,
      String transactionId,
      Map<String, String> additionalParameters) async {
    final validateAndLogInAppIosPurchase =
        PlatformMethod.validateAndLogInAppIosPurchase.asString();
    return _methodChannel.invokeMethod(validateAndLogInAppIosPurchase, {
      'productIdentifier': productIdentifier,
      'price': price,
      'currency': currency,
      'transactionId': transactionId,
      'additionalParameters': additionalParameters
    });
  }

  /// set sandbox for iOS purchase validation
  void useReceiptValidationSandbox({required bool isSandboxEnabled}) {
    _methodChannel.invokeMethod(
        "useReceiptValidationSandbox", isSandboxEnabled);
  }

  /// Set additional data to be sent to AppsFlyer.
  void setAdditionalData(Map<String, dynamic>? customData) {
    final setAdditionalData = PlatformMethod.setAdditionalData.asString();
    _methodChannel.invokeMethod(setAdditionalData, {'customData': customData});
  }

  void _registerUDLListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data);
      final String? type = decodedJSON['type'];

      if (type?.toPlatformResponse() == AppsflyerConstants.afOnDeepLink) {
        if (_afUDLStreamController != null &&
            !_afUDLStreamController!.isClosed) {
          _afUDLStreamController?.sink.add(decodedJSON);
        } else {
          if (afOptions != null && afOptions!.showDebug) {
            printError(
                "UDL Stream controller is closed. the event wasn't sent");
          }
        }
      }
    });
  }

  void _registerGCDListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data);
      final String? type = decodedJSON['type'];

      switch (type) {
        case AppsflyerConstants.afGetConversionData:
          if (_afGCDStreamController != null &&
              !_afGCDStreamController!.isClosed) {
            _afGCDStreamController?.sink.add(decodedJSON);
          } else {
            if (afOptions != null && afOptions!.showDebug) {
              print("GCD Stream controller is closed. the event wasn't sent");
            }
          }
          break;
        case AppsflyerConstants.afOnAppOpenAttribution:
          if (_afOpenAttributionStreamController != null &&
              !_afOpenAttributionStreamController!.isClosed) {
            _afOpenAttributionStreamController?.sink.add(decodedJSON);
          } else {
            if (afOptions != null && afOptions!.showDebug) {
              print(
                  "OnAppOpenAttribution stream is closed. the event wasn't sent");
            }
          }
          break;
      }
    });
  }

  void _registerPurchaseValidateListener() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      final decodedJSON = jsonDecode(data);
      final String? type = decodedJSON['type'];
      if (type == AppsflyerConstants.afValidatePurchase) {
        _afValidtaPurchaseController!.sink.add(decodedJSON);
      }
    });
  }

  ///The sharing filter blocks the sharing of S2S events via postbacks/API with integrated partners and other third-party integrations.
  ///Use the filter to fulfill regulatory requirements like GDPR and CCPA, to comply with user opt-out mechanisms, and for other business logic reasons.
  void setSharingFilter(List<String> filters) {
    final setSharingFilter = PlatformMethod.setSharingFilter.asString();
    _methodChannel.invokeMethod(setSharingFilter, filters);
  }

  void setSharingFilterForAllPartners() {
    final setSharingFilterForAllPartners =
        PlatformMethod.setSharingFilterForAllPartners.asString();
    _methodChannel.invokeMethod(setSharingFilterForAllPartners);
  }

  void generateInviteLink(
    AppsFlyerInviteLinkParams? params, {
    required ResponseCallback onSuccess,
    required ResponseCallback onError,
  }) {
    callbacks.startListening(
      responseCallback: onSuccess,
      platformResponse: PlatformResponse.generateInviteLinkSuccess,
    );
    callbacks.startListening(
      responseCallback: onError,
      platformResponse: PlatformResponse.generateInviteLinkFailure,
    );
    final generateInviteLink = PlatformMethod.generateInviteLink.asString();
    _methodChannel.invokeMethod(generateInviteLink, params?.toJson());
  }

  ///Set the OneLink ID that should be used for User-Invite-API.
  ///The link that is generated for the user invite will use this OneLink ID as the base link ID
  Future<void> setAppInviteOneLinkID(
      String oneLinkID, ResponseCallback callback) async {
    callbacks.startListening(
        responseCallback: callback,
        platformResponse: PlatformResponse.setAppInviteOneLinkIDCallback);
    final setAppInviteOneLinkID =
        PlatformMethod.setAppInviteOneLinkID.asString();
    await _methodChannel.invokeMethod(setAppInviteOneLinkID, {
      'oneLinkID': oneLinkID,
    });
  }

  ///To attribute an impression use the following API call.
  ///Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
  void logCrossPromotionImpression(String appId, String campaign, Map? data) {
    final logCrossPromotionImpression =
        PlatformMethod.logCrossPromotionImpression.asString();
    _methodChannel.invokeMethod(logCrossPromotionImpression,
        {'appId': appId, 'campaign': campaign, 'data': data});
  }

  ///Use the following API to attribute the click and launch the app store's app page.
  void logCrossPromotionAndOpenStore(
      String appId, String campaign, Map? params) {
    final logCrossPromotionAndOpenStore =
        PlatformMethod.logCrossPromotionAndOpenStore.asString();
    _methodChannel.invokeMethod(logCrossPromotionAndOpenStore, {
      'appId': appId,
      'campaign': campaign,
      'params': params,
    });
  }

  void setOneLinkCustomDomain(List<String> brandDomains) {
    final setOneLinkCustomDomain =
        PlatformMethod.setOneLinkCustomDomain.asString();
    _methodChannel.invokeMethod(setOneLinkCustomDomain, brandDomains);
  }

  void setPushNotification({required bool isEnabled}) {
    final setPushNotification = PlatformMethod.setPushNotification.asString();
    _methodChannel.invokeMethod(setPushNotification, isEnabled);
  }

  void enableFacebookDeferredApplinks({required bool isEnabled}) {
    final enableFacebookDeferredApplinks =
        PlatformMethod.enableFacebookDeferredApplinks.asString();
    _methodChannel.invokeMethod(enableFacebookDeferredApplinks,
        {'isFacebookDeferredApplinksEnabled': isEnabled});
  }

  void disableSKAdNetwork({required bool isEnabled}) {
    final disableSKAdNetwork = PlatformMethod.disableSKAdNetwork.asString();
    _methodChannel.invokeMethod(disableSKAdNetwork, isEnabled);
  }

  void onInstallConversionData(ResponseCallback callback) async {
    callbacks.startListening(
      responseCallback: _responseLogger('onInstallConversionData', callback),
      platformResponse: PlatformResponse.onInstallConversionData,
    );
  }

  void onAppOpenAttribution(ResponseCallback callback) async {
    callbacks.startListening(
      responseCallback: _responseLogger('onAppOpenAttribution', callback),
      platformResponse: PlatformResponse.onAppOpenAttribution,
    );
  }

  void onDeepLinking(ResponseCallback callback) async {
    callbacks.startListening(
      responseCallback: _responseLogger('onDeepLinking', callback),
      platformResponse: PlatformResponse.onDeepLinking,
    );
  }

  void onPurchaseValidation(ResponseCallback callback) async {
    callbacks.startListening(
      responseCallback: _responseLogger('onPurchaseValidation', callback),
      platformResponse: PlatformResponse.validatePurchase,
    );
  }

  ResponseCallback _responseLogger(String trace, ResponseCallback callback) {
    return (response) {
      debugPrint('$trace callback executed with $response');

      callback(response);
    };
  }

  void printWarning(String text) {
    print('\x1B[33m$text\x1B[0m');
  }

  void printError(String text) {
    print('\x1B[31m$text\x1B[0m');
  }
}
