import 'package:flutter/material.dart';
import 'package:ecogo_app/pages/geo_page.dart';
import 'package:ecogo_app/pages/notification_page.dart';
import 'package:ecogo_app/pages/user_profile_page.dart';
import 'package:ecogo_app/pages/winnings_page.dart';



class NavScreen extends StatefulWidget {
  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  final _pages = [
    // Aquí reemplaza por tus propias páginas
    GeoPage(),
    NotificationPage(), // Notificaciones
    WinningsPage(), // Ganancias
    UserProfilePage(),  // Perfil
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DBF3C),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF9DBF3C),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 30),
            label: '',
          ),
        ],
      ),
    );
  }
}
