import 'package:flutter/material.dart';

class CustomSnackBar {
  SnackBar errorSnackBar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        textColor: Colors.white,
        label: 'Dismiss',
        onPressed: () {},
      ),
    );
  }

  SnackBar successSnackBar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    );
  }

  SnackBar infoSnackBar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.blueAccent,
      duration: const Duration(seconds: 3),
    );
  }
}
