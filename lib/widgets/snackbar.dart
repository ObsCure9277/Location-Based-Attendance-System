import 'package:flutter/material.dart';

class CustomSnackBar {
  SnackBar errorSnackBar({required String message}) {
    return SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
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
}
