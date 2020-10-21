import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import './main_page.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MainPage(),
    );
  }
}
