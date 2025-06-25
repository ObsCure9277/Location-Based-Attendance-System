import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_home.dart';
import 'package:location_based_attendance_app/pages/Global/login.dart';
import 'package:location_based_attendance_app/pages/Global/sign_up.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';

class Initial extends StatelessWidget {
  const Initial({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = 0;
    double screenHeight = 0;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: screenHeight / 8),
            Icon(Icons.my_location, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            Text(
              'GeoMark',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No Punch, Just Presence',
              style: TextStyle(
                fontFamily: "NexaRegular",
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: screenHeight / 8),
            Center(
                  child: Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: screenWidth / 18,
                      color: Colors.white,
                      fontFamily: "NexaBold",
                      letterSpacing: 2,
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KeyboardVisibilityProvider(child: Login())
                  )
                );
              },
              child: initialButtonInText('LOGIN', screenWidth, screenHeight),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Signup()),
                );
              },
              child: initialButtonInText('SIGN UP', screenWidth, screenHeight),
            ),
             const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Adminhomepage()),
                );
              },
              child: initialButtonInText('ADMIN', screenWidth, screenHeight),
            ),
          ],
        ),
      ),
    );
  }
}
