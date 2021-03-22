import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TextBorder extends StatelessWidget {
  TextEditingController controller;
  String labelText;

  TextBorder({this.controller, this.labelText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: false,
      maxLines: null,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0.0),
        ),
      ),
    );
  }
}
