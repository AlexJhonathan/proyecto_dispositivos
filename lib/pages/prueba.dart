import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_dispositivos/services/auth_service.dart';

class Prueba extends StatefulWidget {
  final double currentLat = -21.532860;
  final double currentLng = -64.730900;
  final double originalLat = -21.532860;
  final double originalLng = -64.730900;
  final bool mostrarRuta;

  const Prueba({
    Key? key,
    this.mostrarRuta = false,
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
  late double originalLat;
  late double originalLng;

  final List<Offset> coordenadas = [];
  final Set<Offset> basureros = {};
  bool mostrarRuta = false;

  @override
void initState() {
  super.initState();

  double latStep = (maxLat - minLat) / rows;
  double lngStep = (maxLng - minLng) / cols;

  originalLat = minLat + (4 + 0.5) * latStep;
  originalLng = minLng + (5 + 0.5) * lngStep;

  currentLat = originalLat;
  currentLng = originalLng;
  mostrarRuta = widget.mostrarRuta;

  _generarCoordenadasCuadrantes();

  double basureroLat = minLat + (2 + 0.5) * latStep;
  double basureroLng = minLng + (4 + 0.5) * lngStep;
  
  double basureroLat1 = minLat + (6 + 0.5) * latStep;
  double basureroLng1 = minLng + (2 + 0.5) * lngStep;

  double basureroLat2 = minLat + (9 + 0.5) * latStep;
  double basureroLng2 = minLng + (4 + 0.5) * lngStep;

  double basureroLat3 = minLat + (10 + 0.5) * latStep;
  double basureroLng3 = minLng + (8 + 0.5) * lngStep;

  basureros.clear();
  basureros.add(Offset(basureroLat, basureroLng));
  basureros.add(Offset(basureroLat1, basureroLng1));
  basureros.add(Offset(basureroLat2, basureroLng2));
  basureros.add(Offset(basureroLat3, basureroLng3)); // Fila 3, columna 5

  
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

  @override
  Widget build(BuildContext context) {
    double width = 350;
    double height = 480;

    double cellWidth = width / cols;
    double cellHeight = height / rows;

    double latStep = (maxLat - minLat) / rows;
    double lngStep = (maxLng - minLng) / cols;

    Offset? puntoCentro;
    Offset? puntoBasurero;

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

    if (basureros.isNotEmpty) {
      final b = basureros.first;
      int i = ((b.dx - minLat) / latStep).floor();
      int j = ((b.dy - minLng) / lngStep).floor();

      puntoBasurero = Offset(
        j * cellWidth + cellWidth / 2,
        i * cellHeight + cellHeight / 2,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa Universidad"),
        backgroundColor: Color.fromARGB(255, 140, 198, 64),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFFE8F5E8),
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

                  if (mostrarRuta && puntoCentro != null && puntoBasurero != null)
                    CustomPaint(
                      size: Size(width, height),
                      painter: RutaPainter(puntoCentro!, puntoBasurero),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: mostrarRuta
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                 onPressed: () async {
                  double latStep = (maxLat - minLat) / rows;
                  double lngStep = (maxLng - minLng) / cols;

                  // Movimiento paso a paso: izquierda 1 (lng -) y arriba 2 (lat -)
                  List<Offset> pasos = [
                    Offset(currentLat, currentLng - lngStep), // 1 paso izquierda
                    Offset(currentLat - latStep, currentLng - lngStep), // 1 paso arriba
                    Offset(currentLat - 2 * latStep, currentLng - lngStep), // otro paso arriba
                  ];

                  for (int i = 0; i < pasos.length; i++) {
                    await Future.delayed(Duration(seconds: 10));
                    setState(() {
                      currentLat = pasos[i].dx;
                      currentLng = pasos[i].dy;
                    });
                  }

                  // Espera 1 segundo adicional antes de mostrar el mensaje de éxito
                  await Future.delayed(Duration(seconds: 4));

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("¡Éxito!"),
                        content: Text("Ganaste 20 puntos 🎉"),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              final authService = Provider.of<AuthService>(context, listen: false);
                              await authService.sumarPuntos(20);

                              setState(() {
                                currentLat = originalLat;
                                currentLng = originalLng;
                                mostrarRuta = false;
                              });
                            },
                            child: Text("OK"),
                          ),
                        ],
                      ),
                    );
                  
                },
                  icon: Icon(Icons.directions_walk),
                  label: Text("Comenzar el recorrido"),
                  backgroundColor: Color.fromARGB(255, 47, 147, 255),
                ),
                SizedBox(height: 10),
              ],
            )
          : FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 47, 147, 255),
              child: Icon(Icons.camera_alt, color: Colors.white),
              onPressed: () async {
                // Al volver desde la cámara, pasar `mostrarRuta = true`
                final result = await Navigator.pushNamed(context, '/homepage');
                if (result == true) {
                  setState(() {
                    mostrarRuta = true;
                  });
                }
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

class RutaPainter extends CustomPainter {
  final Offset inicio;
  final Offset fin;
  RutaPainter(this.inicio, this.fin);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3;
    canvas.drawLine(inicio, fin, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
