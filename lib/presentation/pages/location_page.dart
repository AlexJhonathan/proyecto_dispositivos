import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/location/location_event.dart';
import '../bloc/location/location_state.dart';
import '../widgets/location_display.dart';
import 'dart:math' as math;

class LocationPage extends StatelessWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Ubicación',
          style: TextStyle(
            color: Color(0xFF993300), 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xB4CD1B), 
        iconTheme: IconThemeData(color: Color(0xFF993300)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB4CD1B), Color(0xFF9CB018)], 
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: MiniMapPainter(),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8, 
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF993300),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text('Tu ubicación', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF88AA00),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text('Basureros', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    if (state is LocationInitial) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Presiona el botón para obtener tu ubicación',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF993300),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    } else if (state is LocationLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF993300),
                        ),
                      );
                    } else if (state is LocationSuccess) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LocationDisplay(location: state.location),
                        ),
                      );
                    } else if (state is LocationFailure) {
                      return Card(
                        elevation: 4,
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${state.message}',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<LocationBloc>().add(GetCurrentLocationEvent());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD9A404),
                      foregroundColor: Color(0xFF993300), 
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Obtener Mi Ubicación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Buscando basureros cercanos...'),
                        backgroundColor: Color(0xFF993300),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF993300)),
                    foregroundColor: Color(0xFF993300),
                  ),
                  child: const Text('Encontrar basureros cercanos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = Color(0xFFE8E8E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    final Paint streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, 0),
      Offset(size.width * 0.25, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.6, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.8, size.height),
      streetPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      streetPaint,
    );
    final Paint trashCanPaint = Paint()
      ..color = Color(0xFF88AA00)
      ..style = PaintingStyle.fill;

    final List<Offset> trashCanPositions = [
      Offset(size.width * 0.25, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.75),
      Offset(size.width * 0.4, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.2),
    ];

    for (var position in trashCanPositions) {
      canvas.drawCircle(position, 6, trashCanPaint);
    }
    final Paint locationPaint = Paint()
      ..color = Color(0xFF993300)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.5),
      8,
      locationPaint,
    );

    final Paint pulsePaint = Paint()
      ..color = Color(0xFF993300).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.5),
      15,
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}