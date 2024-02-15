import 'dart:async';
import 'package:flutter/material.dart';
import './app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainer extends StatefulWidget {
  final Map onData;
  final Future<bool?> Function(String, Map) logEvent;
  Object deepLinkData;

  HomeContainer({
    required this.onData,
    required this.deepLinkData,
    required this.logEvent,
  });

  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  final String eventName = "Purchase Event";

  final Map eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "20"
  };

  String _logEventResponse = "Awaiting event status";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.CONTAINER_PADDING),
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
        ),child: Column(
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
            TextBorder(
              controller: TextEditingController(
                text: widget.onData.isNotEmpty
                    ? Utils.formatJson(widget.onData)
                    : "Waiting for conversion data...",
              ),
              labelText: "CONVERSION DATA",
            ),
            SizedBox(height: 12.0),
            TextBorder(
              controller: TextEditingController(
                text: widget.deepLinkData != null
                    ? Utils.formatJson(widget.deepLinkData)
                    : "Waiting for attribution data...",
              ),
              labelText: "ATTRIBUTION DATA",
            ),
          ],
        ),
        ),
            SizedBox(height: 12.0),
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
                children: <Widget>[
                  Text(
                    "EVENT LOGGER",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
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
                    controller: TextEditingController(
                        text: _logEventResponse
                    ),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      widget.logEvent(eventName, eventValues).then((onValue) {
                        setState(() {
                          _logEventResponse = "Event Status: " + onValue.toString();
                        });
                      }).catchError((onError) {
                        setState(() {
                          _logEventResponse = "Error: " + onError.toString();
                        });
                      });
                    },
                    child: Text("Trigger Purchase Event"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}