import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // File hasil generate dari flutterfire configure
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  // Wajib dipanggil sebelum Firebase.initializeApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(const DragRacingApp());
}

class DragRacingApp extends StatelessWidget {
  const DragRacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}