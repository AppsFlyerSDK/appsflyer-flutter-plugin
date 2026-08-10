// ignore_for_file: unnecessary_library_name

/// The public API for the AppsFlyer SDK 7 Flutter plugin.
///
/// Use [AppsFlyerSdk.instance] to initialize the SDK, register native listeners,
/// receive SDK events, and call the supported Android and iOS APIs.
library appsflyer_sdk;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'src/appsflyer_constants.dart';
part 'src/appsflyer_event.dart';
part 'src/appsflyer_invite_link_params.dart';
part 'src/appsflyer_sdk.dart';
part 'src/udl/deep_link_result.dart';
part 'src/udl/deeplink.dart';
part 'src/purchase_connector/purchase_connector.dart';
part 'src/purchase_connector/connector_callbacks.dart';
part 'src/purchase_connector/missing_configuration_exception.dart';
part 'src/purchase_connector/purchase_connector_configuration.dart';
part 'src/purchase_connector/store_kit_version.dart';
part 'src/purchase_connector/models/subscription_purchase.dart';
part 'src/purchase_connector/models/in_app_purchase_validation_result.dart';
part 'src/purchase_connector/models/product_purchase.dart';
part 'src/purchase_connector/models/subscription_validation_result.dart';
part 'src/purchase_connector/models/validation_failure_data.dart';
part 'src/purchase_connector/models/jvm_throwable.dart';
part 'src/purchase_connector/models/ios_error.dart';
part 'appsflyer_sdk.g.dart';
part 'src/af_purchase_details.dart';
part 'src/appsflyer_exception.dart';
