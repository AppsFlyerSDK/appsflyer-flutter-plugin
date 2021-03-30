import 'dart:async';

import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainerStreams extends StatefulWidget {
  final Stream<Map> onData;
  final Stream<Map> onAttribution;
  final Future<bool> Function(String, Map) logEvent;

  HomeContainerStreams({this.onData, this.onAttribution, this.logEvent});

  @override
  _HomeContainerStreamsState createState() => _HomeContainerStreamsState();
}

class _HomeContainerStreamsState extends State<HomeContainerStreams> {
  final String eventName = "my event";

  final Map<String, String> eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "2"
  };

  String _logEventResponse = "No event have been sent";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.containerPadding),
          child: Column(
            children: <Widget>[
              Text(
                "AF SDK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(top: AppConstants.topPadding),
              ),
              StreamBuilder<dynamic>(
                  stream: widget.onData?.asBroadcastStream(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    return TextBorder(
                      controller: TextEditingController(
                          text: snapshot.hasData
                              ? Utils.formatJson(snapshot.data)
                              : "No conversion data"),
                      labelText: "Conversion Data:",
                    );
                  }),
              Padding(
                padding: EdgeInsets.only(top: 12.0),
              ),
              StreamBuilder<dynamic>(
                  stream: widget.onAttribution?.asBroadcastStream(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    return TextBorder(
                      controller: TextEditingController(
                          text: snapshot.hasData
                              ? Utils.formatJson(snapshot.data)
                              : "No attribution data"),
                      labelText: "Attribution Data:",
                    );
                  }),
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
                    child: Text("Log event"),
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
                          TextEditingController(text: _logEventResponse)),
                  ElevatedButton(
                    onPressed: () {
                      widget.logEvent(eventName, eventValues).then((onValue) {
                        setState(() {
                          _logEventResponse = onValue.toString();
                        });
                      }).catchError((onError) {
                        setState(() {
                          _logEventResponse = onError.toString();
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
