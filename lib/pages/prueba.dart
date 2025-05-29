import 'dart:async';
import 'package:flutter/material.dart';

class Prueba extends StatefulWidget {
  final double currentLat;
  final double currentLng;

  const Prueba({Key? key, required this.currentLat, required this.currentLng}) : super(key: key);

  @override
  _PruebaState createState() => _PruebaState();
}

class _PruebaState extends State<Prueba> {
  final double minLat = -21.533086;
  final double maxLat = -21.532727;
  final double minLng = -64.730968;
  final double maxLng = -64.730890;

  final int rows = 12;
  final int cols = 9;

  late double currentLat;
  late double currentLng;

  int currentIndex = 0;
  List<Offset> coordenadas = [];

  @override
  void initState() {
    super.initState();
    currentLat = widget.currentLat;
    currentLng = widget.currentLng;
    _generarCoordenadasCuadrantes();
    // Si quieres movimiento automático, descomenta la siguiente línea:
    // _iniciarMovimiento();
  }

  void _generarCoordenadasCuadrantes() {
    double latStep = (maxLat - minLat) / rows;
    double lngStep = (maxLng - minLng) / cols;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        double lat = minLat + (i + 0.5) * latStep;
        double lng = minLng + (j + 0.5) * lngStep;
        coordenadas.add(Offset(lat, lng));
      }
    }
  }

  // Si quieres actualizar la posición desde fuera, puedes agregar este método:
  void updateLocation(double lat, double lng) {
    setState(() {
      currentLat = lat;
      currentLng = lng;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ...el resto de tu código permanece igual...
    // Usa currentLat y currentLng normalmente
    // ...
    // (No olvides quitar la inicialización fija de currentLat/currentLng)
    // ...
    // El resto del código sigue igual
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa Universidad"),
        backgroundColor: Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = 350;
          double height = 480;

          double cellWidth = width / cols;
          double cellHeight = height / rows;

          double latStep = (maxLat - minLat) / rows;
          double lngStep = (maxLng - minLng) / cols;

          Offset? puntoCentro;

          for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
              double quadMinLat = minLat + i * latStep;
              double quadMaxLat = quadMinLat + latStep;

              double quadMinLng = minLng + j * lngStep;
              double quadMaxLng = quadMinLng + lngStep;

              bool esUltimaFila = i == rows - 1;
              bool esUltimaColumna = j == cols - 1;

              if (currentLat >= quadMinLat &&
                  (esUltimaFila ? currentLat <= quadMaxLat : currentLat < quadMaxLat) &&
                  currentLng >= quadMinLng &&
                  (esUltimaColumna ? currentLng <= quadMaxLng : currentLng < quadMaxLng)) {
                puntoCentro = Offset(
                  j * cellWidth + cellWidth / 2,
                  i * cellHeight + cellHeight / 2,
                );
              }
            }
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: AssetImage('assets/images/mapaU1.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (puntoCentro != null)
                    CustomPaint(
                      size: Size(width, height),
                      painter: UbicacionPainter(puntoCentro!),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UbicacionPainter extends CustomPainter {
  final Offset centro;

  UbicacionPainter(this.centro);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centro, 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}