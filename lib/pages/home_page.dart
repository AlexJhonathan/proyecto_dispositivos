import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'geo_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? imagePath;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Esperamos un momento para asegurar que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraPermission();
    });
  }

  Future<void> _checkCameraPermission() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _setError('Permiso de cámara denegado');
          return;
        }
      }
      
      if (status.isPermanentlyDenied) {
        _setError('Permiso de cámara denegado permanentemente. Por favor habilítalo en la configuración');
        return;
      }
      
      await _openCamera();
    } catch (e) {
      _setError('Error al verificar permisos: $e');
    }
  }

  void _setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      setState(() {
        isLoading = false;
      });
      
      if (image != null) {
        setState(() {
          imagePath = image.path;
        });
        
        // Navegar automáticamente a GeoPage cuando se tenga la imagen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GeoPage()),
        );
      } else {
        _setError('No se seleccionó ninguna imagen');
      }
    } catch (e) {
      _setError('Error al abrir la cámara: $e');
      
      // Si estamos en un emulador, podemos navegar directamente a la siguiente pantalla
      // para pruebas de desarrollo
      if (e.toString().contains('no_available_camera')) {
        _handleEmulatorTesting();
      }
    }
  }
  
  void _handleEmulatorTesting() {
    // En desarrollo, para pruebas en emulador, podemos navegar
    // directamente a la siguiente pantalla
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GeoPage()),
      );
    });
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Iniciando cámara...'),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _checkCameraPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.file(
              File(imagePath!),
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? _buildLoadingIndicator()
            : errorMessage.isNotEmpty
                ? _buildErrorMessage()
                : _buildImagePreview(),
      ),
    );
  }
}