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
    widget.initSdk();
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

  Future<bool> sendEvent(String eventName, Map eventValues) async {
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
