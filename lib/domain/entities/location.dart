import 'package:equatable/equatable.dart';

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracy;  // Precisión en metros
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime? timestamp;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, altitude, speed, heading];
}