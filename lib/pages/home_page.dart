import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:proyecto_dispositivos/pages/prueba.dart';

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
  
  // Definir las dimensiones exactas que usa Teachable Machine
  final int modelInputWidth = 224;
  final int modelInputHeight = 224;
  
  // Resultados detallados para cada clase
  List<double> _confidences = [];
  
  // Configuración para la detección
  final double confidenceThreshold = 0.7; // Umbral de confianza más bajo para detectar mejor
  
  // Variables para el seguimiento de detección continua
  String? _lastDetectedClass;
  int _highConfidenceCounter = 0;
  DateTime? _highConfidenceStartTime;
  bool _isNavigating = false;
  
  // Configuración para la navegación automática
  final double highConfidenceThreshold = 0.98; // 98% o más
  final int requiredDurationInSeconds = 5;     // 5 segundos
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await _loadModel();
    await _initCamera();
    
    // Temporizador para verificar la cámara
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
        ResolutionPreset.medium, // Resolución media para mejor rendimiento
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Formato para Android
      );
      
      await _cameraController!.initialize();
      if (!mounted) return;
      
      // Configurar la cámara para mejores resultados
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
      // Configuración para maximizar el rendimiento
      final interpreterOptions = InterpreterOptions()
        ..threads = 4
        ..useNnApiForAndroid = true;  // Usar Neural API en Android
      
      // Cargar el modelo
      _interpreter = await Interpreter.fromAsset(
        'assets/model_unquant.tflite',
        options: interpreterOptions,
      );
      
      // Cargar etiquetas
      String labelsRaw = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsRaw.split('\n')
          .where((label) => label.isNotEmpty)
          .toList();
          
      print('Modelo cargado con ${_labels.length} etiquetas: $_labels');
      
      // Inicializar array de confianzas
      _confidences = List.filled(_labels.length, 0.0);
      
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      print('Error al cargar el modelo o etiquetas: $e');
      // Mostrar error en la UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar el modelo: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      if (_interpreter == null) {
        _isDetecting = false;
        return;
      }
      
      // Convertir la imagen de la cámara al formato RGB
      final imgLib = await _convertYUV420toImageColor(image);
      
      // Redimensionar la imagen al tamaño que espera el modelo
      final imgResized = img.copyResize(imgLib, width: modelInputWidth, height: modelInputHeight);
      
      // Preparar los datos para el modelo
      Float32List inputData = _imageToTensorData(imgResized);
      
      // Preparar el buffer de salida
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputBuffer = List.filled(outputShape[0] * outputShape[1], 0.0).reshape(outputShape);
      
      // Ejecutar la inferencia
      _interpreter!.run(
        inputData.reshape([1, modelInputHeight, modelInputWidth, 3]), 
        outputBuffer
      );
      
      // Obtener resultados
      final resultList = outputBuffer[0] as List<double>;
      
      // Actualizar las confianzas para todas las clases
      _confidences = List.from(resultList);
      
      // Encontrar la clase con mayor confianza
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
      
      // Imprimir valores para depuración
      print("Confianzas: ${resultList.map((v) => v.toStringAsFixed(2)).toList()}");
      print("Máxima confianza: $maxConfidence para clase: $detectedLabel");
      
      // Comprobar si hay una detección de alta confianza
      if (confidence >= highConfidenceThreshold) {
        // Si es la misma clase que la última vez, incrementar el contador
        if (_lastDetectedClass == detectedLabel) {
          // Si es el primer frame de alta confianza, iniciar el temporizador
          if (_highConfidenceStartTime == null) {
            _highConfidenceStartTime = DateTime.now();
            _highConfidenceCounter = 1;
          } else {
            // Calcular cuánto tiempo ha pasado desde que empezamos a detectar esta clase
            final elapsedSeconds = DateTime.now().difference(_highConfidenceStartTime!).inSeconds;
            _highConfidenceCounter++;
            
            print("Alta confianza en '$detectedLabel' durante $elapsedSeconds segundos (Frames: $_highConfidenceCounter)");
            
            // Si ha pasado el tiempo requerido y no estamos ya navegando
            if (elapsedSeconds >= requiredDurationInSeconds && !_isNavigating) {
              _isNavigating = true;
              
              // Mostrar un mensaje antes de navegar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("¡Producto '$detectedLabel' reconocido! Redirigiendo..."),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
              
              // Pequeño retraso antes de navegar
              Future.delayed(Duration(milliseconds: 1000), () {
                if (mounted) {
                  // Navegar a la pantalla play_page
                  Navigator.pop(context, true);
                }
                
                // Reiniciar contadores después de la navegación
                _highConfidenceStartTime = null;
                _highConfidenceCounter = 0;
                _isNavigating = false;
              });
            }
          }
        } else {
          // Si es una clase diferente, reiniciar el contador
          _lastDetectedClass = detectedLabel;
          _highConfidenceStartTime = DateTime.now();
          _highConfidenceCounter = 1;
        }
      } else {
        // No hay alta confianza, reiniciar el contador
        _lastDetectedClass = null;
        _highConfidenceStartTime = null;
        _highConfidenceCounter = 0;
      }
      
      // Actualizar la UI
      if (confidence >= confidenceThreshold) {
        String confidenceText = (confidence * 100).toStringAsFixed(1) + "%";
        
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
      // Pequeño retraso
      await Future.delayed(Duration(milliseconds: 200));
      _isDetecting = false;
    }
  }
  
  Future<img.Image> _convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;

      // Crear una nueva imagen
      var imgLib = img.Image(width: width, height: height);

      // Convertir YUV a RGB
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
          final int index = y * width + x;

          final int yp = image.planes[0].bytes[index];
          final int up = image.planes[1].bytes[uvIndex];
          final int vp = image.planes[2].bytes[uvIndex];

          // Convertir YUV a RGB
          int r = (yp + 1.402 * (vp - 128)).round().clamp(0, 255);
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round().clamp(0, 255);
          int b = (yp + 1.772 * (up - 128)).round().clamp(0, 255);

          // Establecer el color del píxel
          imgLib.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return imgLib;
    } catch (e) {
      print("Error al convertir imagen: $e");
      // En caso de error, devolver una imagen pequeña
      return img.Image(width: 1, height: 1);
    }
  }

  // Convertir una imagen a la representación de tensor que espera Teachable Machine
  Float32List _imageToTensorData(img.Image image) {
    try {
      var buffer = Float32List(1 * modelInputHeight * modelInputWidth * 3);
      int pixelIndex = 0;
      
      // Recorrer cada píxel y normalizar a [-1, 1] como espera Teachable Machine
      for (int y = 0; y < modelInputHeight; y++) {
        for (int x = 0; x < modelInputWidth; x++) {
          // Obtener el color del píxel
          final pixel = image.getPixel(x, y);
          
          // Para la versión 4.x del paquete image, obtenemos r, g, b directamente del objeto Pixel
          // La clase Pixel en image 4.x tiene getters r, g, b
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          
          // Normalizar a [-1, 1] para modelos de Teachable Machine
          buffer[pixelIndex++] = (r / 127.5) - 1.0;
          buffer[pixelIndex++] = (g / 127.5) - 1.0;
          buffer[pixelIndex++] = (b / 127.5) - 1.0;
        }
      }
      
      return buffer;
    } catch (e) {
      print("Error en _imageToTensorData: $e");
      // En caso de error, devolver un buffer vacío del tamaño correcto
      return Float32List(modelInputHeight * modelInputWidth * 3);
    }
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartCameraStream,
            tooltip: 'Reiniciar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista de cámara
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          
          // Marco de detección
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              margin: EdgeInsets.all(20), // Área de detección más visible
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
                  SizedBox(height: 10),
                  
                  // Mostrar barras de confianza para las clases (similar a la imagen compartida)
                  if (_confidences.isNotEmpty)
                    Container(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _labels.length,
                        itemBuilder: (context, index) {
                          final double confidence = _confidences[index];
                          final Color barColor = _getColorForClass(index);
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                // Etiqueta
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    _labels[index],
                                    style: TextStyle(
                                      color: barColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Barra de confianza
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: barColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      Container(
                                        height: 20,
                                        width: MediaQuery.of(context).size.width * 0.7 * confidence,
                                        decoration: BoxDecoration(
                                          color: barColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      if (confidence > 0.1)
                                        Positioned(
                                          right: 10,
                                          top: 2,
                                          child: Text(
                                            "${(confidence * 100).toStringAsFixed(0)}%",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
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
            ),
          ),
        ],
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/geopage',
            arguments: {
              'showConfirmation': true,
              'userId': 1,
            },
          );
        },
        backgroundColor: Colors.pinkAccent,
        child: Icon(Icons.location_on),
      ),
    );
    
  }
  
  // Generar colores para cada clase (similar a Teachable Machine)
  Color _getColorForClass(int index) {
    final List<Color> colors = [
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.orange[300]!,
      Colors.pink[300]!,
      Colors.purple[300]!,
      Colors.blue[300]!,
      Colors.orange[800]!,
    ];
    
    return colors[index % colors.length];
  }
}