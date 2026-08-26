// lib/presentation/home/cubit/home_state.dart
part of 'home_cubit.dart';

class HomeState extends Equatable {
  final List<Map<String, dynamic>> categories;
  
  final String? categoriesError;
  final ViewType viewType;
  final String location;
  final String? locationError;

  const HomeState({
    this.categories = const [],
    this.categoriesError,
    this.viewType = ViewType.tile,
    this.location = '',
    this.locationError,
  });

  HomeState copyWith({
    List<Map<String, dynamic>>? categories,
    String? categoriesError,
    ViewType? viewType,
    String? location,
    String? locationError,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      categoriesError: categoriesError ?? this.categoriesError,
      viewType: viewType ?? this.viewType,
      location: location ?? this.location,
      locationError: locationError ?? this.locationError,
    );
  }

  @override
  List<Object?> get props => [categories, categoriesError, viewType, location, locationError];
}