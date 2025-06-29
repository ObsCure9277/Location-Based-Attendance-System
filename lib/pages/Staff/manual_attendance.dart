import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';

class ManualAttendancepage extends StatefulWidget {
  final Map<String, dynamic> timetableData;
  final String timetableId;

  const ManualAttendancepage({
    super.key,
    required this.timetableData,
    required this.timetableId,
  });

  @override
  State<ManualAttendancepage> createState() => _ManualAttendancepageState();
}

class _ManualAttendancepageState extends State<ManualAttendancepage> {
  List<Map<String, dynamic>> students = [];
  Set<String> attendedStudentIds = {};
  bool loading = true;
  bool _ascending = true;
  String _sortType = 'Group';
  String _searchQuery = '';

  // Map to cache attendance statuses
  Map<String, String> attendanceStatusMap = {};

  @override
  void initState() {
    super.initState();
    fetchStudentsAndAttendance();
  }

  Future<void> fetchStudentsAndAttendance() async {
    setState(() => loading = true);

    // Get group names from timetable
    final groupNames =
        widget.timetableData['GroupNames'] != null
            ? List<String>.from(widget.timetableData['GroupNames'])
            : [];

    // Query students in these groups
    final studentsSnapshot =
        await FirebaseFirestore.instance
            .collection('Student')
            .where(
              'GroupName',
              whereIn: groupNames.isEmpty ? ['dummy'] : groupNames,
            )
            .get();

    final studentsList =
        studentsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'group': data['GroupName'] ?? '',
          };
        }).toList();

    // Query attendance for this timetable
    final attendanceSnapshot =
        await FirebaseFirestore.instance
            .collection('Attendance')
            .where('timetableId', isEqualTo: widget.timetableId)
            .get();

    final attendedIds = <String>{};
    attendanceStatusMap.clear();
    for (var doc in attendanceSnapshot.docs) {
      final studentId = doc['studentId'] as String;
      final status = doc['attendanceStatus'] as String? ?? 'Absent';
      attendanceStatusMap[studentId] = status;
      if (status == 'Present') attendedIds.add(studentId);
    }

    setState(() {
      students = studentsList;
      attendedStudentIds = attendedIds;
      loading = false;
    });
  }

  Future<void> setAttendance(String studentId, String status) async {
    // Find the attendance record for this student and timetable
    final snapshot = await FirebaseFirestore.instance
        .collection('Attendance')
        .where('studentId', isEqualTo: studentId)
        .where('timetableId', isEqualTo: widget.timetableId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final docRef = snapshot.docs.first.reference;
      await docRef.update({
        'attendanceStatus': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        if (status == 'Present') {
          attendedStudentIds.add(studentId);
        } else {
          attendedStudentIds.remove(studentId);
        }
        
        attendanceStatusMap[studentId] = status;
      });
    }
  }

  List<Map<String, dynamic>> get sortedStudents {
    List<Map<String, dynamic>> sorted = List.from(students);
    if (_sortType == 'Group') {
      sorted.sort((a, b) {
        int cmp = (a['group'] as String).compareTo(b['group'] as String);
        if (cmp == 0) {
          cmp = (a['name'] as String).compareTo(b['name'] as String);
        }
        return _ascending ? cmp : -cmp;
      });
    } else if (_sortType == 'Alphabet') {
      sorted.sort((a, b) {
        int cmp = (a['name'] as String).compareTo(b['name'] as String);
        if (cmp == 0) {
          cmp = (a['group'] as String).compareTo(b['group'] as String);
        }
        return _ascending ? cmp : -cmp;
      });
    }
    if (_searchQuery.isNotEmpty) {
      sorted = sorted
          .where((student) =>
              student['name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              student['group']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return sorted;
  }

  // Helper to check if sorting by group should be hidden
  bool get isSortByGroupHidden => (widget.timetableData['Type'] == 'T');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timetable Details',
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'Group') {
                setState(() {
                  _sortType = value;
                });
              } else if (value == 'Alphabet') {
                setState(() {
                  _sortType = value;
                });
              } else if (value == 'Ascending') {
                setState(() {
                  _ascending = true;
                });
              } else if (value == 'Descending') {
                setState(() {
                  _ascending = false;
                });
              }
            },
            itemBuilder: (context) => [
              if (!isSortByGroupHidden)
                const PopupMenuItem(
                  value: 'Group',
                  child: Text(
                    'Sort by Group',
                    style: TextStyle(fontFamily: 'NexaBold'),
                  ),
                ),
              const PopupMenuItem(
                value: 'Alphabet',
                child: Text(
                  'Sort by Name',
                  style: TextStyle(fontFamily: 'NexaBold'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Ascending',
                child: Text(
                  'Ascending',
                  style: TextStyle(fontFamily: 'NexaBold'),
                ),
              ),
              const PopupMenuItem(
                value: 'Descending',
                child: Text(
                  'Descending',
                  style: TextStyle(fontFamily: 'NexaBold'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: SplashScreen())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Subject: ',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.timetableData['Subject']}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Lecturer: ',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.timetableData['Lecturer']}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Location: ',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text: '${widget.timetableData['locationName']}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Time: ',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          TextSpan(
                            text:
                                '${widget.timetableData['StartTime']} - ${widget.timetableData['EndTime']}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Student by Name/Group',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Student:',
                  style: TextStyle(
                    fontFamily: 'NexaBold',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                ...sortedStudents.map(
                  (student) => ListTile(
                    title: Text(
                      student['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Tutorial Group: ${student['group']}'),
                    trailing: DropdownButton<String>(
                      value: ['Absent', 'Present', 'Leave'].contains(getStudentStatus(student['id']))
                          ? getStudentStatus(student['id'])
                          : 'Absent',
                      items: const [
                        DropdownMenuItem(
                          value: 'Absent', 
                          child: Text(
                            'Absent',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              color: Colors.red,
                            )
                          )
                        ),
                        DropdownMenuItem(value: 'Present', 
                          child: Text(
                            'Present',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              color: Colors.green,
                            )
                          )),
                        DropdownMenuItem(value: 'Leave', 
                          child: Text(
                            'Leave',
                            style: TextStyle(
                              fontFamily: 'NexaBold',
                              color: Colors.orange,
                            )
                          )),
                      ],
                      onChanged: (status) async {
                        if (status != null) {
                          String fixedStatus = status[0].toUpperCase() + status.substring(1).toLowerCase();
                          await setAttendance(student['id'], fixedStatus);
                        }
                      },
                    ),
                  ),
                ),
                if (students.isEmpty)
                  const Text('No students found for this group.'),
              ],
            ),
    );
  }

  String getStudentStatus(String studentId) {
    return attendanceStatusMap[studentId] ?? 'Absent';
  }
}
