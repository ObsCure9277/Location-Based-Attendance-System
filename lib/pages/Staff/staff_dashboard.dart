import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:location_based_attendance_app/helpers/printing_helper.dart';

class StaffDashboardpage extends StatefulWidget {
  const StaffDashboardpage({super.key});

  @override
  State<StaffDashboardpage> createState() => _StaffDashboardpageState();
}

double screenHeight = 0;
double screenWidth = 0;

class _StaffDashboardpageState extends State<StaffDashboardpage> {
  int touchedIndex = -1;
  String _searchQuery = '';
  String? staffName;

  final Map<String, Color> statusColorMap = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Leave': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    fetchStaffName();
  }

  Future<void> fetchStaffName() async {
    final staffDoc =
        await FirebaseFirestore.instance
            .collection('Staff')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
    setState(() {
      staffName = staffDoc['name'];
    });
  }

  Future<void> exportPieChartToPdf(
    BuildContext context,
    List<Map<String, dynamic>> filteredRates,
  ) async {
    // Create a global key to identify the pie chart
    final pieChartKey = GlobalKey();

    // Current subject display text
    final subjectText = _searchQuery.isEmpty ? 'All Subjects' : _searchQuery;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Preparing chart for PDF export..."),
                ],
              ),
            ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop();

      await showDialog(
        context: context,
        builder:
            (dialogContext) => Dialog(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Attendance Rate by Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subjectText,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      key: pieChartKey,
                      child: SizedBox(
                        height: 250,
                        width: 250,
                        child: PieChart(
                          PieChartData(
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(filteredRates.length, (i) {
                              final data = filteredRates[i];
                              return PieChartSectionData(
                                color:
                                    statusColorMap[data['status']] ??
                                    Colors.grey,
                                value: data['rate'],
                                title:
                                    '${data['status']}\n${data['rate'].toStringAsFixed(1)}%',
                                radius: 60.0,
                                titleStyle: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(filteredRates.length, (i) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color:
                                    statusColorMap[filteredRates[i]['status']] ??
                                    Colors.grey,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${filteredRates[i]['status']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (ctx) => const AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text(
                                            "Generating PDF...",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              );

                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );

                              // Capture the chart as image
                              final boundary =
                                  pieChartKey.currentContext!.findRenderObject()
                                      as RenderRepaintBoundary;
                              final image = await boundary.toImage(
                                pixelRatio: 1.5,
                              );
                              final byteData = await image.toByteData(
                                format: ui.ImageByteFormat.png,
                              );

                              if (byteData == null) {
                                throw Exception("Failed to get image data");
                              }

                              final pngBytes = byteData.buffer.asUint8List();

                              Navigator.pop(dialogContext);

                              final pdf = pw.Document();
                              final imageProvider = pw.MemoryImage(pngBytes);

                              pdf.addPage(
                                pw.Page(
                                  pageFormat: PdfPageFormat.a4,
                                  build: (pw.Context context) {
                                    return pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Header(
                                          level: 0,
                                          child: pw.Text(
                                            'Attendance Status Report',
                                            style: pw.TextStyle(
                                              fontSize: 24,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        pw.SizedBox(height: 20),
                                        pw.Text(
                                          'Staff: $staffName',
                                          style: pw.TextStyle(fontSize: 16),
                                        ),
                                        pw.Text(
                                          'Subject: $subjectText',
                                          style: pw.TextStyle(fontSize: 16),
                                        ),
                                        pw.Text(
                                          'Generated Date: ${DateTime.now().toString().split(' ')[0]}',
                                          style: pw.TextStyle(fontSize: 16),
                                        ),
                                        pw.SizedBox(height: 30),
                                        pw.Center(
                                          child: pw.Image(
                                            imageProvider,
                                            height: 400,
                                          ),
                                        ),
                                        pw.SizedBox(height: 30),
                                        pw.Text(
                                          'Status Summary:',
                                          style: pw.TextStyle(
                                            fontSize: 18,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                        pw.SizedBox(height: 10),
                                        ...filteredRates.map(
                                          (rate) => pw.Text(
                                            '${rate['status']}: ${rate['rate'].toStringAsFixed(1)}%',
                                            style: pw.TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );

                              Navigator.of(context).pop();

                              // Save PDF using our helper
                              await PrintingHelper.savePdfToStorage(
                                context,
                                pdf,
                                'attendance_report_${DateTime.now().millisecondsSinceEpoch}',
                              );
                            } catch (e) {
                              // Close dialogs in case of error
                              try {
                                Navigator.of(dialogContext).pop();
                              } catch (_) {}

                              try {
                                Navigator.of(context).pop();
                              } catch (_) {}

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to generate PDF: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text(
                            'Generate PDF',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Stream for attendance status rates by subject
  Stream<List<Map<String, dynamic>>> attendanceStatusStream(
    String subjectQuery,
  ) async* {
    if (staffName == null) {
      yield [];
      return;
    }

    // Get timetable entries for this staff
    final timetableSnapshot = await FirebaseFirestore.instance
        .collection('Timetable')
        .where('Lecturer', isEqualTo: staffName)
        .get();

    // Filter by subject if needed
    final filteredTimetableDocs = timetableSnapshot.docs.where((doc) {
      final subject = (doc['Subject'] ?? 'Unknown').toString().trim().toLowerCase();
      final query = subjectQuery.trim().toLowerCase();
      return query.isEmpty ? true : subject == query;
    }).toList();

    // If no matching timetables, return empty result
    if (filteredTimetableDocs.isEmpty) {
      yield [];
      return;
    }

    // Get all timetable IDs
    final List<String> allTimetableIds = filteredTimetableDocs.map((doc) => doc.id).toList();
    
    // Create a controller to yield results
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    // Track attendance counts by status
    Map<String, int> statusCounts = {};
    int totalRecords = 0;
    
    // Function to process results and yield to controller
    void processResults() {
      if (totalRecords == 0) {
        controller.add([]);
        return;
      }
      
      // Convert to percentage
      final List<Map<String, dynamic>> statusRates = statusCounts.entries.map((entry) {
        final rate = (entry.value / totalRecords) * 100;
        return {'status': entry.key, 'rate': rate, 'subject': subjectQuery};
      }).toList();
      
      controller.add(statusRates);
    }
    
    // Break up the timetable IDs into batches of 10 (Firestore's whereIn limit)
    for (int i = 0; i < allTimetableIds.length; i += 10) {
      final end = (i + 10 < allTimetableIds.length) ? i + 10 : allTimetableIds.length;
      final batchIds = allTimetableIds.sublist(i, end);
      
      // Create a query for each batch
      final query = FirebaseFirestore.instance
          .collection('Attendance')
          .where('timetableId', whereIn: batchIds);
      
      // Get a snapshot once (not a stream)
      final snapshot = await query.get();
      
      // Count records by status
      for (var doc in snapshot.docs) {
        final status = doc['attendanceStatus'] ?? 'Unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        totalRecords++;
      }
    }
    
    // Process all results
    processResults();
    
    // Create a merged stream for real-time updates
    // This is simpler than trying to merge multiple streams
    final mainQuery = FirebaseFirestore.instance
        .collection('Attendance')
        .where('timetableId', whereIn: 
            allTimetableIds.length > 10 ? allTimetableIds.sublist(0, 10) : allTimetableIds)
        .snapshots();
    
    final subscription = mainQuery.listen((snapshot) {
      // Just notify that data changed - trigger a refresh
      processResults();
    });
    
    // Clean up when stream is done
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };
    
    // Yield the stream
    yield* controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Text(
          'Attendance Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream:
                staffName == null
                    ? const Stream.empty()
                    : FirebaseFirestore.instance
                        .collection('Timetable')
                        .where('Lecturer', isEqualTo: staffName)
                        .snapshots(),
            builder: (context, snapshot) {
              final subjectSet = <String>{};
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final subject =
                      (doc['Subject'] ?? 'Unknown').toString().trim();
                  subjectSet.add(subject);
                }
              }
              final subjects = ['All', ...subjectSet];
              return PopupMenuButton<String>(
                tooltip: 'Filter Subject',
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onSelected: (value) {
                  setState(() {
                    _searchQuery = value == 'All' ? '' : value;
                  });
                },
                itemBuilder: (context) {
                  return subjects.map((subject) {
                    return PopupMenuItem<String>(
                      value: subject,
                      child: Text(
                        subject == 'All' ? 'All Subjects' : subject,
                        style: TextStyle(
                          fontFamily: 'NexaBold',
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: attendanceStatusStream(_searchQuery),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final filteredRates = snapshot.data!;
          if (filteredRates.isEmpty) {
            return Center(
              child: Text(
                "No Attendance Data Found.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream:
                      staffName == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('Timetable')
                              .where('Lecturer', isEqualTo: staffName)
                              .snapshots(),
                  builder: (context, timetableSnapshot) {
                    if (!timetableSnapshot.hasData) {
                      return SizedBox(
                        height: screenHeight * 0.125,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final timetableDocs = timetableSnapshot.data!.docs;
                    final timetableIds =
                        timetableDocs
                            .where(
                              (doc) =>
                                  _searchQuery.isEmpty
                                      ? true
                                      : (doc['Subject'] ?? 'Unknown')
                                              .toString()
                                              .trim()
                                              .toLowerCase() ==
                                          _searchQuery.trim().toLowerCase(),
                            )
                            .map((doc) => doc.id)
                            .toList();

                    if (timetableIds.isEmpty) {
                      return Container(
                        margin: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          top: screenHeight * 0.025,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        height: screenHeight * 0.125,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.all(
                            Radius.circular(screenWidth * 0.05),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildSummaryColumn('Present', 0, Colors.green),
                            buildSummaryColumn('Leave', 0, Colors.orange),
                            buildSummaryColumn('Absent', 0, Colors.red),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('Attendance')
                              .where('timetableId', whereIn: timetableIds)
                              .snapshots(),
                      builder: (context, attendanceSnapshot) {
                        if (!attendanceSnapshot.hasData) {
                          return SizedBox(
                            height: screenHeight * 0.125,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final attendanceDocs = attendanceSnapshot.data!.docs;
                        int present = 0, leave = 0, absent = 0;
                        for (var doc in attendanceDocs) {
                          final status = doc['attendanceStatus'];
                          if (status == 'Present') present++;
                          if (status == 'Leave') leave++;
                          if (status == 'Absent') absent++;
                        }
                        return Container(
                          margin: EdgeInsets.only(
                            left: screenWidth * 0.05,
                            right: screenWidth * 0.05,
                            top: screenHeight * 0.025,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          height: screenHeight * 0.125,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.all(
                              Radius.circular(screenWidth * 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildSummaryColumn(
                                'Present',
                                present,
                                Colors.green,
                              ),
                              buildSummaryColumn('Leave', leave, Colors.orange),
                              buildSummaryColumn('Absent', absent, Colors.red),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                Container(
                  margin: EdgeInsets.only(
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    top: screenHeight * 0.025,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    color: Colors.black,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(width: screenWidth * 0.025),
                            Text(
                              'Attendance Rate by Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.04,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.11),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    exportPieChartToPdf(context, filteredRates);
                                  },
                                  child: Icon(
                                    Icons.print,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (filteredRates.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: screenHeight * 0.01,
                              bottom: screenHeight * 0.01,
                            ),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'All Subjects'
                                  : filteredRates
                                      .map((e) => e['subject'])
                                      .toSet()
                                      .join(', '),
                              style: TextStyle(
                                fontSize: screenWidth * 0.0375,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          height: screenHeight * 0.30,
                          width: screenWidth * 0.575,
                          child: Container(
                            color: Colors.black,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (
                                    FlTouchEvent event,
                                    pieTouchResponse,
                                  ) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex =
                                          pieTouchResponse
                                              .touchedSection!
                                              .touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: screenWidth * 0.005,
                                centerSpaceRadius: screenWidth * 0.1,
                                sections: List.generate(filteredRates.length, (
                                  i,
                                ) {
                                  final isTouched = i == touchedIndex;
                                  final fontSize =
                                      isTouched
                                          ? screenWidth * 0.05
                                          : screenWidth * 0.035;
                                  final radius =
                                      isTouched
                                          ? screenWidth * 0.16
                                          : screenWidth * 0.135;
                                  final data = filteredRates[i];
                                  return PieChartSectionData(
                                    color:
                                        statusColorMap[data['status']] ??
                                        Colors.grey,
                                    value: data['rate'],
                                    title:
                                        '${data['status']}\n${data['rate'].toStringAsFixed(1)}%',
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.0125),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(filteredRates.length, (i) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.0025,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: screenWidth * 0.03,
                                    height: screenWidth * 0.03,
                                    decoration: BoxDecoration(
                                      color:
                                          statusColorMap[filteredRates[i]['status']] ??
                                          Colors.grey,
                                      shape: BoxShape.rectangle,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.0125),
                                  Text(
                                    '${filteredRates[i]['status']}',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.025),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget buildSummaryColumn(String label, int count, Color color) {
  return Expanded(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: "NexaRegular",
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: "NexaBold",
            fontSize: screenWidth * 0.055,
            color: color,
          ),
        ),
      ],
    ),
  );
}
