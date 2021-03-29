import 'dart:io';
import 'package:flutter/material.dart';

import 'appsflyer_service.dart';
import 'home_container.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  AppsFlyerService appsFlyerService;

  @override
  void initState() {
    super.initState();
    appsFlyerService = AppsFlyerService()..initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: Platform.isAndroid
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: <Widget>[
            Text('AppsFlyer SDK example app'),
            FutureBuilder<String>(
              future: appsFlyerService.sdk.getSDKVersion(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                return Text(snapshot.hasData ? snapshot.data : "");
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: appsFlyerService.initializer,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              return HomeContainer(appsFlyerService: appsFlyerService);
          }

          return Center(child: Text("Error initializing sdk"));
        },
      ),
    );
  }
}
