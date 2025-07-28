import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
            SizedBox(height: screenHeight / 6),
            Icon(
              Icons.my_location, 
              color: Colors.white, 
              size: screenWidth * 0.2
            ),
            SizedBox(height: screenHeight * 0.025),
            Text(
              'GeoMark',
              style: TextStyle(
                fontSize: screenWidth * 0.08,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.0125),
            Text(
              'No Punch, Just Presence',
              style: TextStyle(
                fontFamily: "NexaRegular",
                fontSize: screenWidth * 0.04,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: screenHeight / 7),
            Center(
              child: Text(
                "Welcome to GeoMark",
                style: TextStyle(
                  fontSize: screenWidth / 18,
                  color: Colors.white,
                  fontFamily: "NexaBold",
                  letterSpacing: screenWidth * 0.005,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
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
            SizedBox(height: screenHeight * 0.0125),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Signup()),
                );
              },
              child: initialButtonInText('SIGN UP', screenWidth, screenHeight),
            ),
            SizedBox(height: screenHeight * 0.0125),
          ],
        ),
      ),
    );
  }
}
