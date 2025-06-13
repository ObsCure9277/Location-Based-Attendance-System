import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:location_based_attendance_app/pages/homepage.dart';
import 'package:location_based_attendance_app/pages/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: const KeyboardVisibilityProvider(
        child: AuthCheck(),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool userAvailable = false;
  late SharedPreferences sharedPreferences;
  
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }
  
  void _getCurrentUser() async {
    sharedPreferences = await SharedPreferences.getInstance();

    try{
      if(sharedPreferences.getString('email')!= null){
        setState(() {
          userAvailable = true;
        });
      }
    } catch(e){
      setState(() {
        userAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return userAvailable ? Homepage() : const Login();
  }
}