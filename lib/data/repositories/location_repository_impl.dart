import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    try {
      final locationModel = await dataSource.getCurrentLocation();
      return Right(locationModel);
    } catch (e) {
      return Left(LocationFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Location>> getLocationStream() {
    return dataSource.getLocationStream()
      .map((location) => Right<Failure, Location>(location))
      .handleError((error) => Left(LocationFailure(message: error.toString())));
  }
}