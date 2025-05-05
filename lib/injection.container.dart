import 'package:get_it/get_it.dart';
import 'data/datasources/location_data_source.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/usecases/get_current_location.dart';
import 'domain/usecases/stream_location_updates.dart';
import 'presentation/bloc/location/location_bloc.dart';

final sl = GetIt.instance;

void 
init() {
  // BLoC
  sl.registerFactory(
    () => LocationBloc(
      getCurrentLocation: sl(),
      streamLocationUpdates: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => StreamLocationUpdates(sl()));

  // Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<LocationDataSource>(
    () => LocationDataSourceImpl(),
  );
}