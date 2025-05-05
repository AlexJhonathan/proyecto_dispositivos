import 'package:equatable/equatable.dart';
import '../../../domain/entities/location.dart';

abstract class LocationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetCurrentLocationEvent extends LocationEvent {}

class StartLocationStreamEvent extends LocationEvent {}

class StopLocationStreamEvent extends LocationEvent {}

class LocationFailureEvent extends LocationEvent {
  final String message;

  LocationFailureEvent(this.message);

  @override
  List<Object> get props => [message];
}

class LocationSuccessEvent extends LocationEvent {
  final Location location;

  LocationSuccessEvent(this.location);

  @override
  List<Object> get props => [location];
}