import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

class WinningsPage extends StatefulWidget {
  @override
  _WinningsPageState createState() => _WinningsPageState();
}

class _WinningsPageState extends State<WinningsPage> {
  int userPoints = 1500; // Puntos predeterminados
  String? qrData;
  DateTime? qrExpiration;
  final GlobalKey _qrKey = GlobalKey(); // Key para capturar el QR
  
  // Listas de canje
  final List<Map<String, dynamic>> dineroCanjes = [
    {'puntos': 1000, 'valor': 50, 'moneda': 'bs'},
    {'puntos': 2000, 'valor': 100, 'moneda': 'bs'},
    {'puntos': 3000, 'valor': 150, 'moneda': 'bs'},
    {'puntos': 5000, 'valor': 250, 'moneda': 'bs'},
    {'puntos': 10000, 'valor': 500, 'moneda': 'bs'},
  ];

  final List<Map<String, dynamic>> productosCanjes = [
    {'puntos': 50, 'producto': 'Dulce'},
    {'puntos': 100, 'producto': 'Galleta'},
    {'puntos': 200, 'producto': 'Jugo'},
    {'puntos': 300, 'producto': 'Sandwich'},
    {'puntos': 500, 'producto': 'Combo Completo'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'GANANCIAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade300,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Puntos section
                        Column(
                          children: [
                            Text(
                              'TUS PUNTOS:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.brown.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '$userPoints pts',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tiempo de juego: 45 min\n¡Sigue jugando para ganar más!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Canje buttons
                        Column(
                          children: [
                            _buildCanjeCard(
                              icon: '💰',
                              text: 'Canjea por dinero',
                              onPressed: () => _showDineroList(),
                            ),
                            SizedBox(height: 16),
                            _buildCanjeCard(
                              icon: '🍫',
                              text: 'Canjea por productos',
                              onPressed: () => _showProductosList(),
                            ),
                          ],
                        ),
                        
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanjeCard({required String icon, required String text, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'CANJEAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDineroList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCanjeList(dineroCanjes, 'dinero'),
    );
  }

  void _showProductosList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCanjeList(productosCanjes, 'producto'),
    );
  }

  Widget _buildCanjeList(List<Map<String, dynamic>> items, String type) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
              ),
              Text(
                'Canje por ${type == 'dinero' ? 'Dinero' : 'Productos'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tus puntos: $userPoints',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final puntos = item['puntos'] as int;
                final canCanje = userPoints >= puntos;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$puntos puntos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              type == 'dinero' 
                                ? '= ${item['valor']} ${item['moneda']}'
                                : '= ${item['producto']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: canCanje ? () => _showConfirmDialog(item, type) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCanje ? Colors.green.shade500 : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'CANJEAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: canCanje ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(Map<String, dynamic> item, String type) {
    final puntos = item['puntos'] as int;
    
    if (userPoints < puntos) {
      _showInsufficientPointsDialog();
      return;
    }
    
    final description = type == 'dinero' 
      ? '${item['valor']} ${item['moneda']}'
      : item['producto'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('¿Estás seguro?'),
          ],
        ),
        content: Text('¿Cambiar $puntos puntos por $description?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              _processExchange(item, type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade500,
            ),
            child: Text('ACEPTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.close, color: Colors.red),
            SizedBox(width: 8),
            Text('Puntos Insuficientes'),
          ],
        ),
        content: Text('¡Sigue jugando para ganar más puntos!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade500,
            ),
            child: Text('CONTINUAR JUGANDO', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processExchange(Map<String, dynamic> item, String type) {
    final puntos = item['puntos'] as int;
    
    // Generate unique QR code
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString() + 
                    Random().nextInt(10000).toString();
    
    final qrDataMap = {
      'id': uniqueId,
      'type': type,
      'points': puntos,
      'value': type == 'dinero' ? '${item['valor']} ${item['moneda']}' : item['producto'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expires': DateTime.now().add(Duration(minutes: 10)).millisecondsSinceEpoch,
    };
    
    setState(() {
      userPoints -= puntos;
      qrData = jsonEncode(qrDataMap);
      qrExpiration = DateTime.fromMillisecondsSinceEpoch(qrDataMap['expires']);
    });
    
    _showQRDialog();
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Canje Exitoso!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Expira: ${qrExpiration?.toLocal().toString().substring(11, 19)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 16),
              if (qrData != null)
                RepaintBoundary(
                  key: _qrKey, // Key para capturar el widget
                  child: Container(
                    width: 200,
                    height: 200,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: QrImageView(
                      data: qrData!,
                      version: QrVersions.auto,
                      size: 180.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              SizedBox(height: 8),
              Text(
                'Código QR de Canje',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _downloadQR(),
                    icon: Icon(Icons.download),
                    label: Text('DESCARGAR'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                    ),
                    child: Text(
                      'CERRAR',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadQR() async {
    try {
      // Verificar si tenemos permisos para usar la galería
      if (!await Gal.hasAccess()) {
        final hasAccess = await Gal.requestAccess();
        if (!hasAccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se necesitan permisos para guardar la imagen'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Capturar el widget QR como imagen
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Obtener directorio temporal para guardar el archivo
      final tempDir = await getTemporaryDirectory();
      final fileName = "QR_Canje_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File('${tempDir.path}/$fileName');
      
      // Escribir los bytes al archivo
      await file.writeAsBytes(pngBytes);

      // Guardar en galería usando Gal
      await Gal.putImage(file.path);

      // Eliminar archivo temporal
      await file.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR guardado en galería exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar QR: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}