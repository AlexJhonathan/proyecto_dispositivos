import 'package:equatable/equatable.dart';
import '../../../domain/entities/location.dart';

abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSuccess extends LocationState {
  final Location location;

  LocationSuccess(this.location);

  @override
  List<Object> get props => [location];
}

class LocationFailure extends LocationState {
  final String message;

  LocationFailure(this.message);

  @override
  List<Object> get props => [message];
}