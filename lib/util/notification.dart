import 'package:flutter/material.dart';

void showSnackbarMessage(BuildContext context, String message) {
  ///    Shows notification in snackbar
  final snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
