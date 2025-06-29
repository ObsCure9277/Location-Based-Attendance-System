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

class _StaffDashboardpageState extends State<StaffDashboardpage> {
  int touchedIndex = -1;
  String _searchQuery = '';
  String? staffName;

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

  final Map<String, Color> statusColorMap = {
    'Present': Colors.green,
    'Absent': Colors.red,
    'Leave': Colors.orange,
  };

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
                  Text(
                    "Preparing chart for PDF export...",
                  ),
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
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Attendance Rate by Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
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
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              ),
                            )
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
                                          )
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

                              // Close loading dialog
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

                              print('Error generating PDF: $e');
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
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

      print('Error in PDF export: $e');
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
    final timetableSnapshot =
        await FirebaseFirestore.instance
            .collection('Timetable')
            .where('Lecturer', isEqualTo: staffName ?? '')
            .get();

    final timetableMap = <String, String>{};
    for (var doc in timetableSnapshot.docs) {
      final subject = (doc['Subject'] ?? 'Unknown').toString().trim();
      timetableMap[doc.id] = subject;
    }

    await for (final attendanceSnapshot
        in FirebaseFirestore.instance.collection('Attendance').snapshots()) {
      final docs = attendanceSnapshot.docs;

      // Filter docs by subject
      final filteredDocs =
          docs.where((doc) {
            final timetableId = doc['timetableId'];
            final subject =
                (timetableMap[timetableId] ?? 'Unknown')
                    .toString()
                    .trim()
                    .toLowerCase();
            final query = subjectQuery.trim().toLowerCase();
            return query.isEmpty ? true : subject == query;
          }).toList();

      final total = filteredDocs.length;

      // Count each status
      final Map<String, int> statusCounts = {};
      for (var doc in filteredDocs) {
        final status = doc['attendanceStatus'] ?? 'Unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      // Convert to percentage
      final List<Map<String, dynamic>> statusRates =
          statusCounts.entries.map((entry) {
            final rate = total == 0 ? 0.0 : (entry.value / total) * 100;
            return {'status': entry.key, 'rate': rate, 'subject': subjectQuery};
          }).toList();

      yield statusRates;
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: 22,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
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
                        style: const TextStyle(fontFamily: 'NexaBold'),
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
            return const Center(
              child: Text(
                "No Attendance Data Found.",
                style: TextStyle(color: Colors.white),
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
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final timetableDocs = timetableSnapshot.data!.docs;
                    // Filter timetable IDs by subject if a subject is selected
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
                        margin: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(20)),
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
                          return const SizedBox(
                            height: 100,
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
                          margin: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.all(Radius.circular(20)),
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
                  margin: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    top: 20.0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Attendance Rate by Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (filteredRates.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'All Subjects'
                                  : filteredRates
                                      .map((e) => e['subject'])
                                      .toSet()
                                      .join(', '),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          height: 200,
                          width: 230,
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
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: List.generate(filteredRates.length, (
                                  i,
                                ) {
                                  final isTouched = i == touchedIndex;
                                  final fontSize = isTouched ? 20.0 : 14.0;
                                  final radius = isTouched ? 65.0 : 55.0;
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(filteredRates.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => exportPieChartToPdf(context, filteredRates),
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Export Chart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
