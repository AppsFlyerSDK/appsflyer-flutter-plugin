import 'dart:async';
import 'package:flutter/material.dart';
import './app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainer extends StatefulWidget {
  final Map<String, dynamic> onData;
  final Future<bool> Function(String, Map<String, dynamic>) logEvent;
  final Object deepLinkData;

  HomeContainer({this.onData, this.deepLinkData, this.logEvent});

  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  final String eventName = "purchase";
  final Map<String, String> eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "20"
  };

  String _logEventResponse = "No event have been sent";
  TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    final text = widget.deepLinkData != null
        ? Utils.formatJson(widget.deepLinkData)
        : "No Attribution data";

    textEditingController = TextEditingController(text: text);
  }

  @override
  void dispose() {
    textEditingController?.dispose();
    super.dispose();
  }

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
                controller: textEditingController,
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
                      print("Pressed");
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
                    child: Text("Send purchase event"),
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
