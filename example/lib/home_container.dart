import 'package:flutter/material.dart';
import './app_constants.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainer extends StatelessWidget {
  String gcdText;
  String onAppOpenAttributionText;
  String eventRequestText;
  String eventResponseText;
  Function onEventPress;

  var gcdTextField = TextEditingController();
  var onAppOpenAttributionTextField = TextEditingController();
  var eventRequestTextField = TextEditingController();
  var eventResponseTextField = TextEditingController();

  HomeContainer(
      {this.gcdText,
      this.onAppOpenAttributionText,
      this.eventResponseText,
      this.onEventPress}) {
    gcdTextField.text = gcdText;
    onAppOpenAttributionTextField.text = onAppOpenAttributionText;
    eventResponseTextField.text = eventResponseText;
    _initEventRequestTextField();
  }

  String eventName = "my event";
  Map eventValues = {
    "af_content_id": "id123",
    "af_currency": "USD",
    "af_revenue": "2"
  };

  _initEventRequestTextField() {
    String eventValuesStr = Utils.formatJson(eventValues);
    eventRequestTextField.text =
        "event name: ${eventName}\nevent values: ${eventValuesStr}";
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
                controller: gcdTextField,
                labelText: "Conversion Data:",
              ),
              Padding(
                padding: EdgeInsets.only(top: 12.0),
              ),
              TextBorder(
                controller: onAppOpenAttributionTextField,
                labelText: "OnAppOpenAttribution: ",
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
                    controller: eventRequestTextField,
                    labelText: "Event Request",
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.0),
                  ),
                  TextBorder(
                    controller: eventResponseTextField,
                    labelText: "Server Response",
                  ),
                  RaisedButton(
                    onPressed: () {
                      onEventPress(eventName, eventValues);
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
