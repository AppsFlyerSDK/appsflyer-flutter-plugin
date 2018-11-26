import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String afDevKey = "7jKdYxdnYcbSQ5iWrGytWc";

  @override
  void initState() {
    super.initState();
    initSdk();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void initSdk() async {
    AppsflyerSdk.initSdk(afDevKey);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Center(
          child: new Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
