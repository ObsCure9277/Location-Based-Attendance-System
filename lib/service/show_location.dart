import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

class ShowLocationPage extends StatefulWidget {
  const ShowLocationPage({super.key});

  @override
  State<ShowLocationPage> createState() => _ShowLocationPageState();
}

class _ShowLocationPageState extends State<ShowLocationPage> {
  double? latitude;
  double? longitude;
  bool isLoading = false;
  bool permissionGranted = false;

  // Geofence parameters
  static const double geofenceLat = 3.250845; // Set your geofence latitude
  static const double geofenceLng = 101.701308; // Set your geofence longitude
  static const double geofenceRadius = 100; // meters

  Timer? _timer;
  bool _isInsideGeofence = false;
  int _secondsInside = 0;

  @override
  void initState() {
    super.initState();
    fetchLocation();
    startGeofenceMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> fetchLocation() async {
    setState(() {
      isLoading = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        permissionGranted = true;
        isLoading = false;
      });
    } else {
      setState(() {
        latitude = null;
        longitude = null;
        permissionGranted = false;
        isLoading = false;
      });
    }
  }

  void startGeofenceMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position;
        try {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
        } catch (e) {
          return;
        }
        final distance = calculateDistance(
          position.latitude,
          position.longitude,
          geofenceLat,
          geofenceLng,
        );

        print('Distance to geofence: $distance meters');

        if (distance <= geofenceRadius) {
          if (!_isInsideGeofence) {
            _isInsideGeofence = true;
            print('Entered geofence');
          }
          setState(() {
            _secondsInside += 2;
            latitude = position.latitude;
            longitude = position.longitude;
          });
        } else {
          if (_isInsideGeofence) {
            _isInsideGeofence = false;
            print('Exited geofence');
          }
          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Location')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Latitude: ${latitude?.toStringAsFixed(6) ?? "Unknown"}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Longitude: ${longitude?.toStringAsFixed(6) ?? "Unknown"}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isInsideGeofence
                        ? 'Inside geofence ($_secondsInside seconds)'
                        : 'Outside geofence',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isInsideGeofence ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchLocation,
                    child: const Text('Refresh Location'),
                  ),
                  if (!permissionGranted)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        'Location permission not granted or location unavailable.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}