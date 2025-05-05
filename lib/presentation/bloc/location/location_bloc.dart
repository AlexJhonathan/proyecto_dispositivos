import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_current_location.dart';
import '../../../domain/usecases/stream_location_updates.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetCurrentLocation getCurrentLocation;
  final StreamLocationUpdates streamLocationUpdates;

  StreamSubscription? _locationSubscription;

  LocationBloc({
    required this.getCurrentLocation,
    required this.streamLocationUpdates,
  }) : super(LocationInitial()) {
    on<GetCurrentLocationEvent>(_onGetCurrentLocation);
    on<StartLocationStreamEvent>(_onStartLocationStream);
    on<StopLocationStreamEvent>(_onStopLocationStream);
    on<LocationFailureEvent>((event, emit) {
      emit(LocationFailure(event.message));
    });
    on<LocationSuccessEvent>((event, emit) {
      emit(LocationSuccess(event.location));
    });
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    print('Obteniendo ubicación actual...'); // Para depuración

    try {
      final result = await getCurrentLocation();

      result.fold(
        (failure) {
          print('Error al obtener ubicación: ${failure.message}'); // Para depuración
          emit(LocationFailure(failure.message));
        },
        (location) {
          print('Ubicación obtenida: $location'); // Para depuración
          emit(LocationSuccess(location));
        },
      );
    } catch (e) {
      print('Excepción al obtener ubicación: $e'); // Para depuración
      emit(LocationFailure(e.toString()));
    }
  }

  Future<void> _onStartLocationStream(
    StartLocationStreamEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    await _locationSubscription?.cancel();

    _locationSubscription = streamLocationUpdates().listen(
      (result) {
        result.fold(
          (failure) => add(LocationFailureEvent(failure.message)),
          (location) => add(LocationSuccessEvent(location)),
        );
      },
    );
  }

  Future<void> _onStopLocationStream(
    StopLocationStreamEvent event,
    Emitter<LocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}