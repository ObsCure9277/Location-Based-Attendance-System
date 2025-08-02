import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class TimetableForm extends StatefulWidget {
  final DocumentSnapshot? docToEdit;

  const TimetableForm({super.key, this.docToEdit});

  @override
  _TimetableFormState createState() => _TimetableFormState();
}

class _TimetableFormState extends State<TimetableForm> {
  final _formKey = GlobalKey<FormState>();

  final dayController = TextEditingController();
  final dateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();
  final locationController = TextEditingController();
  final subjectController = TextEditingController();
  final lecturerController = TextEditingController();
  final groupNameController = TextEditingController();
  final typeController = TextEditingController();

  List<Map<String, dynamic>> allLecturers = [];
  List<Map<String, dynamic>> filteredLecturers = [];
  bool isLecturerSearching = false;
  List<Map<String, dynamic>> allGroups = [];
  List<Map<String, dynamic>> filteredGroups = [];
  bool isGroupSearching = false;
  List<Map<String, dynamic>> allLocations = [];
  List<Map<String, dynamic>> filteredLocations = [];
  bool isLocationSearching = false;
  List<String> selectedGroups = [];

  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    if (widget.docToEdit != null) {
      final data = widget.docToEdit!.data() as Map<String, dynamic>;
      dayController.text = data['Day'] ?? '';
      dateController.text = data['Date'] ?? '';
      startTimeController.text = data['StartTime'] ?? '';
      endTimeController.text = data['EndTime'] ?? '';
      locationController.text = data['locationName'] ?? '';
      subjectController.text = data['Subject'] ?? '';
      lecturerController.text = data['Lecturer'] ?? '';
      selectedGroups = List<String>.from(data['GroupNames'] ?? []);
      typeController.text = data['Type'] ?? '';
    }
    fetchAllLocations();
    fetchAllLecturers();
    fetchAllGroups();
  }

  Future<void> pickDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final String formatted =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      // Get the weekday name
      final List<String> weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final String dayName = weekdays[picked.weekday - 1];
      setState(() {
        controller.text = formatted;
        dayController.text = dayName;
      });
    }
  }

  Future<void> pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final int hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final String period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final String formatted =
          '${hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Future<void> fetchAllLocations() async {
    final locationSnapshot =
        await FirebaseFirestore.instance.collection('Location').get();
    setState(() {
      allLocations =
          locationSnapshot.docs
              .map(
                (doc) => {
                  'locationName': doc['locationName'] ?? '',
                  'lat': doc['lat'],
                  'lng': doc['lng'],
                  'radius': doc['radius'],
                },
              )
              .toList();
      filteredLocations = allLocations;
    });
  }

  Future<void> fetchAllLecturers() async {
    final lecturerSnapshot =
        await FirebaseFirestore.instance.collection('Staff').get();
    setState(() {
      allLecturers =
          lecturerSnapshot.docs
              .map((doc) => {'StaffName': doc['name'] ?? ''})
              .toList();
      filteredLecturers = allLecturers;
    });
  }

  Future<void> fetchAllGroups() async {
    final groupSnapshot =
        await FirebaseFirestore.instance.collection('Class').get();
    setState(() {
      allGroups =
          groupSnapshot.docs
              .map((doc) => {'groupName': doc['GroupName'] ?? ''})
              .toList();
      filteredGroups = allGroups;
    });
  }

  void onLocationSearch(String query) {
    setState(() {
      isLocationSearching = query.isNotEmpty;
      filteredLocations =
          allLocations
              .where(
                (loc) =>
                    (loc['locationName'] as String).toLowerCase().contains(
                      query.toLowerCase(),
                    ) &&
                    // If class type is 'T', exclude locations with 'DK'
                    (typeController.text == 'T'
                        ? !(loc['locationName'] as String)
                            .toUpperCase()
                            .contains('DK')
                        : true),
              )
              .toList();
    });
  }

  void selectLocationFromSearch(Map<String, dynamic> loc) {
    setState(() {
      locationController.text = loc['locationName'];
      isLocationSearching = false;
    });
  }

  void onLecturerSearch(String query) {
    setState(() {
      isLecturerSearching = query.isNotEmpty;
      filteredLecturers =
          allLecturers
              .where(
                (lecturer) => lecturer['StaffName'].toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  void selectLecturerFromSearch(Map<String, dynamic> lecturer) {
    setState(() {
      lecturerController.text = lecturer['StaffName'];
      isLecturerSearching = false;
    });
  }

  void onGroupSearch(String query) {
    setState(() {
      isGroupSearching = query.isNotEmpty;
      filteredGroups =
          allGroups
              .where(
                (group) =>
                    group['groupName'].toLowerCase().contains(
                      query.toLowerCase(),
                    ) &&
                    !selectedGroups.contains(group['groupName']),
              )
              .toList();
    });
  }

  void addGroupFromSearch(Map<String, dynamic> group) {
    setState(() {
      if (typeController.text == 'T') {
        // Only allow one group for Tutorial
        selectedGroups = [group['groupName']];
        groupNameController.clear();
        isGroupSearching = false;
      } else {
        // Allow multiple groups for other types
        selectedGroups.add(group['groupName']);
        groupNameController.clear();
        isGroupSearching = false;
      }
    });
  }

  void removeGroup(String groupName) {
    setState(() {
      selectedGroups.remove(groupName);
    });
  }

  void saveTimetableData() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'Day': dayController.text,
        'Date': dateController.text,
        'StartTime': startTimeController.text,
        'EndTime': endTimeController.text,
        'locationName': locationController.text,
        'Subject': subjectController.text,
        'Lecturer': lecturerController.text,
        'GroupNames': selectedGroups,
        'Type': typeController.text,
      };

      if (widget.docToEdit == null) {
        // Add new timetable and set the auto-generated ID as 'id'
        final docRef = await FirebaseFirestore.instance
            .collection('Timetable')
            .add(data);
        await docRef.update({'id': docRef.id});
        // Pass the timetable ID to the attendance creation
        await createTimetableAndAttendance(docRef.id, data, selectedGroups);
      } else {
        // Update existing timetable
        await FirebaseFirestore.instance
            .collection('Timetable')
            .doc(widget.docToEdit!.id)
            .update(data);
      }
      Navigator.pop(context);
    }
  }

  void deleteTimetableData() async {
    if (widget.docToEdit != null) {
      // Delete all attendance records for this timetable
      final attendanceSnapshot =
          await FirebaseFirestore.instance
              .collection('Attendance')
              .where('timetableId', isEqualTo: widget.docToEdit!.id)
              .get();

      for (final doc in attendanceSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the timetable itself
      await FirebaseFirestore.instance
          .collection('Timetable')
          .doc(widget.docToEdit!.id)
          .delete();

      Navigator.pop(context);
    }
  }

  Future<void> createTimetableAndAttendance(
    String timetableId,
    Map<String, dynamic> timetableData,
    List<String> groupNames,
  ) async {
    for (final groupName in groupNames) {
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('Student')
              .where('GroupName', isEqualTo: groupName)
              .get();

      for (final studentDoc in studentsSnapshot.docs) {
        await FirebaseFirestore.instance.collection('Attendance').add({
          'studentId': studentDoc.id,
          'timetableId': timetableId,
          'timestamp': null, // Not marked yet
          'locationName': timetableData['locationName'] ?? '',
          'attendanceStatus': 'Absent',
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docToEdit == null ? 'Add Timetable' : 'Edit Timetable',
          style: TextStyle(fontSize: 20, fontFamily: "NexaBold"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => pickDate(dateController),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: dayController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Day',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: startTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => pickTime(startTimeController),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: endTimeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => pickTime(endTimeController),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value:
                    typeController.text.isNotEmpty ? typeController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Class Type',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('L')),
                  DropdownMenuItem(value: 'T', child: Text('T')),
                ],
                onChanged: (value) {
                  setState(() {
                    typeController.text = value ?? '';
                  });
                },
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(
                        fontFamily: "NexaRegular",
                        fontWeight: FontWeight.bold,
                      ),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: onLocationSearch,
                  ),
                  if (isLocationSearching && filteredLocations.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          final loc = filteredLocations[index];
                          return ListTile(
                            title: Text(loc['locationName']),
                            subtitle: Text('${loc['lat']}, ${loc['lng']}'),
                            onTap: () => selectLocationFromSearch(loc),
                          );
                        },
                      ),
                    ),
                  if (isLocationSearching && filteredLocations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "No location found.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: lecturerController,
                    decoration: const InputDecoration(
                      labelText: 'Lecturer',
                      labelStyle: TextStyle(
                        fontFamily: "NexaRegular",
                        fontWeight: FontWeight.bold,
                      ),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: onLecturerSearch,
                  ),
                  if (isLecturerSearching && filteredLecturers.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredLecturers.length,
                        itemBuilder: (context, index) {
                          final lecturer = filteredLecturers[index];
                          return ListTile(
                            title: Text(lecturer['StaffName']),
                            onTap: () => selectLecturerFromSearch(lecturer),
                          );
                        },
                      ),
                    ),
                  if (isLecturerSearching && filteredLecturers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "No Lecturer found.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: groupNameController,
                    enabled:
                        !(typeController.text == 'T' &&
                            selectedGroups.isNotEmpty),
                    decoration: const InputDecoration(
                      labelText: 'Tutorial Group',
                      labelStyle: TextStyle(
                        fontFamily: "NexaRegular",
                        fontWeight: FontWeight.bold,
                      ),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: onGroupSearch,
                  ),
                  if (isGroupSearching && filteredGroups.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return ListTile(
                            title: Text(group['groupName']),
                            onTap: () => addGroupFromSearch(group),
                          );
                        },
                      ),
                    ),
                  if (isGroupSearching && filteredGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "No Tutorial Group found.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children:
                        selectedGroups
                            .map(
                              (group) => Chip(
                                label: Text(group),
                                onDeleted: () => removeGroup(group),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  String date = dayController.text.trim();
                  String startTime = startTimeController.text.trim();
                  String endTime = endTimeController.text.trim();
                  String classLocation = locationController.text.trim();
                  String subject = subjectController.text.trim();
                  String lecturer = lecturerController.text.trim();
                  String classType = typeController.text.trim();

                  if (date.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Date cannot be empty",
                      ),
                    );
                  } else if (startTime.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Start Time cannot be empty",
                      ),
                    );
                  } else if (endTime.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "End Time cannot be empty",
                      ),
                    );
                  } else if (parseTimeOfDay(endTime)!.hour <
                          parseTimeOfDay(startTime)!.hour ||
                      (parseTimeOfDay(endTime)!.hour ==
                              parseTimeOfDay(startTime)!.hour &&
                          parseTimeOfDay(endTime)!.minute <=
                              parseTimeOfDay(startTime)!.minute)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message:
                            "End Time cannot be earlier than or equal to Start Time",
                      ),
                    );
                  } else if (classLocation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Class Location cannot be empty",
                      ),
                    );
                  } else if (subject.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Subject cannot be empty",
                      ),
                    );
                  } else if (lecturer.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Lecturer cannot be empty",
                      ),
                    );
                  } else if (classType.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Class Type cannot be empty",
                      ),
                    );
                  } else {
                    saveTimetableData();
                    if (widget.docToEdit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Timetable added successfully!",
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Timetable updated successfully!",
                        ),
                      );
                    }
                  }
                },
                child: buttonInText(
                  widget.docToEdit == null ? "ADD" : "UPDATE",
                  screenHeight,
                  screenWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassForm extends StatefulWidget {
  final DocumentSnapshot? docToEdit;

  const ClassForm({super.key, this.docToEdit});

  @override
  State<ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<ClassForm> {
  final _formKey = GlobalKey<FormState>();
  final groupNameController = TextEditingController();
  final studentController = TextEditingController();
  List<String> students = [];
  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];
  Set<String> assignedStudentEmails = {}; // Track assigned students
  bool isSearching = false;

  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    if (widget.docToEdit != null) {
      final data = widget.docToEdit!.data() as Map<String, dynamic>;
      groupNameController.text = data['GroupName'] ?? '';
      students = List<String>.from(data['Students'] ?? []);
    }
    fetchAllStudentsAndGroups();
  }

  Future<void> fetchAllStudentsAndGroups() async {
    // Fetch all students
    final studentSnapshot =
        await FirebaseFirestore.instance.collection('Student').get();
    // Fetch all groups
    final groupSnapshot =
        await FirebaseFirestore.instance.collection('Class').get();

    // Build set of assigned student emails
    Set<String> assigned = {};
    for (var doc in groupSnapshot.docs) {
      final groupStudents = List<String>.from(doc['Students'] ?? []);
      for (var s in groupStudents) {
        // Extract email from "Name (email)" format
        final match = RegExp(r'\(([^)]+)\)$').firstMatch(s);
        if (match != null) {
          assigned.add(match.group(1)!);
        }
      }
    }

    setState(() {
      allStudents =
          studentSnapshot.docs
              .map(
                (doc) => {
                  'name': doc['name'] ?? '',
                  'email': doc['email'] ?? '',
                },
              )
              .toList();
      assignedStudentEmails = assigned;
      filteredStudents =
          allStudents
              .where(
                (student) => !assignedStudentEmails.contains(student['email']),
              )
              .toList();
    });
  }

  void onStudentSearch(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      filteredStudents =
          allStudents
              .where(
                (student) =>
                    !assignedStudentEmails.contains(student['email']) &&
                    (student['name'].toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        student['email'].toLowerCase().contains(
                          query.toLowerCase(),
                        )),
              )
              .toList();
    });
  }

  void addStudentFromSearch(Map<String, dynamic> student) {
    String studentDisplay = "${student['name']} (${student['email']})";
    if (!students.contains(studentDisplay)) {
      setState(() {
        students.add(studentDisplay);
        studentController.clear();
        isSearching = false;
        // Add to assigned so it disappears from search immediately
        assignedStudentEmails.add(student['email']);
      });
    }
  }

  void saveClassData() async {
    if (_formKey.currentState!.validate()) {
      final groupName = groupNameController.text.trim();

      // Check for duplicate group name
      final query =
          await FirebaseFirestore.instance
              .collection('Class')
              .where('GroupName', isEqualTo: groupName)
              .get();
      final isDuplicate =
          widget.docToEdit == null
              ? query.docs.isNotEmpty
              : query.docs.any((doc) => doc.id != widget.docToEdit!.id);

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar().errorSnackBar(
            message: "A group with this name already exists.",
          ),
        );
        return;
      }
      final data = {
        'GroupName': groupNameController.text,
        'Students': students, // students is a List<String> of "Name (email)"
      };

      // Save or update the group document
      DocumentReference groupRef;
      if (widget.docToEdit == null) {
        groupRef = await FirebaseFirestore.instance
            .collection('Class')
            .add(data);
      } else {
        groupRef = FirebaseFirestore.instance
            .collection('Class')
            .doc(widget.docToEdit!.id);
        await groupRef.update(data);
      }
      for (String student in students) {
        // Extract email from "Name (email)"
        final match = RegExp(r'\(([^)]+)\)$').firstMatch(student);
        if (match != null) {
          final email = match.group(1)!;
          // Find the student document by email
          final query =
              await FirebaseFirestore.instance
                  .collection('Student')
                  .where('email', isEqualTo: email)
                  .get();
          if (query.docs.isNotEmpty) {
            final studentDoc = query.docs.first;
            // Update GroupName field
            await studentDoc.reference.update({
              'GroupName': groupNameController.text,
            });
          }
        }
      }
      Navigator.pop(context);
    }
  }

  Future<void> updateClassData(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final groupName = data['GroupName'] ?? '';
    final students = List<String>.from(data['Students'] ?? []);

    for (String student in students) {
      final match = RegExp(r'\(([^)]+)\)$').firstMatch(student);
      if (match != null) {
        final email = match.group(1)!;
        final query =
            await FirebaseFirestore.instance
                .collection('Student')
                .where('email', isEqualTo: email)
                .get();
        if (query.docs.isNotEmpty) {
          final studentDoc = query.docs.first;
          if ((studentDoc['GroupName'] ?? '') == groupName) {
            await studentDoc.reference.update({'GroupName': ''});
          }
        }
      }
    }
    await FirebaseFirestore.instance.collection('Class').doc(doc.id).delete();
  }

  void addStudent() {
    String student = studentController.text.trim();
    if (student.isNotEmpty && !students.contains(student)) {
      setState(() {
        students.add(student);
        studentController.clear();
      });
    }
  }

  void removeStudent(String student) {
    setState(() {
      students.remove(student);
      updateClassData(widget.docToEdit!);
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docToEdit == null ? 'Add Tutorial Group' : 'Edit Tutorial Group',
          style: TextStyle(fontSize: 20, fontFamily: "NexaBold"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: studentController,
                    decoration: const InputDecoration(
                      labelText: 'Search Student (name or email)',
                      labelStyle: TextStyle(
                        fontFamily: "NexaRegular",
                        fontWeight: FontWeight.bold,
                      ),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: onStudentSearch,
                  ),
                  if (isSearching && filteredStudents.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final display =
                              "${student['name']} (${student['email']})";
                          return ListTile(
                            title: Text(display),
                            onTap: () => addStudentFromSearch(student),
                          );
                        },
                      ),
                    ),
                  if (isSearching && filteredStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "No available students found.",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    students
                        .map(
                          (student) => Chip(
                            label: Text(student),
                            onDeleted: () {
                              removeStudent(student);
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  String groupName = groupNameController.text.trim();

                  if (groupName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Group Name cannot be empty",
                      ),
                    );
                  } else if (students.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message:
                            "Please select at least one student for this group.",
                      ),
                    );
                  } else {
                    saveClassData();
                    if (widget.docToEdit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Tutorial Group added successfully!",
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Tutorial Group updated successfully!",
                        ),
                      );
                    }
                  }
                },
                child: buttonInText(
                  widget.docToEdit == null ? "ADD" : "UPDATE",
                  screenHeight,
                  screenWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationForm extends StatefulWidget {
  final DocumentSnapshot? docToEdit;

  const LocationForm({super.key, this.docToEdit});

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  final locationNameController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final radiusController = TextEditingController();

  List<Map<String, dynamic>> locations = [];

  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    if (widget.docToEdit != null) {
      final data = widget.docToEdit!.data() as Map<String, dynamic>;
      locationNameController.text = data['locationName'] ?? '';
      latController.text = data['lat']?.toString() ?? '';
      lngController.text = data['lng']?.toString() ?? '';
      radiusController.text = data['radius']?.toString() ?? '';
    }
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Location').get();
    setState(() {
      locations =
          snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'locationName': doc['locationName'] ?? '',
                  'lat': doc['lat'],
                  'lng': doc['lng'],
                  'radius': doc['radius'],
                },
              )
              .toList();
    });
  }

  void saveLocationData() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'locationName': locationNameController.text.trim(),
        'lat': double.tryParse(latController.text.trim()) ?? 0.0,
        'lng': double.tryParse(lngController.text.trim()) ?? 0.0,
        'radius': double.tryParse(radiusController.text.trim()) ?? 50.0,
      };

      if (widget.docToEdit == null) {
        await FirebaseFirestore.instance.collection('Location').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('Location')
            .doc(widget.docToEdit!.id)
            .update(data);
      }
      Navigator.pop(context);
    }
  }

  void deleteLocation(String id) async {
    await FirebaseFirestore.instance.collection('Location').doc(id).delete();
    fetchLocations();
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar().successSnackBar(
        message: "Location deleted successfully!",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docToEdit == null ? 'Add Location' : 'Edit Location',
          style: TextStyle(fontSize: 20, fontFamily: "NexaBold"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (locationNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Location Name cannot be empty",
                      ),
                    );
                  } else if (latController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Latitude cannot be empty",
                      ),
                    );
                  } else if (lngController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Longitude cannot be empty",
                      ),
                    );
                  } else if (radiusController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Radius cannot be empty",
                      ),
                    );
                  } else if (double.tryParse(latController.text) == null ||
                      double.tryParse(lngController.text) == null ||
                      double.tryParse(radiusController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Invalid number format",
                      ),
                    );
                  } else {
                    saveLocationData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().successSnackBar(
                        message:
                            widget.docToEdit == null
                                ? "Location added successfully!"
                                : "Location updated successfully!",
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.docToEdit == null ? "ADD" : "UPDATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth / 22,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaveRequestForm extends StatefulWidget {
  final DocumentSnapshot? docToEdit;

  const LeaveRequestForm({super.key, this.docToEdit});

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final reasonController = TextEditingController();
  final studentNameController = TextEditingController();
  final requestDateController = TextEditingController();

  List<PlatformFile> supportingDocuments = [];
  List<String> supportingDocumentUrls = [];
  String? existingStatus;
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    if (widget.docToEdit != null) {
      final data = widget.docToEdit!.data() as Map<String, dynamic>;
      startDateController.text = data['StartDate'] ?? '';
      endDateController.text = data['EndDate'] ?? '';
      reasonController.text = data['Reason'] ?? '';
      studentNameController.text = data['StudentName'] ?? '';
      existingStatus = data['Status'] ?? 'Pending';
      requestDateController.text = data['RequestDate'] ?? '';
      supportingDocumentUrls = List<String>.from(
        data['SupportingDocument'] ?? [],
      );
    } else {
      autofillStudentName();
      final now = DateTime.now();
      requestDateController.text =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    }
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    reasonController.dispose();
    studentNameController.dispose();
    requestDateController.dispose();
    super.dispose();
  }

  Future<void> autofillStudentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Student')
              .doc(user.uid)
              .get();
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          studentNameController.text = data?['name'] ?? '';
        });
      }
    }
  }

  Future<void> pickDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime minDate = now.add(const Duration(days: 7));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final String formatted =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        controller.text = formatted;
      });
    }
  }

  void saveLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'RequestDate': requestDateController.text,
        'StartDate': startDateController.text,
        'EndDate': endDateController.text,
        'Reason': reasonController.text,
        'StudentName': studentNameController.text,
        'Status':
            widget.docToEdit == null
                ? 'Pending'
                : (existingStatus ?? 'Pending'),
        'SupportingDocument': supportingDocumentUrls,
      };

      if (widget.docToEdit == null) {
        await FirebaseFirestore.instance.collection('LeaveRequests').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('LeaveRequests')
            .doc(widget.docToEdit!.id)
            .update(data);
      }
      Navigator.pop(context);
    }
  }

  Future<String?> uploadFileToCloudinary(File file) async {
    try {
      final uploadParams = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split("/").last,
        ),
        'upload_preset': 'ml_default', // Replace with your unsigned preset
      });

      final response = await Dio().post(
        'https://api.cloudinary.com/v1_1/dbvtq5i7g/upload', // Replace with your cloud name
        data: uploadParams,
        options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
      );

      if (response.statusCode == 200) {
        final fileUrl = response.data['secure_url'];
        print('File uploaded successfully: $fileUrl');
        return fileUrl;
      } else {
        print('Error uploading file: ${response.data['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.docToEdit == null ? 'Add Leave Request' : 'Edit Leave Request',
          style: TextStyle(fontSize: 20, fontFamily: "NexaBold"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: studentNameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: requestDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Request Date',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: startDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => pickDate(startDateController),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: endDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => pickDate(endDateController),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason of Leave',
                  labelStyle: TextStyle(
                    fontFamily: "NexaRegular",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                maxLines: 4,
                maxLength: 200,
              ),
              const SizedBox(height: 10),
              // --- Multiple File Upload Section ---
              Row(
                children: [
                  Expanded(
                    child:
                        supportingDocuments.isNotEmpty
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  supportingDocuments
                                      .map(
                                        (file) => Text(
                                          file.name,
                                          style: const TextStyle(
                                            fontFamily: "NexaRegular",
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                      .toList(),
                            )
                            : const Text(
                              'No document selected',
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    label: const Text('Upload'),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            allowMultiple: true,
                          );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() {
                          // Merge new files with existing, avoiding duplicates by path
                          final existingPaths =
                              supportingDocuments.map((f) => f.path).toSet();
                          final newFiles = result.files.where(
                            (f) => !existingPaths.contains(f.path),
                          );
                          // Limit total files to 3
                          final totalFiles =
                              supportingDocuments.length + newFiles.length;
                          if (totalFiles > 3) {
                            final allowedToAdd = 3 - supportingDocuments.length;
                            supportingDocuments.addAll(
                              newFiles.take(allowedToAdd),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              CustomSnackBar().errorSnackBar(
                                message: "You can only upload maximum 3 files.",
                              ),
                            );
                          } else {
                            supportingDocuments.addAll(newFiles);
                          }
                          supportingDocumentUrls = [];
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Note: Only JPG, JPEG, PNG, PDF allowed.',
                style: TextStyle(
                  fontFamily: "NexaRegular",
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth / 30,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final startParts = startDateController.text.split('-');
                  final endParts = endDateController.text.split('-');
                  final start = DateTime(
                    int.parse(startParts[2]),
                    int.parse(startParts[1]),
                    int.parse(startParts[0]),
                  );
                  final end = DateTime(
                    int.parse(endParts[2]),
                    int.parse(endParts[1]),
                    int.parse(endParts[0]),
                  );

                  if (studentNameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Student Name cannot be empty",
                      ),
                    );
                  } else if (startDateController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Start Date cannot be empty",
                      ),
                    );
                  } else if (endDateController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "End Date cannot be empty",
                      ),
                    );
                  } else if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "Reason of Leave cannot be empty",
                      ),
                    );
                  } else if (supportingDocuments.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "At least one supporting document is required",
                      ),
                    );
                  } else if (end.isBefore(start)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      CustomSnackBar().errorSnackBar(
                        message: "End Date cannot be earlier than Start Date",
                      ),
                    );
                  } else {
                    List<String> fileUrls = [];
                    for (final file in supportingDocuments) {
                      final url = await uploadFileToCloudinary(
                        File(file.path!),
                      );
                      if (url != null) {
                        fileUrls.add(url);
                      }
                    }
                    if (fileUrls.length != supportingDocuments.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().errorSnackBar(
                          message: "Failed to upload all supporting documents.",
                        ),
                      );
                      return;
                    }
                    supportingDocumentUrls = fileUrls;

                    saveLeaveRequest();

                    if (widget.docToEdit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Leave Request added successfully!",
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().successSnackBar(
                          message: "Leave Request updated successfully!",
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.docToEdit == null ? "ADD" : "UPDATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth / 22,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TimeOfDay? parseTimeOfDay(String timeStr) {
  try {
    final parts = timeStr.split(' ');
    final hm = parts[0].split(':');
    int hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);
    final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  } catch (_) {
    return null;
  }
}
