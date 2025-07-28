import 'dart:convert';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize notifications for background service
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize the background service
Future<void> initBackgroundService() async {
  // Initialize notifications
  await initNotifications();
}

// Initialize notifications
Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
      
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<bool> areNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('notificationsEnabled') ?? true;
}

// Save current geofence data for background service
Future<void> saveGeofenceData(Map<String, dynamic> classData, Map<String, dynamic> locationData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Combine class and location data
    final geofenceData = {
      'id': classData['id'],
      'locationName': classData['locationName'],
      'subject': classData['Subject'] ?? '',
      'lat': locationData['lat'],
      'lng': locationData['lng'],
      'radius': locationData['radius'],
    };
    
    await prefs.setString('currentGeofence', jsonEncode(geofenceData));
    print('Geofence data saved: ${jsonEncode(geofenceData)}');
  } catch (e) {
    print('Error saving geofence data: $e');
  }
}

// Check if user is inside saved geofence
Future<bool> checkSavedGeofence() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final geofenceJson = prefs.getString('currentGeofence');
    
    if (geofenceJson == null) return false;
    
    final geofence = jsonDecode(geofenceJson) as Map<String, dynamic>;
    final position = await Geolocator.getCurrentPosition();
    
    final lat = (geofence['lat'] as num).toDouble();
    final lng = (geofence['lng'] as num).toDouble();
    final radius = (geofence['radius'] as num).toDouble();
    
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
    
    return distance <= radius;
  } catch (e) {
    print('Error checking saved geofence: $e');
    return false;
  }
}

// Show notification
Future<void> showBackgroundNotification(String title, String body) async {
  // Check notification settings first
  bool notificationsEnabled = await areNotificationsEnabled();
  if (!notificationsEnabled) {
    return; // Skip notification if disabled
  }
  
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'geofence_channel',
    'Geofence Notifications',
    channelDescription: 'Notifications for class location arrival',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );
  
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
}