import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb){
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyA91zxDnmMKowohrLXO1LnLMO9vlsc2wqk",
        authDomain: "geofencing-attendance-ap-910c8.firebaseapp.com",
        projectId: "geofencing-attendance-ap-910c8",
        storageBucket: "geofencing-attendance-ap-910c8.firebasestorage.app",
        messagingSenderId: "340718914134",
        appId: "1:340718914134:web:4bb0c54185d0e692e489f7"));
  }else{
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityProvider(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
        ),
        home: Initial(),
      ),
    );
  }
}

