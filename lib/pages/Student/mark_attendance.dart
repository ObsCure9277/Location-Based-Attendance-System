import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:location_based_attendance_app/widgets/dropdownlist.dart';

class Attendancepage extends StatefulWidget {
  const Attendancepage({super.key});

  @override
  State<Attendancepage> createState() => _AttendancepageState();
}

class _AttendancepageState extends State<Attendancepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  double? latitude;
  double? longitude;
  bool locationPermissionGranted = false;
  bool isCheckingLocation = false;
  String locationStatus = "Checking...";
  StreamSubscription<Position>? positionStream;
  StreamSubscription<ServiceStatus>? serviceStatusStream;

  Map<String, dynamic>? currentClass;
  Map<String, dynamic>? classLocation;
  bool canMarkAttendance = false;

  Timer? geofenceTimer;
  bool isInsideGeofence = false;
  int secondsInside = 0;
  List<Map<String, dynamic>> currentClasses = [];
  int selectedClassIndex = 0;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  void initState() {
    super.initState();
    startLocationListeners();
    startGeofenceMonitoring();
    fetchCurrentClass();
  }

  void startLocationListeners() {
    // Only listen for service status on mobile platforms
    if (!kIsWeb) {
      serviceStatusStream = Geolocator.getServiceStatusStream().listen((
        status,
      ) {
        checkLocationStatus();
      });
    }

    // Listen for location changes (works on all platforms)
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        locationPermissionGranted = true;
        locationStatus = "Operational";
      });
    });

    // Initial check
    checkLocationStatus();
  }

  void startGeofenceMonitoring() {
    geofenceTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (latitude != null && longitude != null && classLocation != null) {
        final lat = (classLocation!['lat'] as num).toDouble();
        final lng = (classLocation!['lng'] as num).toDouble();
        final radius = (classLocation!['radius'] as num).toDouble();
        final distance = calculateDistance(latitude!, longitude!, lat, lng);

        if (distance <= radius) {
          if (!isInsideGeofence) {
            isInsideGeofence = true;
            print('Entered geofence');
          }
          setState(() {
            secondsInside += 2;
          });
        } else {
          if (isInsideGeofence) {
            isInsideGeofence = false;
            print('Exited geofence');
          }
        }
        checkCanMarkAttendance();
      }
    });
  }

  Future<void> checkLocationStatus() async {
    setState(() {
      isCheckingLocation = true;
      locationStatus = "Checking...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationPermissionGranted = false;
        locationStatus = "Location services disabled";
        isCheckingLocation = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          locationPermissionGranted = true;
          locationStatus = "Operational";
          isCheckingLocation = false;
        });
      } catch (e) {
        setState(() {
          locationPermissionGranted = false;
          locationStatus = "Location unavailable";
          isCheckingLocation = false;
        });
      }
    } else {
      setState(() {
        locationPermissionGranted = false;
        locationStatus = "Permission denied";
        isCheckingLocation = false;
      });
    }
  }

  // 1. Get current class for student
  Future<void> fetchCurrentClass() async {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);

    // Get student group
    final studentDoc =
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();
    final studentGroup = studentDoc['GroupName'] ?? '';

    // Get all today's classes for this group
    final timetableSnapshot =
        await FirebaseFirestore.instance
            .collection('Timetable')
            .where('Date', isEqualTo: formattedDate)
            .get();

    List<Map<String, dynamic>> foundClasses = [];
    for (var doc in timetableSnapshot.docs) {
      final data = doc.data();
      final groups = List<String>.from(data['GroupNames'] ?? []);
      if (!groups.contains(studentGroup)) continue;
      foundClasses.add({...data, 'id': doc.id});
    }

    setState(() {
      currentClasses = foundClasses;
      selectedClassIndex = 0;
      currentClass = foundClasses.isNotEmpty ? foundClasses[0] : null;
    });

    if (currentClass != null) {
      await fetchClassLocation(currentClass!['locationName']);
    } else {
      setState(() {
        classLocation = null;
      });
    }
  }

  // Helper to parse time string like "8:00 AM"
  DateTime parseTime(String date, String timeStr) {
    final dateTimeStr = "$date $timeStr";
    return DateFormat('dd-MM-yyyy h:mm a').parse(dateTimeStr);
  }

  // 2. Get geofence for class
  Future<void> fetchClassLocation(String locationName) async {
    final locationSnapshot =
        await FirebaseFirestore.instance
            .collection('Location')
            .where('locationName', isEqualTo: locationName)
            .get();
    if (locationSnapshot.docs.isNotEmpty) {
      setState(() {
        classLocation = locationSnapshot.docs.first.data();
      });
    }
  }

  // 3. Check if can mark attendance
  void checkCanMarkAttendance() {
    if (currentClass == null ||
        classLocation == null ||
        latitude == null ||
        longitude == null) {
      setState(() {
        canMarkAttendance = false;
      });
      return;
    }
    // Ensure correct types for geofence calculation
    final lat = (classLocation!['lat'] as num).toDouble();
    final lng = (classLocation!['lng'] as num).toDouble();
    final radius = (classLocation!['radius'] as num).toDouble();
    final distance = calculateDistance(latitude!, longitude!, lat, lng);
    final insideGeofence = distance <= radius;

    // Check time
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(now);
    final startTime = parseTime(formattedDate, currentClass!['StartTime']);
    final endTime = parseTime(formattedDate, currentClass!['EndTime']);
    final withinTime = now.isAfter(startTime) && now.isBefore(endTime);

    // Debug info
    print('Now: $now, Start: $startTime, End: $endTime, Within: $withinTime');
    print(
      'Current: $latitude, $longitude | Geofence: $lat, $lng, radius: $radius | Distance: $distance | Inside: $insideGeofence',
    );

    setState(() {
      canMarkAttendance = insideGeofence && withinTime;
    });
  }

  // 4. Mark attendance
  Future<void> markAttendance() async {
    if (currentClass == null) return;

    // Check if attendance already exists for this student and timetable
    final attendanceQuery =
        await FirebaseFirestore.instance
            .collection('Attendance')
            .where(
              'studentId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .where('timetableId', isEqualTo: currentClass!['id'])
            .get();

    if (attendanceQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(
          message: 'Attendance already marked for this class.',
        ),
      );
      return;
    }

    // If not, allow marking attendance
    await FirebaseFirestore.instance.collection('Attendance').add({
      'studentId': FirebaseAuth.instance.currentUser!.uid,
      'timetableId': currentClass!['id'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'locationName': currentClass!['locationName'] ?? '',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar().successSnackBar(
        message: 'Attendance is marked successfully.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    final current = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(current);
    // Filter out classes that have already ended
    final availableClasses =
        currentClasses.where((cls) {
          final endTime = DateFormat(
            'dd-MM-yyyy h:mm a',
          ).parse('$formattedDate ${cls['EndTime']}');
          return current.isBefore(endTime);
        }).toList();

    // Ensure selectedClassIndex is valid
    if (selectedClassIndex >= availableClasses.length) {
      selectedClassIndex = 0;
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('Student')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.only(top: 12),
                    child: Text(
                      'Welcome',
                      style: TextStyle(
                        color: Colors.black87,
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 22,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const CircularProgressIndicator(),
                  ),
                ],
              );
            }
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final studentName = data['name'] ?? 'Student';
            final studentGroupName = data['GroupName'] ?? '';

            return Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.only(top: 15),
                  child: Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: "NexaRegular",
                      fontSize: screenWidth / 22,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    studentName,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: "NexaBold",
                      fontSize: screenWidth / 18,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight / 50),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          'Today\'s Classes',
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                          ),
                        ),
                      
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 32),
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Classes',
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                fontSize: screenWidth / 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('Timetable')
                                      .where(
                                        'Date',
                                        isEqualTo: DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(DateTime.now()),
                                      )
                                      .snapshots(),
                              builder: (context, timetableSnapshot) {
                                if (!timetableSnapshot.hasData ||
                                    studentGroupName.isEmpty) {
                                  return Text(
                                    '0',
                                    style: TextStyle(
                                      fontFamily: "NexaBold",
                                      fontSize: screenWidth / 18,
                                    ),
                                  );
                                }
                                final docs = timetableSnapshot.data!.docs;
                                final filteredDocs =
                                    docs.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final timetableGroups =
                                          data['GroupNames'] != null
                                              ? List<String>.from(
                                                data['GroupNames'],
                                              )
                                              : [];
                                      return timetableGroups.contains(
                                        studentGroupName,
                                      );
                                    }).toList();

                                return Text(
                                  '${filteredDocs.length}',
                                  style: TextStyle(
                                    fontFamily: "NexaBold",
                                    fontSize: screenWidth / 18,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(color: Colors.black26, thickness: 1),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Classes Attended',
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                fontSize: screenWidth / 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('Timetable')
                                      .where(
                                        'Date',
                                        isEqualTo: DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(DateTime.now()),
                                      )
                                      .snapshots(),
                              builder: (context, timetableSnapshot) {
                                if (!timetableSnapshot.hasData ||
                                    studentGroupName.isEmpty) {
                                  return Text(
                                    '0',
                                    style: TextStyle(
                                      fontFamily: "NexaBold",
                                      fontSize: screenWidth / 18,
                                    ),
                                  );
                                }
                                final timetableDocs =
                                    timetableSnapshot.data!.docs;
                                // Filter timetables for this student's group
                                final groupTimetables =
                                    timetableDocs.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final timetableGroups =
                                          data['GroupNames'] != null
                                              ? List<String>.from(
                                                data['GroupNames'],
                                              )
                                              : [];
                                      return timetableGroups.contains(
                                        studentGroupName,
                                      );
                                    }).toList();
                                final timetableIds =
                                    groupTimetables
                                        .map((doc) => doc.id)
                                        .toList();

                                // Now, count attendance for these timetable IDs
                                return StreamBuilder<QuerySnapshot>(
                                  stream:
                                      FirebaseFirestore.instance
                                          .collection('Attendance')
                                          .where(
                                            'studentId',
                                            isEqualTo:
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser!
                                                    .uid,
                                          )
                                          .where(
                                            'timetableId',
                                            whereIn:
                                                timetableIds.isEmpty
                                                    ? ['dummy']
                                                    : timetableIds,
                                          )
                                          .snapshots(),
                                  builder: (context, attendanceSnapshot) {
                                    if (!attendanceSnapshot.hasData) {
                                      return Text(
                                        '0',
                                        style: TextStyle(
                                          fontFamily: "NexaBold",
                                          fontSize: screenWidth / 18,
                                        ),
                                      );
                                    }
                                    final attendedCount =
                                        attendanceSnapshot.data!.docs.length;
                                    return Text(
                                      '$attendedCount',
                                      style: TextStyle(
                                        fontFamily: "NexaBold",
                                        fontSize: screenWidth / 18,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        DateTime.now().day.toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth / 18,
                          fontFamily: "NexaBold",
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontFamily: "NexaRegular",
                          fontSize: screenWidth / 20,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lat: ${latitude?.toStringAsFixed(4) ?? "Unknown"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        Text(
                          DateFormat('hh:mm:ss a').format(DateTime.now()),
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Lng: ${longitude?.toStringAsFixed(4) ?? "Unknown"}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                    border: Border.all(
                      color:
                          locationPermissionGranted ? Colors.green : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        locationPermissionGranted
                            ? Icons.location_on
                            : Icons.location_off,
                        color:
                            locationPermissionGranted
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Location status: ${locationPermissionGranted ? "Operational" : locationStatus}",
                          style: TextStyle(
                            color:
                                locationPermissionGranted
                                    ? Colors.green
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!locationPermissionGranted)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: Colors.red,
                          tooltip: "Retry",
                          onPressed: checkLocationStatus,
                        ),
                    ],
                  ),
                ),
                customDropdown(
                  'Select Class',
                  availableClasses.isNotEmpty
                      ? '${availableClasses[selectedClassIndex]['locationName']} (${availableClasses[selectedClassIndex]['StartTime']})'
                      : '',
                  availableClasses
                      .map(
                        (cls) => '${cls['locationName']} (${cls['StartTime']})',
                      )
                      .toList(),
                  screenHeight,
                  screenWidth,
                  Icons.class_,
                  (String? newValue) {
                    final index = availableClasses.indexWhere(
                      (cls) =>
                          '${cls['locationName']} (${cls['StartTime']})' ==
                          newValue,
                    );
                    if (index != -1) {
                      setState(() {
                        selectedClassIndex = index;
                        currentClass = availableClasses[index];
                      });
                      fetchClassLocation(
                        availableClasses[index]['locationName'],
                      );
                      checkCanMarkAttendance();
                    }
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  isInsideGeofence
                      ? 'Inside ${currentClass != null ? currentClass!['locationName'] ?? "geofence" : "geofence"}'
                      : 'Outside Any Location',
                  style: TextStyle(
                    fontSize: 18,
                    color: isInsideGeofence ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: canMarkAttendance ? markAttendance : null,
                  child: successButtonInText(
                    'I am here !',
                    screenHeight,
                    screenWidth,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
