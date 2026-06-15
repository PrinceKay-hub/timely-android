// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:booking/data/repositories/location_repository_impl.dart';
part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationRepositoryImpl locationRepositoryImpl;
  LocationCubit({
    required this.locationRepositoryImpl,
  }
  ) : super(LocationInitial());


  Future<void> fetcLocations() async {
    // Don't emit loading if we're already loading
    if (state is LocationLoading) return;

    emit(LocationLoading());

    try {
      final location = await locationRepositoryImpl.fetchAllRegions();
      emit(LocationLoaded(location));
    } catch (e) {
      emit(LocationError('Failed to load location: ${e.toString()}'));
    }
  }
}
