import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ecogo_app/firebase_options.dart';

import 'package:ecogo_app/pages/auth/login_page.dart';
import 'package:ecogo_app/pages/auth/register_page.dart';
import 'package:ecogo_app/pages/geo_page.dart';
import 'package:ecogo_app/pages/home_page.dart';
import 'package:ecogo_app/pages/first_page.dart';
import 'package:ecogo_app/pages/play_page.dart';
import 'package:ecogo_app/pages/notification_page.dart';
import 'package:ecogo_app/pages/admin_notification_page.dart';
import 'package:ecogo_app/pages/winnings_page.dart';
import 'package:ecogo_app/pages/admin_winnings_page.dart';
import 'package:ecogo_app/pages/user_profile_page.dart';
import 'package:ecogo_app/pages/auth_admin_page.dart';
import 'package:ecogo_app/pages/nav_screen.dart';//import 'package:ecogo_app/pages/prueba.dart';

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
        '/loginpage': (context) => LoginPage(),
        '/registerpage': (context) => RegisterPage(),
        '/homepage': (context) => HomePage(),
        '/firstpage': (context) => FirstPage(),
        '/geopage': (context) => GeoPage(),
        '/play': (context) => PlayPage(),
        '/notificationpage': (context) => NotificationPage(),
        '/adminnotificationpage': (context) => AdminNotificationPage(),
        '/winningspage': (context) => WinningsPage(),
        '/adminwinningspage': (context) => AdminWinningsPage(),
        '/userprofilepage': (context) => UserProfilePage(),
        '/authadminpage': (context) => AuthAdminPage(),
        '/navscreen': (context) => NavScreen(),
        //'/prueba': (context) => Prueba(),
      }
    );
  }
}
