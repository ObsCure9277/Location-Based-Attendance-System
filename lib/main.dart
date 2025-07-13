import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/service/background_service.dart';
import 'package:universal_html/html.dart' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  if (!kIsWeb) {
    await initBackgroundService();
  }
  if (!kIsWeb) {
    await FlutterDownloader.initialize(debug: true);
  }

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      ),
    );
    
    // Apply mobile phone simulation styles for web
    html.document.documentElement?.style.overflow = 'hidden';
    html.document.body?.style.backgroundColor = '#e0e0e0';
    
    // Center the app and make it look like a phone
    html.document.body?.style.display = 'flex';
    html.document.body?.style.justifyContent = 'center';
    html.document.body?.style.alignItems = 'center';
    html.document.body?.style.height = '100vh';
    html.document.body?.style.margin = '0';
  } else {
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
        theme: ThemeData(fontFamily: 'Poppins'),
        home: kIsWeb 
            ? PhoneSimulator(child: Initial()) 
            : Initial(),
      ),
    );
  }
}

// Phone simulator widget for web
class PhoneSimulator extends StatelessWidget {
  final Widget child;
  
  const PhoneSimulator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only apply phone frame on web
    if (!kIsWeb) return child;
    
    return Center(
      child: Container(
        width: 390, // iPhone 12/13 width
        height: 844, // iPhone 12/13 height
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Phone screen content
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                margin: const EdgeInsets.all(8),
                child: child,
              ),
            ),
            
            // Notch
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 35,
                alignment: Alignment.center,
                child: Container(
                  width: 150,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
