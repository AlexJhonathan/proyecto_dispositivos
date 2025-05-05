import 'package:dartz/dartz.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';
import '../../core/errors/failures.dart';

class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  Future<Either<Failure, Location>> call() async {
    return await repository.getCurrentLocation();
  }
}