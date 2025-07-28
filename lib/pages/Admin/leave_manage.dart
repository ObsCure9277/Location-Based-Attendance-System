import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/widgets/row.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:io';

double screenHeight = 0;
double screenWidth = 0;

Future<void> downloadWithDownloader(String url, {String? fileName}) async {
  final saveDir = await getDownloadDirectory();
  final name = fileName ?? url.split('/').last.split('?').first;

  final _ = await FlutterDownloader.enqueue(
    url: url,
    savedDir: saveDir,
    fileName: name,
    showNotification: true,
    openFileFromNotification: true,
  );
}

Future<String> getDownloadDirectory() async {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/Download';
  } else {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }
}

String getDirectCloudinaryUrl(String url) {
  if (url.contains('/upload/')) {
    return url.replaceFirst('/upload/', '/upload/fl_attachment/');
  }
  return url;
}

class LeaveRequestDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? docId; // Pass the document ID for updating

  const LeaveRequestDetailPage({super.key, required this.data, this.docId});

  Future<void> updateStatus(BuildContext context, String status) async {
    if (docId == null) return;
    await FirebaseFirestore.instance
        .collection('LeaveRequests')
        .doc(docId)
        .update({'Status': status});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    final List<dynamic> files = data['SupportingDocument'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leave Request Details",
          style: TextStyle(
            fontFamily: "NexaBold",
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow("Status", ''),
            detailRow('', data['Status'] ?? 'Pending'),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Student Name", ''),
            detailRow('', data['StudentName'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Start Date", ''),
            detailRow("", data['StartDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("End Date", ''),
            detailRow("", data['EndDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Request Date", ''),
            detailRow("", data['RequestDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            Text(
              "Reason:",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: screenWidth * 0.045,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              data['Reason'] ?? '',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.0125),
            // Display supporting document if exists
            if (files.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Supporting Document:",
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  ...files.map((fileUrl) {
                    final ext =
                        fileUrl.toString().split('.').last.toLowerCase();
                    final fileLabel =
                        ext == 'jpg' || ext == 'jpeg'
                            ? 'Image File (JPG)'
                            : ext == 'png'
                            ? 'Image File (PNG)'
                            : ext == 'pdf'
                            ? 'PDF File'
                            : '${ext.toUpperCase()} File';
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.attach_file,
                            color: Colors.black,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                String downloadUrl = fileUrl;
                                if (downloadUrl.contains('cloudinary.com')) {
                                  downloadUrl = getDirectCloudinaryUrl(
                                    downloadUrl,
                                  );
                                }
                                print('Downloading from: $downloadUrl');
                                await downloadWithDownloader(downloadUrl);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar().successSnackBar(
                                    message:
                                        'Download started. Check your notifications.',
                                  ),
                                );
                              },
                              child: Text(
                                fileLabel,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontSize:
                                      screenWidth *
                                      0.035, // Added responsive size
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => updateStatus(context, 'Approved'),
                  child: leaveRequestButtonInText(
                    'Approve',
                    screenHeight,
                    screenWidth / 2.5,
                    screenWidth / 26,
                    Colors.green,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => updateStatus(context, 'Rejected'),
                  child: leaveRequestButtonInText(
                    'Reject',
                    screenHeight,
                    screenWidth / 2.5,
                    screenWidth / 26,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudentLeaveDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? docId; // Pass the document ID for updating

  const StudentLeaveDetailPage({super.key, required this.data, this.docId});

  Future<void> updateStatus(BuildContext context, String status) async {
    if (docId == null) return;
    await FirebaseFirestore.instance
        .collection('LeaveRequests')
        .doc(docId)
        .update({'Status': status});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    final List<dynamic> files = data['SupportingDocument'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leave Request Details",
          style: TextStyle(
            fontFamily: "NexaBold",
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow("Status", ''),
            detailRow('', data['Status'] ?? 'Pending'),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Student Name", ''),
            detailRow('', data['StudentName'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Start Date", ''),
            detailRow("", data['StartDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("End Date", ''),
            detailRow("", data['EndDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            detailRow("Request Date", ''),
            detailRow("", data['RequestDate'] ?? ''),
            SizedBox(height: screenHeight * 0.005),
            Text(
              "Reason:",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: screenWidth * 0.045,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              data['Reason'] ?? '',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.0125),
            // Display supporting document if exists
            if (files.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Supporting Document:",
                    style: TextStyle(
                      fontFamily: "NexaBold",
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  ...files.map((fileUrl) {
                    final ext =
                        fileUrl.toString().split('.').last.toLowerCase();
                    final fileLabel =
                        ext == 'jpg' || ext == 'jpeg'
                            ? 'Image File (JPG)'
                            : ext == 'png'
                            ? 'Image File (PNG)'
                            : ext == 'pdf'
                            ? 'PDF File'
                            : '${ext.toUpperCase()} File';
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.attach_file,
                            color: Colors.black,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                String downloadUrl = fileUrl;
                                if (downloadUrl.contains('cloudinary.com')) {
                                  downloadUrl = getDirectCloudinaryUrl(
                                    downloadUrl,
                                  );
                                }
                                print('Downloading from: $downloadUrl');
                                await downloadWithDownloader(downloadUrl);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar().successSnackBar(
                                    message:
                                        'Download started. Check your notifications.',
                                  ),
                                );
                              },
                              child: Text(
                                fileLabel,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontSize:
                                      screenWidth *
                                      0.035, // Added responsive size
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
