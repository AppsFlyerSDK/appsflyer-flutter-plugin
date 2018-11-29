import 'dart:convert';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  String afDevKey = "7jKdYxdnYcbSQ5iWrGytWc";
  var gcdTextField = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSdk();
    gcdTextField.text = "Waiting for response";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AppsFlyer SDK example app'),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Text(
                "AF SDK:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(top: 12.0),
              ),
              TextField(
                enabled: false,
                maxLines: null,
                controller: gcdTextField,
                decoration: InputDecoration(
                  labelText: "Conversion Data:",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      20.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> initSdk() async {
    dynamic result = '';
    try {
      result = await AppsflyerSdk.initSdk(
        afDevKey: afDevKey,
        iOSAppId: "124342323",
      );
    } on Exception catch (e) {
      result = e;
      return;
    }

    setState(() {
      gcdTextField.text = formatJson(result);
      print(formatJson(result));
    });
  }

  String formatJson(jsonObj) {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObj);
  }
}
