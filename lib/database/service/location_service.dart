import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter/foundation.dart';

class LocationService {
  // Check and request location permissions
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled. Please enable the services
      // Or handle it by showing a message to the user
      debugPrint('Location services are disabled.');
      return false;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        debugPrint('Location permissions are denied.');
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }

  // Get current position
  Future<geo.Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      return null;
    }
    try {
      return await geo.Geolocator.getCurrentPosition(
          locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high));
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Configure and start geofencing
  void configureGeofencing() {
    bg.BackgroundGeolocation.ready(bg.Config(
      locationAuthorizationRequest: 'Always',
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH, // Use this for accuracy
      // Android specific settings can be configured using the android: {} block if needed
      // Apple specific settings (if needed, otherwise defaults are used)
      // appleSettings: bg.AppleSettings(
      //   accuracy: bg.Config.DESIRED_ACCURACY_HIGH, // For iOS
      //   distanceFilter: 10.0
      // ),
      distanceFilter: 10.0, // Trigger event for every 10m change
      stopOnTerminate: false, // Continue tracking when app is terminated
      startOnBoot: true, // Start tracking when device boots (requires special permissions)
      debug: true, // Set to false for production
      logLevel: bg.Config.LOG_LEVEL_VERBOSE, // Adjust for production
      geofenceProximityRadius: 1000, // Geofences within 1km will be considered active for triggering events
      // Add other configurations as needed by your app
      // For example, notification settings for geofence events:
      // notification: bg.Notification(
      //   title: "Geofence Event",
      //   text: "You have {event} {identifier}"
      // )
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.startGeofences();
        debugPrint('BackgroundGeolocation geofences started.');
      } else {
        debugPrint('BackgroundGeolocation geofences already started.');
      }
    }).catchError((error) {
      debugPrint('Error configuring BackgroundGeolocation: $error');
    });

    // Listen to geofence events
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      debugPrint('[geofence] ${event.action}:${event.identifier}');
      // Handle geofence events (ENTER, EXIT, DWELL)
      if (event.action == 'ENTER') {
        debugPrint('User entered geofence: ${event.identifier}');
        // Implemented attendance marking logic placeholder
        debugPrint('Placeholder: Attendance marked for geofence ${event.identifier}');
        debugPrint('Attendance marking logic to be implemented for geofence enter.');
      } else if (event.action == 'EXIT') {
        debugPrint('User exited geofence: ${event.identifier}');
        // Implemented logic for user exit placeholder
        debugPrint('Placeholder: User exited geofence ${event.identifier}. Logic to be implemented.');
        debugPrint('Logic for geofence exit to be implemented.');
      }
    });
  }

  // Add a geofence
  Future<void> addGeofence(String identifier, double latitude, double longitude, double radius) async {
    // First, ensure permissions are handled and geofencing is configured
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
        debugPrint('Cannot add geofence due to missing permissions.');
        return;
    }
    // It's good practice to ensure the service is ready before adding geofences.
    // However, `addGeofence` can be called even if `ready` hasn't completed yet.
    // The plugin will queue the request.

    try {
      await bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: identifier,
        radius: radius, // in meters
        latitude: latitude,
        longitude: longitude,
        notifyOnEntry: true,
        notifyOnExit: true,
        notifyOnDwell: false, // Set to true if DWELL events are needed
        // loiteringDelay: 30000, // 30 seconds. Only if notifyOnDwell is true
        // extras: { // Optional custom data for this geofence
        //   'description': 'Office Location'
        // }
      ));
      debugPrint('Geofence added: $identifier at $latitude, $longitude with radius $radius');
    } catch (e) {
      debugPrint('Error adding geofence $identifier: $e');
    }
  }

  // Remove a geofence
  Future<void> removeGeofence(String identifier) async {
    try {
      await bg.BackgroundGeolocation.removeGeofence(identifier);
      debugPrint('Geofence removed: $identifier');
    } catch (e) {
      debugPrint('Error removing geofence $identifier: $e');
    }
  }

  // Get all geofences
  Future<List<bg.Geofence>> getGeofences() async {
    try {
      List<bg.Geofence> geofences = await bg.BackgroundGeolocation.geofences;
      debugPrint('Retrieved ${geofences.length} geofences.');
      return geofences;
    } catch (e) {
      debugPrint('Error getting geofences: $e');
      return [];
    }
  }

  // Stop geofencing service (optional, if you need to manually stop it)
  void stopGeofencingService() {
     bg.BackgroundGeolocation.stop();
     debugPrint('BackgroundGeolocation service stopped.');
  }
}