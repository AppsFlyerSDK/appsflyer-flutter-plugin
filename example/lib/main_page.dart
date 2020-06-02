import 'dart:async';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';
import 'home_container.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  AppsflyerSdk _appsflyerSdk;

  @override
  void initState() {
    super.initState();
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: "afDevKey", appId: "123456789", showDebug: true);
    _appsflyerSdk = AppsflyerSdk(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Column(
            children: <Widget>[
              Text('AppsFlyer SDK example app'),
              FutureBuilder<String>(
                  future: _appsflyerSdk.getSDKVersion(),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return Text(snapshot.hasData ? snapshot.data : "");
                  })
            ],
          ),
        ),
        body: FutureBuilder<dynamic>(
            future: _appsflyerSdk.initSdk(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                if (snapshot.hasData) {
                  return HomeContainer(
                    onData: _appsflyerSdk.conversionDataStream,
                    onAttribution: _appsflyerSdk.appOpenAttributionStream,
                    trackEvent: trackEvent,
                  );
                } else {
                  return Center(child: Text("Error initializing sdk"));
                }
              }
            }));
  }

  Future<bool> trackEvent(String eventName, Map eventValues) {
    return _appsflyerSdk.trackEvent(eventName, eventValues);
  }
}
