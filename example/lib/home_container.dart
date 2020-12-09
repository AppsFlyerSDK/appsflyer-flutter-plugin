import 'dart:async';

import 'package:flutter/material.dart';
import './app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainer extends StatefulWidget {
  final Map onData;
  final Map onAttribution;
  Future<bool> Function(String, Map) trackEvent;

  HomeContainer({this.onData, this.onAttribution, this.trackEvent});

  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  final String eventName = "my event";

  final Map eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "2"
  };

  String _trackEventResponse = "No event have been sent";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.CONTAINER_PADDING),
          child: Column(
            children: <Widget>[
              Text(
                "AF SDK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(top: AppConstants.TOP_PADDING),
              ),
              TextBorder(
                controller: TextEditingController(
                    text: widget.onData != null
                        ? Utils.formatJson(widget.onData)
                        : "No conversion data"),
                labelText: "Conversion Data:",
              ),
              Padding(
                padding: EdgeInsets.only(top: 12.0),
              ),
              TextBorder(
                controller: TextEditingController(
                    text: widget.onAttribution != null
                        ? Utils.formatJson(widget.onAttribution)
                        : "No Attribution data"),
                labelText: "Attribution Data:",
              ),
              Padding(
                padding: EdgeInsets.only(top: 12.0),
              ),
              Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child: Column(children: <Widget>[
                  Center(
                    child: Text("Track event"),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.0),
                  ),
                  TextBorder(
                    controller: TextEditingController(
                        text:
                            "event name: $eventName\nevent values: $eventValues"),
                    labelText: "Event Request",
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.0),
                  ),
                  TextBorder(
                      labelText: "Server response",
                      controller:
                          TextEditingController(text: _trackEventResponse)),
                  RaisedButton(
                    onPressed: () {
                      print("Pressed");
                      widget.trackEvent(eventName, eventValues).then((onValue) {
                        setState(() {
                          _trackEventResponse = onValue.toString();
                        });
                      }).catchError((onError) {
                        setState(() {
                          _trackEventResponse = onError.toString();
                        });
                      });
                    },
                    child: Text("Send event"),
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
