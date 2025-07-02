import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settingspage extends StatefulWidget {
  const Settingspage({super.key});

  @override
  State<Settingspage> createState() => _SettingspageState();
}

class _SettingspageState extends State<Settingspage> {
  double screenWidth = 0;
  double screenHeight = 0;
  bool notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
  }
  
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: screenWidth * 0.05, 
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: screenHeight * 0.02,
          ),
          SwitchListTile(
            title: const Text(
              'Geofence Notifications',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'NexaBold',
                color: Colors.black,
              ),),
            subtitle: const Text(
              'Receive notifications when you enter class locations',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'NexaRegular',
                color: Colors.black54,
              ),
            ),
            value: notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                notificationsEnabled = value;
              });
              _saveSettings();
            },
            secondary: Icon(
              notificationsEnabled 
                ? Icons.notifications_active 
                : Icons.notifications_off,
              color: notificationsEnabled ? Colors.black : Colors.black,
            ),
            activeColor: Colors.white,
            activeTrackColor: Colors.black,
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.white,
          ),
          const Divider(),

        ],
      ),
    );
  }
}