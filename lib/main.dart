import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
// import 'services/notification_service.dart'; //

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagan Appointment System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3bc1ff),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3bc1ff),
          primary: const Color(0xFF3bc1ff),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}