import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ecogo_app/firebase_options.dart';

import 'package:ecogo_app/pages/auth/login_page.dart';
import 'package:ecogo_app/pages/auth/register_page.dart';
import 'package:ecogo_app/pages/geo_page.dart';
import 'package:ecogo_app/pages/home_page.dart';
import 'package:ecogo_app/pages/first_page.dart';
import 'package:ecogo_app/pages/play_page.dart';

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
      home: PlayPage(),
      routes: {
        '/loginpage': (context) => LoginPage(),
        '/registerpage': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/firstpage': (context) => FirstPage(),
        '/geopage': (context) => GeoPage(),
        '/playpage': (context) => PlayPage(),
      }
    );
  }
}
