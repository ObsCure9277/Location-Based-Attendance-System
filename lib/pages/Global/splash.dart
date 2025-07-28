import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    Future.delayed(const Duration(seconds: 2), () {});
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.my_location,
              color: Colors.white,
              size: screenWidth * 0.2, 
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
            SizedBox(height: screenHeight * 0.05), 
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: screenWidth * 0.01, 
            ),
          ],
        ),
      ),
    );
  }
}
