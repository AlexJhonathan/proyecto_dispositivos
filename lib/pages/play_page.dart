import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'home_page.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({Key? key}) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late Stream<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
      );
      return;
    }

    _startLocationStream();
  }

  void _startLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualiza cada 10 metros
      ),
    );

    _positionStream.listen((Position position) {
      // Imprimimos las coordenadas en la terminal en lugar de actualizar el estado
      print("Lat: ${position.latitude}, Lng: ${position.longitude}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Minimapa dibujado
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height),
            painter: MiniMapPainter(),
          ),
          // Botón flotante para ir a HomePage
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill;

    // Fondo del minimapa
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Simulación de calles
    final streetPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Dibujar calles horizontales
    for (double y = 50; y < size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }

    // Dibujar calles verticales
    for (double x = 50; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // Simulación de un marcador
    final markerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 10, markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}