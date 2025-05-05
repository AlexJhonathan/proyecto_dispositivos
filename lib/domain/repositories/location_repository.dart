import 'package:dartz/dartz.dart';
import '../entities/location.dart';
import '../../core/errors/failures.dart';

abstract class LocationRepository {
  Future<Either<Failure, Location>> getCurrentLocation();
  Stream<Either<Failure, Location>> getLocationStream();
}