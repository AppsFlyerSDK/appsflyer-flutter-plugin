import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TextBorder extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;

  const TextBorder({
    required this.controller,
    required this.labelText,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Add some vertical margin
      child: TextField(
        controller: controller,
        enabled: false,
        maxLines: null,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.blueGrey), // Change the color of the label
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              width: 1.0
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              width: 1.0
            ),
          ),
        ),
      ),
    );
  }
}