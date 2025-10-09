import 'dart:async';
import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainerStreams extends StatefulWidget {
  final Stream<Map> onData;
  final Stream<Map> onAttribution;
  final Future<bool> Function(String, Map) logEvent;

  // ignore: prefer_const_constructors_in_immutables
  HomeContainerStreams({
    Key? key,
    required this.onData,
    required this.onAttribution,
    required this.logEvent,
  }) : super(key: key);

  @override
  State<HomeContainerStreams> createState() => _HomeContainerStreamsState();
}

class _HomeContainerStreamsState extends State<HomeContainerStreams> {
  final String eventName = "Custom Event";

  final Map eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "2"
  };

  String _logEventResponse =
      "Event status will be shown here once it's triggered.";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueGrey, width: 0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "APPSFLYER SDK",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppConstants.topPadding),
                    StreamBuilder<dynamic>(
                      stream: widget.onData.asBroadcastStream(),
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        return TextBorder(
                          controller: TextEditingController(
                              text: snapshot.hasData
                                  ? Utils.formatJson(snapshot.data)
                                  : "Waiting for conversion data..."),
                          labelText: "CONVERSION DATA",
                        );
                      },
                    ),
                    const SizedBox(height: 12.0),
                    StreamBuilder<dynamic>(
                        stream: widget.onAttribution.asBroadcastStream(),
                        builder: (BuildContext context,
                            AsyncSnapshot<dynamic> snapshot) {
                          return TextBorder(
                            controller: TextEditingController(
                                text: snapshot.hasData
                                    ? Utils.formatJson(snapshot.data)
                                    : "Waiting for attribution data..."),
                            labelText: "ATTRIBUTION DATA",
                          );
                        }),
                  ],
                )),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey, width: 0.5),
              ),
              child: Column(children: <Widget>[
                const Text(
                  "EVENT LOGGER",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12.0),
                TextBorder(
                  controller: TextEditingController(
                      text:
                          "Event Name: $eventName\nEvent Values: $eventValues"),
                  labelText: "EVENT REQUEST",
                ),
                const SizedBox(height: 12.0),
                TextBorder(
                  labelText: "SERVER RESPONSE",
                  controller: TextEditingController(text: _logEventResponse),
                ),
                const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text("Trigger Event"),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
