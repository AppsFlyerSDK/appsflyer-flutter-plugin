import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/material.dart';

import './app_constants.dart';
import 'appsflyer_service.dart';
import 'text_border.dart';
import 'utils.dart';

class HomeContainer extends StatefulWidget {
  final AppsFlyerService appsFlyerService;
  final DeepLinkResponse deepLinkData;
  final AppInstallResponse appInstallData;

  HomeContainer({@required this.appsFlyerService})
      : deepLinkData = appsFlyerService.deepLinkData,
        appInstallData = appsFlyerService.appInstallResponse;

  @override
  _HomeContainerState createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer> {
  final String eventName = 'purchase';
  final Map<String, String> eventValues = {
    'af_content_id': 'id123',
    'af_currency': 'USD',
    'af_revenue': '20'
  };

  TextEditingController inviteLinkController;
  TextEditingController attributionController;
  TextEditingController deepLinkController;
  TextEditingController eventController;
  TextEditingController responseController;

  AppsflyerSdk get sdk => widget.appsFlyerService.sdk;

  @override
  void initState() {
    super.initState();
    final attributionData = widget.deepLinkData != null
        ? Utils.prettyPrintDiagnosticable(widget.appInstallData)
        : 'No attribution data';
    final deepLinkData = widget.deepLinkData != null
        ? Utils.prettyPrintDiagnosticable(widget.deepLinkData)
        : 'No deep link data';
    final eventData =
        'event name: $eventName\nevent values: ${Utils.formatJson(eventValues)}';
    final responseDefault = 'No event has been sent';
    final inviteLinkDefault = 'No link has been generated';

    inviteLinkController = TextEditingController(text: inviteLinkDefault);
    attributionController = TextEditingController(text: attributionData);
    deepLinkController = TextEditingController(text: deepLinkData);
    eventController = TextEditingController(text: eventData);
    responseController = TextEditingController(text: responseDefault);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    [
      inviteLinkController,
      attributionController,
      deepLinkController,
      eventController,
      responseController,
    ].forEach((controller) => controller?.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.containerPadding),
        child: Column(
          children: <Widget>[
            Text('AF SDK', style: TextStyle(fontWeight: FontWeight.bold)),
            Padding(padding: EdgeInsets.only(top: AppConstants.topPadding)),
            SizedBox(height: 12.0),
            TextBorder(
              labelText: 'Attribution Data:',
              controller: attributionController,
            ),
            SizedBox(height: 12.0),
            TextBorder(
              labelText: 'Deep Link Data:',
              controller: deepLinkController,
            ),
            SizedBox(height: 12.0),
            _buildPurchaseEventSection(),
            _buildGenerateLinkSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseEventSection() {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: <Widget>[
          Center(child: Text('Log event')),
          SizedBox(height: 12.0),
          TextBorder(
            labelText: 'Event Request',
            controller: eventController,
          ),
          SizedBox(height: 12.0),
          TextBorder(
            labelText: 'Server response',
            controller: responseController,
          ),
          SizedBox(height: 12.0),
          AsyncButton(
            onPressed: () async {
              print('Purchase Event Button Pressed');
              final value = await sdk.logEvent(
                eventName,
                eventValues,
              );

              responseController.text = value.toString();
            },
            builder: (isBusy) {
              return isBusy
                  ? Text('Sending event...')
                  : Text('Send Purchase Event');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateLinkSection() {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: <Widget>[
          Center(child: Text('Generate Link')),
          SizedBox(height: 12.0),
          TextBorder(
            labelText: 'Invite Link',
            controller: inviteLinkController,
          ),
          SizedBox(height: 12.0),
          AsyncButton(
            onPressed: _generateInviteLink,
            builder: (isBusy) => isBusy
                ? Text('Generating Link...')
                : Text('Generate Invite Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInviteLink() async {
    debugPrint('Generating Invite Link');

    final params = AppsFlyerInviteLinkParams(
      baseDeepLink: 'sub.onelink.me',
      brandDomain: 'sub.domain.com',
      campaign: 'Your Campaign Name',
      customerID: 'Generated Link Campaign',
      referrerImageUrl:
          r'https://cdn.appsflyer.com/af-libs/fe-components-global/4.3.41/af-logo-white.21a9ef88fd066e8acf2c1e3af4d46dd3.png',
      referrerName: 'Mobile App',
    );

    final service = widget.appsFlyerService;
    final appsFlyerResponse = await service.generateInviteLinkAsync(params);

    inviteLinkController.text = Utils.prettyPrintDiagnosticable(
      appsFlyerResponse,
    );
  }
}

class AsyncButton extends StatefulWidget {
  final Future Function() onPressed;
  final Widget Function(bool isBusy) builder;

  const AsyncButton({
    @required this.onPressed,
    @required this.builder,
    Key key,
  }) : super(key: key);

  @override
  _AsyncButtonState createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool isBusy = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBusy
          ? null
          : () async {
              setState(() => isBusy = true);
              await widget.onPressed();
              setState(() => isBusy = false);
            },
      child: widget.builder(isBusy),
    );
  }
}
