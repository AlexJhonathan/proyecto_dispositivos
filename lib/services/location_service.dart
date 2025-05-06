import 'package:geolocator/geolocator.dart';

class LocationService {
  // Método para verificar si los servicios de ubicación están habilitados
  Future<bool> checkLocationServices() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Método para verificar y solicitar permisos
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Método principal para obtener la ubicación actual
  Future<Position?> getCurrentLocation() async {
    // Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await checkLocationServices();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados.');
    }

    // Verificar permisos
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Los permisos de ubicación fueron denegados.');
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos de ubicación están permanentemente denegados, no se puede solicitar permisos.');
    }

    // Obtener la ubicación actual con alta precisión
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Error al obtener la ubicación: $e');
    }
  }

  // Método para obtener actualizaciones continuas de ubicación
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // En metros, actualiza cuando se mueve más de 10 metros
      ),
    );
  }
}