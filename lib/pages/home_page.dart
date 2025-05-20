import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:async';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  String? _result;
  bool _modelLoaded = false;
  Interpreter? _interpreter;
  List<String> _labels = [];
  Timer? _timer;
  
  // Definir las dimensiones que espera tu modelo de Teachable Machine
  final int modelInputWidth = 224; // Ajusta al tamaño que espera tu modelo
  final int modelInputHeight = 224; // Ajusta al tamaño que espera tu modelo
  final int numChannels = 3; // RGB
  
  // Configuración para la detección
  final double confidenceThreshold = 0.9; // Reducido para detectar con más facilidad
  final double highConfidenceThreshold = 0.9; // Umbral para mostrar "¡100%!"

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await _loadModel();
    await _initCamera();
    
    // Comenzar un temporizador para verificar y reiniciar la cámara si es necesario
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
        print("Reiniciando el flujo de imágenes de la cámara...");
        _restartCameraStream();
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera, 
        ResolutionPreset.medium, // Cambiado a medium para mejor detección
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      if (!mounted) return;
      
      await _cameraController!.setExposureMode(ExposureMode.auto);
      await _cameraController!.setFlashMode(FlashMode.off);
      
      setState(() {});
      
      await _startCameraStream();
      
    } catch (e) {
      print('Error al inicializar la cámara: $e');
    }
  }
  
  Future<void> _startCameraStream() async {
    await _cameraController!.startImageStream((CameraImage image) {
      if (!_isDetecting && _modelLoaded) {
        _isDetecting = true;
        _processCameraImage(image);
      }
    });
  }
  
  Future<void> _restartCameraStream() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await Future.delayed(Duration(milliseconds: 500));
        await _startCameraStream();
      }
    } catch (e) {
      print('Error al reiniciar el flujo de la cámara: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      // Aumentar el número de hilos para mejorar el rendimiento
      final interpreterOptions = InterpreterOptions()..threads = 4;
      
      // 1. Cargar el modelo de Teachable Machine
      _interpreter = await Interpreter.fromAsset(
        'assets/model_unquant.tflite',
        options: interpreterOptions,
      );
      
      // 2. Cargar las etiquetas desde el archivo
      String labelsRaw = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsRaw.split('\n')
          .where((label) => label.isNotEmpty)
          .toList();
          
      print('Modelo cargado con ${_labels.length} etiquetas: $_labels');
      
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print('Error al cargar el modelo o etiquetas: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      if (_interpreter == null) {
        _isDetecting = false;
        return;
      }
      
      // Preprocesar imagen a escala completa (toda la pantalla)
      var inputBytes = _prepareInputData(image);
      
      // Crear el tensor de entrada
      final input = inputBytes.buffer.asFloat32List();
      
      // Preparar la salida según el número de clases
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputBuffer = List.filled(outputShape[0] * outputShape[1], 0.0).reshape(outputShape);
      
      // Ejecutar la inferencia con toda la imagen
      final inputShape = [1, modelInputHeight, modelInputWidth, 3];
      _interpreter!.run(
        input.reshape(inputShape), 
        outputBuffer
      );
      
      final resultList = outputBuffer[0] as List<double>;
      
      // Encontrar el índice con la mayor confianza
      int maxIndex = 0;
      double maxConfidence = resultList[0];
      
      for (int i = 1; i < resultList.length; i++) {
        if (resultList[i] > maxConfidence) {
          maxConfidence = resultList[i];
          maxIndex = i;
        }
      }
      
      // Obtener la etiqueta detectada
      String detectedLabel = maxIndex < _labels.length ? _labels[maxIndex] : "Desconocido";
      double confidence = maxConfidence;
      
      // Imprimir valores de confianza para depuración
      print("Confianzas: ${resultList.map((v) => v.toStringAsFixed(2)).toList()}");
      print("Máxima confianza: $maxConfidence para clase: $detectedLabel");
      
      // Formatear el resultado para mostrar
      if (confidence >= confidenceThreshold) {
        String confidenceText = (confidence * 100).toStringAsFixed(1) + "%";
        
        // Mostrar 100% para alta confianza
        if (confidence >= highConfidenceThreshold) {
          confidenceText = "100%";
          
          // Mostrar un snackbar para detecciones de alta confianza
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("¡Detectado: $detectedLabel!"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        
        setState(() {
          _result = "$detectedLabel - $confidenceText";
        });
      } else {
        setState(() {
          _result = "Analizando...";
        });
      }
    } catch (e) {
      print('Error en la inferencia: $e');
    } finally {
      // Añadir un pequeño retraso para evitar sobrecarga de la CPU
      await Future.delayed(Duration(milliseconds: 100));
      _isDetecting = false;
    }
  }
  
  // Método optimizado para preparar los datos de entrada utilizando toda la imagen
  Float32List _prepareInputData(CameraImage image) {
    // Para modelos de Teachable Machine
    var buffer = Float32List(1 * modelInputHeight * modelInputWidth * 3);
    
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;
    
    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;
    
    // Factor de escala para usar toda la imagen
    final xScale = image.width / modelInputWidth;
    final yScale = image.height / modelInputHeight;
    
    int pixelIndex = 0;
    
    for (int j = 0; j < modelInputHeight; j++) {
      for (int i = 0; i < modelInputWidth; i++) {
        // Mapear a la ubicación en la imagen original
        final int sourceX = (i * xScale).floor().clamp(0, image.width - 1);
        final int sourceY = (j * yScale).floor().clamp(0, image.height - 1);
        
        // Calcular índices para YUV
        final int yIndex = sourceY * yRowStride + sourceX;
        final int uvIndex = (sourceY ~/ 2) * uvRowStride + (sourceX ~/ 2) * uvPixelStride;
        
        // Obtener valores YUV
        final int y = yPlane[yIndex];
        final int u = uPlane[uvIndex];
        final int v = vPlane[uvIndex];
        
        // Conversión YUV a RGB
        final int r = (y + 1.402 * (v - 128)).round().clamp(0, 255);
        final int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round().clamp(0, 255);
        final int b = (y + 1.772 * (u - 128)).round().clamp(0, 255);
        
        // Normalizar a [-1, 1] para modelos Teachable Machine
        buffer[pixelIndex++] = (r / 127.5) - 1.0;
        buffer[pixelIndex++] = (g / 127.5) - 1.0;
        buffer[pixelIndex++] = (b / 127.5) - 1.0;
      }
    }
    
    return buffer;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Inicializando cámara...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección de Objetos'),
        backgroundColor: Colors.black,
        actions: [
          // Botón para reiniciar la cámara si hay problemas
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartCameraStream,
            tooltip: 'Reiniciar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista de cámara a pantalla completa
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          
          // Indicación visual de que toda la pantalla es el área de detección
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              margin: EdgeInsets.all(10), // Pequeño margen para mostrar que usa casi toda la pantalla
            ),
          ),
          
          // Panel de resultados
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _result ?? "Analizando objeto...",
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Mostrar mensaje especial para detecciones de alta confianza
                  if (_result != null && _result!.contains("100%"))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "¡OBJETO DETECTADO!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}