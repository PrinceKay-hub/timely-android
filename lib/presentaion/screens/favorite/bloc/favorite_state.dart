import 'package:equatable/equatable.dart';

class FavoriteState extends Equatable {
  final Set<String> favoriteIds;
  final List<Map<String, dynamic>> favoriteItems; // full details
  final bool isLoading;

  const FavoriteState({
    required this.favoriteIds,
    required this.favoriteItems,
    required this.isLoading,
  });

  factory FavoriteState.initial() => const FavoriteState(
        favoriteIds: {},
        favoriteItems: [],
        isLoading: true,
      );

  FavoriteState copyWith({
    Set<String>? favoriteIds,
    List<Map<String, dynamic>>? favoriteItems,
    bool? isLoading,
  }) {
    return FavoriteState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [favoriteIds, favoriteItems, isLoading];
}