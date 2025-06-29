import 'dart:io';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PrintingHelper {
  static Future<void> savePdfToStorage(
    BuildContext context, 
    pw.Document pdf, 
    String fileName
  ) async {
    try {
      // Get storage directory
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName.pdf';
      final file = File(path);
      
      // Save PDF
      await file.writeAsBytes(await pdf.save());
      
      // Show success message with share option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF saved successfully!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              Share.shareXFiles([XFile(path)], text: 'Attendance Report');
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(
          message:'Error saving PDF: $e'
        ),
      );
    }
  }
}