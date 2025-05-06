import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geo App',
      theme: ThemeData.dark(useMaterial3: true),
      home: const GeoPage(),
      );
  }
}

class GeoPage extends StatefulWidget {
  const GeoPage({super.key});

  @override
  State<GeoPage> createState() => _GeoPageState();
}

class _GeoPageState extends State<GeoPage> {
  Future<Position> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('error no tiene permisos');
      }
    }
    return await Geolocator.getCurrentPosition(); 
    }

    void getCurrentLocation() async {
      Position position = await determinePosition();
      print(position.latitude); 
      print(position.longitude);
    }
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocator'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            getCurrentLocation();
          },
          child: const Text('Tomar ubicación'),
        ),
      ),
    );
  }
}
