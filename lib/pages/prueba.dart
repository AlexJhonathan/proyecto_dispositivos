import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Prueba extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final VoidCallback onBack;

  const Prueba({
    Key? key,
    required this.currentLat,
    required this.currentLng,
    required this.onBack,
  }) : super(key: key);

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

  final List<Offset> coordenadas = [];
  final Set<Offset> basureros = {};

  @override
  void initState() {
    super.initState();
    currentLat = -21.532900;
    currentLng = -64.730940;
    //currentLat = widget.currentLat;
    //currentLng = widget.currentLng;
    _generarCoordenadasCuadrantes();
    _generarBasureros();
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

 void _generarBasureros() {
    // Coordenadas fijas, en cuadrantes más al centro
    basureros.addAll([
      Offset(-21.532900, -64.730940), // cuadrante central 1
      Offset(-21.532950, -64.730920), // cuadrante central 2
      Offset(-21.532970, -64.730960), // cuadrante central 3
      Offset(-21.532880, -64.730930), // cuadrante central 4
    ]);
  }

  bool _estaEnCuadranteBasurero() {
    double latStep = (maxLat - minLat) / rows;
    double lngStep = (maxLng - minLng) / cols;

    for (final basurero in basureros) {
      int i = ((basurero.dx - minLat) / latStep).floor();
      int j = ((basurero.dy - minLng) / lngStep).floor();

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
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa Universidad"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
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
                        image: AssetImage('assets/mapaU1.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Dibuja los basureros
                  ...basureros.map((offset) {
                    int i = ((offset.dx - minLat) / latStep).floor();
                    int j = ((offset.dy - minLng) / lngStep).floor();

                    return Positioned(
                      left: j * cellWidth + cellWidth / 2 - 6,
                      top: i * cellHeight + cellHeight / 2 - 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        color: Colors.yellow,
                      ),
                    );
                  }).toList(),

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
      floatingActionButton: _estaEnCuadranteBasurero()
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              child: Icon(Icons.camera_alt),
              onPressed: () {
                Navigator.pushNamed(context, '/homepage');
              },
            )
          : null,
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
