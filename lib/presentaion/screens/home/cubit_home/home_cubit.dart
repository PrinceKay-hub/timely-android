// lib/presentation/home/cubit/home_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:booking/data/repositories/category_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:booking/core/services/location_service.dart';

part 'home_state.dart';

enum ViewType { grid, list, tile }

class HomeCubit extends Cubit<HomeState> {
  final CategoryRepository categoryRepository;
  final LocationService locationService;

  HomeCubit({
    required this.categoryRepository,
    required this.locationService,
  }) : super(const HomeState());

  Future<void> loadCategories() async {
    try {
      final categories = await categoryRepository.fetchCategories();
      emit(state.copyWith(categories: categories));
    } catch (e) {
      // Optionally emit an error state
      emit(state.copyWith(categoriesError: e.toString()));
    }
  }

  void setViewType(ViewType viewType) {
    if (state.viewType != viewType) {
      emit(state.copyWith(viewType: viewType));
    }
  }

  void setLocation(String location) {
    emit(state.copyWith(location: location));
  }

  Future<void> updateLocation() async {
  try {
    final position = await locationService.getCurrentLocation();
    if (position != null) {
      setLocation('${position.latitude},${position.longitude}');
    }
  } catch (e) {
    emit(state.copyWith(locationError: e.toString()));
  }
}
}