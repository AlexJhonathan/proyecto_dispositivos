import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class StreamLocationUpdates {
  final LocationRepository repository;

  StreamLocationUpdates(this.repository);

  Stream<Either<Failure, Location>> call() {
    return repository.getLocationStream();
  }
}