
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int kNearYouLimit = 15;
const double kNearYouRadiusKm = 15.0;

abstract class NearYouState {}

class NearYouInitial extends NearYouState {}

class NearYouLoading extends NearYouState {}

class NearYouLoaded extends NearYouState {
  final List<Map<String, dynamic>> services;
  NearYouLoaded(this.services);
}

class NearYouError extends NearYouState {
  final String message;
  NearYouError([this.message = 'Could not load nearby services']);
}

class NearYouUnavailable extends NearYouState {} // no location permission/fix

class NearYouCubit extends Cubit<NearYouState> {
  final ServiceRepositoryImpl serviceRepository;
 
  NearYouCubit(this.serviceRepository) : super(NearYouInitial());

    Future<void> loadNearby({
    required double? latitude,
    required double? longitude,
  }) async {
    if (latitude == null || longitude == null) {
      emit(NearYouUnavailable());
      return;
    }
 
    emit(NearYouLoading());
    try {
      final services = await serviceRepository.getNearbyServices(
        latitude: latitude,
        longitude: longitude,
      );
      emit(NearYouLoaded(services));
    } catch (e) {
      // TEMP: print the real error to console while debugging.
      // Firestore's FAILED_PRECONDITION error for a missing composite
      // index includes a direct link to auto-create it.
      debugPrint('NearYouCubit.loadNearby failed: $e');
      emit(NearYouError('Could not load nearby services'));
    }
  }
}
