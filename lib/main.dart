import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_dispositivos/firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:proyecto_dispositivos/services/auth_service.dart';

import 'package:proyecto_dispositivos/pages/auth/login_page.dart';
import 'package:proyecto_dispositivos/pages/auth/register_page.dart';
import 'package:proyecto_dispositivos/pages/geo_page.dart';
import 'package:proyecto_dispositivos/pages/home_page.dart';
import 'package:proyecto_dispositivos/pages/first_page.dart';
import 'package:proyecto_dispositivos/pages/play_page.dart';
import 'package:proyecto_dispositivos/pages/notification_page.dart';
import 'package:proyecto_dispositivos/pages/admin_notification_page.dart';
import 'package:proyecto_dispositivos/pages/winnings_page.dart';
import 'package:proyecto_dispositivos/pages/admin_winnings_page.dart';
import 'package:proyecto_dispositivos/pages/user_profile_page.dart';
import 'package:proyecto_dispositivos/pages/auth_admin_page.dart';
import 'package:proyecto_dispositivos/pages/nav_screen.dart';//import 'package:proyecto_dispositivos/pages/prueba.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const MainApp(),
    ),
  );
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
