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
      //afDevKey: "7jKdYxdnYcbSQ5iWrGytWc", appId: "300200652", showDebug: true);
      afDevKey: "7jKdYxdnYcbSQ5iWrGytWc", appId: "com.appsflyer.appsflyersdkexample", showDebug: true);
    _appsflyerSdk = AppsflyerSdk(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: <Widget>[
            Text('AppsFlyer SDK example app'),
            FutureBuilder<String> (future: _appsflyerSdk.getSDKVersion(), builder: (BuildContext context, AsyncSnapshot snapshot) {
                return Text(snapshot.hasData ? snapshot.data :"");
            })
          ],
        ),
      ),
      body: 
      FutureBuilder<dynamic> ( future: _appsflyerSdk.initSdk(true,true), builder: (BuildContext context, AsyncSnapshot snapshot) {       
        if (snapshot.hasData)
            return HomeContainer(
            onData: _appsflyerSdk.conversionDataStream,
            onAttribution: _appsflyerSdk.appOpenAttributionStream,
            trackEvent: trackEvent,
          );
        return Text("Loading");
            })
     
    );
  }

  Future<bool> trackEvent(String eventName, Map eventValues)
  {
    return _appsflyerSdk.trackEvent(eventName, eventValues);
  }
}
