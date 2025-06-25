import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/widgets/row.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> downloadFile(String url) async {
  try {
    final dir = await getTemporaryDirectory();
    final fileName = url.split('/').last.split('?').first;
    final savePath = '${dir.path}/$fileName';
    await Dio().download(url, savePath);
    return savePath;
  } catch (e) {
    return null;
  }
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
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Request Details",
          style: TextStyle(fontFamily: "NexaBold", color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow("Status", ''),
            detailRow('', data['Status'] ?? 'Pending'),
            const SizedBox(height: 4),
            detailRow("Student Name", ''),
            detailRow('', data['StudentName'] ?? ''),
            const SizedBox(height: 4),
            detailRow("Start Date", ''),
            detailRow("", data['StartDate'] ?? ''),
            const SizedBox(height: 4),
            detailRow("End Date", ''),
            detailRow("", data['EndDate'] ?? ''),
            const SizedBox(height: 4),
            detailRow("Request Date", ''),
            detailRow("", data['RequestDate'] ?? ''),
            const SizedBox(height: 4),
            const Text(
              "Reason:",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['Reason'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            // Display supporting document if exists
            if (data['SupportingDocument'] != null &&
                data['SupportingDocument'].toString().isNotEmpty)
              const Text(
                "Supporting Document:",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.attach_file, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior
                              .opaque, // Ensures the whole area is clickable
                      onTap: () async {
                        final path = data['SupportingDocument'];
                        if (path == null || path.isEmpty) return;

                        if (path.startsWith('http')) {
                          // Download the file first
                          final savePath = await downloadFile(path);
                          if (savePath != null) {
                            final result = await OpenFile.open(savePath);
                            if (result.type != ResultType.done) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open file.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed.')),
                            );
                          }
                        } else {
                          // It's a local file, open with OpenFile
                          final result = await OpenFile.open(path);
                          if (result.type != ResultType.done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open file.')),
                            );
                          }
                        }
                      },
                      child: Text(
                        (() {
                          final path = data['SupportingDocument'] ?? '';
                          if (path.isEmpty) return '';
                          final ext = path.split('.').last.toLowerCase();
                          return ext == 'jpg' || ext == 'jpeg'
                              ? 'Image File (JPG)'
                              : ext == 'png'
                              ? 'Image File (PNG)'
                              : ext == 'pdf'
                              ? 'PDF File'
                              : ext.toUpperCase() + ' File';
                        })(),
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Leave Request Details",
          style: TextStyle(fontFamily: "NexaBold", color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow("Status", ''),
            detailRow('', data['Status'] ?? 'Pending'),
            const SizedBox(height: 4),
            detailRow("Student Name", ''),
            detailRow('', data['StudentName'] ?? ''),
            const SizedBox(height: 4),
            detailRow("Start Date", ''),
            detailRow("", data['StartDate'] ?? ''),
            const SizedBox(height: 4),
            detailRow("End Date", ''),
            detailRow("", data['EndDate'] ?? ''),
            const SizedBox(height: 4),
            detailRow("Request Date", ''),
            detailRow("", data['RequestDate'] ?? ''),
            const SizedBox(height: 4),
            const Text(
              "Reason:",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['Reason'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 10),
            // Display supporting document if exists
            if (data['SupportingDocument'] != null &&
                data['SupportingDocument'].toString().isNotEmpty)
              const Text(
                "Supporting Document:",
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.attach_file, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior
                              .opaque, // Ensures the whole area is clickable
                      onTap: () async {
                        final path = data['SupportingDocument'];
                        if (path == null || path.isEmpty) return;

                        if (path.startsWith('http')) {
                          final savePath = await downloadFile(path);
                          if (savePath != null) {
                            final result = await OpenFile.open(savePath);
                            if (result.type != ResultType.done) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not open file.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed.')),
                            );
                          }
                        } else {
                          final result = await OpenFile.open(path);
                          if (result.type != ResultType.done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open file.')),
                            );
                          }
                        }
                      },
                      child: Text(
                        (() {
                          final path = data['SupportingDocument'] ?? '';
                          if (path.isEmpty) return '';
                          final ext = path.split('.').last.toLowerCase();
                          return ext == 'jpg' || ext == 'jpeg'
                              ? 'Image File (JPG)'
                              : ext == 'png'
                              ? 'Image File (PNG)'
                              : ext == 'pdf'
                              ? 'PDF File'
                              : ext.toUpperCase() + ' File';
                        })(),
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
