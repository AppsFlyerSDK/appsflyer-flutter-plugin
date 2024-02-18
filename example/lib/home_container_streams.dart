import 'dart:async';
import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainerStreams extends StatefulWidget {
  final Stream<Map> onData;
  final Stream<Map> onAttribution;
  final Future<bool> Function(String, Map) logEvent;

  HomeContainerStreams({
    required this.onData,
    required this.onAttribution,
    required this.logEvent
  });

  @override
  _HomeContainerStreamsState createState() => _HomeContainerStreamsState();
}

class _HomeContainerStreamsState extends State<HomeContainerStreams> {
  final String eventName = "Custom Event";

  final Map eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "2"
  };

  String _logEventResponse = "Event status will be shown here once it's triggered.";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(AppConstants.CONTAINER_PADDING),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.blueGrey,
                      width: 0.5
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "APPSFLYER SDK",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppConstants.TOP_PADDING),
                    StreamBuilder<dynamic>(
                      stream: widget.onData.asBroadcastStream(),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                        return TextBorder(
                          controller: TextEditingController(
                              text: snapshot.hasData ? Utils.formatJson(snapshot.data) : "Waiting for conversion data..."
                          ),
                          labelText: "CONVERSION DATA",
                        );
                      },
                    ),
                    SizedBox(height: 12.0),
                    StreamBuilder<dynamic>(
                        stream: widget.onAttribution.asBroadcastStream(),
                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                          return TextBorder(
                            controller: TextEditingController(
                                text: snapshot.hasData ? Utils.formatJson(snapshot.data) : "Waiting for attribution data..."
                            ),
                            labelText: "ATTRIBUTION DATA",
                          );
                        }
                    ),
                  ],
                )
            ),
            SizedBox(height: 12.0),
            Container(
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: Colors.grey,
                    width: 0.5
                ),
              ),
              child: Column(children: <Widget>[
                Text(
                  "EVENT LOGGER",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.0),
                TextBorder(
                  controller: TextEditingController(
                      text: "Event Name: $eventName\nEvent Values: $eventValues"
                  ),
                  labelText: "EVENT REQUEST",
                ),
                SizedBox(height: 12.0),
                TextBorder(
                  labelText: "SERVER RESPONSE",
                  controller: TextEditingController(text: _logEventResponse),
                ),
                SizedBox(height: 20),
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
                  child: Text("Trigger Event"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}