import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';

import 'home_container.dart';
import 'utils.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  final String afDevKey = "7jKdYxdnYcbSQ5iWrGytWc";
  final String appId = "300200652";
  String gcdText = "";
  String eventResponseText = "Press on the button";
  String onAppOpenAttributionText = "";

  @override
  void initState() {
    super.initState();
    registerCallbacks();
    initSdk();
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

  Future<Null> initSdk() async {
    dynamic result = '';
    try {
      dynamic options = {"afDevKey": afDevKey, "appId": appId, "isDebug": true};
      result = await AppsflyerSdk.initSdk(options);
    } on Exception catch (e) {
      result = e.toString();
      print("error: " + result);
      return;
    }

    setState(() {
      gcdText = Utils.formatJson(result);
    });
  }

  Future<bool> sendEvent(String eventName, Map eventValues) async {
    bool result;
    try {
      result = await AppsflyerSdk.trackEvent(eventName, eventValues);
    } on Exception catch (e) {}
    setState(() {
      eventResponseText = result.toString();
      print("Result trackEvent: ${result}");
    });
  }

  void registerCallbacks() {
    AppsflyerSdk.registerConversionDataCallback().listen((data) {
      print("GCD: " + data.toString());
      setState(() {
        gcdText = Utils.formatJson(data);
      });
    }).onError((handleError) {
      print("error");
    });

    AppsflyerSdk.registerOnAppOpenAttributionCallback().listen((data) {
      print("OnAppOpenAttribution: " + data.toString());
      setState(() {
        onAppOpenAttributionText = Utils.formatJson(data);
      });
    }).onError((handleError) {
      print("error");
    });
  }
}
