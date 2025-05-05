import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geo_app/firebase_options.dart';

import 'package:geo_app/presentation/pages/auth/login_page.dart';
import 'package:geo_app/presentation/pages/auth/register_page.dart';
import 'package:geo_app/presentation/pages/home_page.dart';
import 'package:geo_app/presentation/pages/first_page.dart';
import 'package:geo_app/presentation/pages/location_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/locationpage': (context) => const LocationPage(),
        '/loginpage': (context) => LoginPage(),
        '/registerpage': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/firstpage': (context) => FirstPage(),
      }
    );
  }
}
