import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure({required this.message});
  
  @override
  List<Object> get props => [message];
}

class LocationFailure extends Failure {
  const LocationFailure({required String message}) : super(message: message);
}