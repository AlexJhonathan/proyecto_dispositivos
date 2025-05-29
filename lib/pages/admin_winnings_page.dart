import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:convert';
import 'dart:io';

class AdminWinningsPage extends StatefulWidget {
  @override
  _AdminWinningsPageState createState() => _AdminWinningsPageState();
}

class _AdminWinningsPageState extends State<AdminWinningsPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String scannedCode = '';
  bool isScanning = false;
  bool isProcessing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade400, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      'Admin - Validar Canjes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      if (!isScanning) _buildScannerOptions(),
                      if (isScanning) _buildQRScanner(),
                      if (scannedCode.isNotEmpty && !isScanning) _buildScannedResult(),
                      _buildInstructions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOptions() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.purple.shade400,
            ),
            SizedBox(height: 24),
            Text(
              'Escanear Código QR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Escanea el código QR del usuario para validar el canje',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 32),
            
            // Scanner button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isScanning = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade500,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'ABRIR ESCÁNER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Manual input option
            OutlinedButton(
              onPressed: () => _showManualInputDialog(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.purple.shade400),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'INGRESAR CÓDIGO MANUAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isScanning = false;
                    });
                    controller?.dispose();
                  },
                  icon: Icon(Icons.arrow_back),
                ),
                Text(
                  'Escanear QR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade300, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.purple.shade400,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 250,
                  ),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Apunta la cámara hacia el código QR',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedResult() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.qr_code,
              size: 60,
              color: Colors.green.shade500,
            ),
            SizedBox(height: 16),
            Text(
              'Código Escaneado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                scannedCode.length > 100 
                  ? '${scannedCode.substring(0, 100)}...'
                  : scannedCode,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            if (isProcessing)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _validateQRCode(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'VALIDAR CANJE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          scannedCode = '';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CANCELAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600),
              SizedBox(width: 8),
              Text(
                'Instrucciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. Escanea el QR del usuario con la cámara\n'
            '2. Verifica que el código sea válido\n'
            '3. Entrega el producto o dinero correspondiente\n'
            '4. El código expira en 10 minutos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isProcessing && scanData.code != null) {
        setState(() {
          scannedCode = scanData.code!;
          isScanning = false;
          isProcessing = true;
        });
        
        controller.dispose();
        
        // Delay to show processing state
        Future.delayed(Duration(milliseconds: 500), () {
          setState(() {
            isProcessing = false;
          });
        });
      }
    });
  }

  void _showManualInputDialog() {
    final TextEditingController textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar Código Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pega el código QR aquí:'),
            SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Código QR...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  scannedCode = textController.text;
                });
                Navigator.pop(context);
              }
            },
            child: Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  void _validateQRCode() {
    setState(() {
      isProcessing = true;
    });
    
    try {
      final Map<String, dynamic> qrData = jsonDecode(scannedCode);
      final int expirationTime = qrData['expires'];
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      
      if (currentTime > expirationTime) {
        _showResultDialog(
          title: 'Código Expirado',
          message: 'Este código QR ya ha expirado.',
          isSuccess: false,
        );
        return;
      }
      
      // Valid QR code
      final String type = qrData['type'];
      final int points = qrData['points'];
      final String value = qrData['value'];
      
      _showResultDialog(
        title: 'Canje Válido',
        message: 'Canje confirmado:\n$points puntos por $value\nTipo: $type',
        isSuccess: true,
      );
      
    } catch (e) {
      _showResultDialog(
        title: 'Código Inválido',
        message: 'El código QR no es válido o está corrupto.',
        isSuccess: false,
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                setState(() {
                  scannedCode = '';
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.red,
            ),
            child: Text(
              'ACEPTAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}