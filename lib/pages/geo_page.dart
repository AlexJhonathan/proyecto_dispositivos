import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'prueba.dart'; // Asegúrate de importar la pantalla Prueba
import 'package:ecogo_app/services/points_service.dart';

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
  final bool showConfirmation = false;
   final String userId = 'defaultUserId'; // Cambia esto por el ID del usuario real

  @override
  State<GeoPage> createState() => _GeoPageState();
}

class _GeoPageState extends State<GeoPage> {
  double? _latitude;
  double? _longitude;
  String? _error;

  final PointsService _pointsService = PointsService();

  

  bool showPrueba = false;

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

  @override
  void initState() {
    super.initState();
    if (widget.showConfirmation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmationDialog();
      });
    }
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

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Gracias!'),
        content: const Text('Has botado la basura correctamente.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // cerrar diálogo
              await _pointsService.addPoints(widget.userId, 15);
              setState(() {}); // actualizar vista si deseas mostrar puntos
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void goToPrueba() {
  if (_latitude != null && _longitude != null) {
    setState(() {
      showPrueba = true;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Primero toma la ubicación')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (showPrueba) {
      return Prueba(
        currentLat: _latitude!,
        currentLng: _longitude!,
        onBack: () => setState(() => showPrueba = false), // para volver
      );
    }

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