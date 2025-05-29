import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'prueba.dart'; // Asegúrate de importar la pantalla Prueba

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
  double? _latitude;
  double? _longitude;
  String? _error;

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
    try {
      Position position = await determinePosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  void goToPrueba() {
    if (_latitude != null && _longitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Prueba(
            currentLat: _latitude!,
            currentLng: _longitude!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero toma la ubicación')),
      );
    }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getCurrentLocation,
              child: const Text('Tomar ubicación'),
            ),
            const SizedBox(height: 20),
            if (_latitude != null && _longitude != null)
              Text(
                'Latitud: ${_latitude!.toStringAsFixed(6)}\nLongitud: ${_longitude!.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: goToPrueba,
              child: const Text('Ir al mapa'),
            ),
          ],
        ),
      ),
    );
  }
}