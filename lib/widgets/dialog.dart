import 'package:flutter/material.dart';

class ConfirmDialog {
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    Widget? customContent, // Add this parameter
    String cancelText = 'Cancel',
    String deleteText = 'Delete',
    Color deleteColor = Colors.red,
    TextStyle? style,
  }) async {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Show the dialog and await the result
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must select an option
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'NexaBold',
            fontSize: screenWidth * 0.045,
          ),
        ),
        content: customContent ?? Text(
          message,
          style: style ?? TextStyle(
            fontFamily: 'NexaRegular',
            fontSize: screenWidth * 0.04,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: TextStyle(
                fontFamily: 'NexaBold',
                fontSize: screenWidth * 0.035,
                color: Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              deleteText,
              style: TextStyle(
                fontFamily: 'NexaBold',
                fontSize: screenWidth * 0.035,
                color: deleteColor,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}