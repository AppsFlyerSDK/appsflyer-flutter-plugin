import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';

import 'home_container.dart';
import 'utils.dart';

class MainPage extends StatefulWidget {
  final AppsflyerSdk appsFlyerSdk;
  final Function initSdk;

  MainPage({this.appsFlyerSdk, this.initSdk});

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  String gcdText = "";
  String eventResponseText = "Press on the button";
  String onAppOpenAttributionText = "";

  @override
  void initState() {
    super.initState();
    registerCallbacks();
    widget.initSdk().then((res) {
      //test all the api functions
      // widget.appsFlyerSdk.setUserEmails(
      // ["a@a.com", "b.@b.com"], EmailCryptType.EmailCryptTypeSHA1);
      // widget.appsFlyerSdk.setMinTimeBetweenSessions(3);
      // widget.appsFlyerSdk.stopTracking(false);
      // widget.appsFlyerSdk.setCurrencyCode("currencyCode");
      // widget.appsFlyerSdk.setIsUpdate(true);
      // widget.appsFlyerSdk.enableUninstallTracking("senderId");
      // widget.appsFlyerSdk.setImeiData("imei");
      // widget.appsFlyerSdk.setAndroidIdData("androidId");
      // widget.appsFlyerSdk.enableLocationCollection(true);
      // widget.appsFlyerSdk.setCustomerUserId("id");
      // widget.appsFlyerSdk.waitForCustomerUserId(true);
      // widget.appsFlyerSdk.setAdditionalData({"customData": "data"});
      // widget.appsFlyerSdk.setCollectAndroidId(true);
      // widget.appsFlyerSdk.setCollectIMEI(true);
      // widget.appsFlyerSdk.setHost("pref", "my-host");
      // widget.appsFlyerSdk.getAppsFlyerUID().then((value) {
      //   print("AppsFlyerUID: ${value}");
      // });
      // widget.appsFlyerSdk.getHostName().then((name) {
      //   print("Host name: ${name}");
      // });
      // widget.appsFlyerSdk.getHostPrefix().then((name) {
      //   print("Host prefix: ${name}");
      // });
      // widget.appsFlyerSdk.updateServerUninstallToken("token");
      // widget.appsFlyerSdk.validateAndTrackInAppPurchase(
      //     "publicKey",
      //     "signature",
      //     "purchaseData",
      //     "price",
      //     "currency",
      //     {"fs": "fs"}).listen((data) {
      //   print(data);
      // }).onError((error) {
      //   print(error);
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AppsFlyer SDK example app'),
      ),
      body: HomeContainer(
        gcdText: gcdText,
        onAppOpenAttributionText: onAppOpenAttributionText,
        eventResponseText: eventResponseText,
        onEventPress: sendEvent,
      ),
    );
  }

  void sendEvent(String eventName, Map eventValues) async {
    bool result;
    try {
      result = await widget.appsFlyerSdk.trackEvent(eventName, eventValues);
    } on Exception catch (e) {}
    setState(() {
      eventResponseText = result.toString();
      print("Result trackEvent: ${result}");
    });
  }

  void registerCallbacks() {
    widget.appsFlyerSdk.registerConversionDataCallback().listen((data) {
      print("GCD: " + data.toString());
      setState(() {
        gcdText = Utils.formatJson(data);
      });
    }).onError((handleError) {
      print("error");
    });

    widget.appsFlyerSdk.registerOnAppOpenAttributionCallback().listen((data) {
      print("OnAppOpenAttribution: " + data.toString());
      setState(() {
        onAppOpenAttributionText = Utils.formatJson(data);
      });
    }).onError((handleError) {
      print("error");
    });
  }
}
