import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  late LocationData locData;

  Future<void> initialze() async {
    bool serviceEnabled;
    PermissionStatus permission;

    // Check if the location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      // Request to enable the service
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return; // Service not enabled, exit
      }
    }

    // Check for location permission
    permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      // Request permission
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return; // Permission not granted, exit
      }
    }
  }

  Future<double?> getLatitude() async {
    locData = await location.getLocation();
    return locData.latitude;
  }

  Future<double?> getLongitude() async {
    locData = await location.getLocation();
    return locData.longitude;
  }
}