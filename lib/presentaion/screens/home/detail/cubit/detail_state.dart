// detail_state.dart

import 'package:equatable/equatable.dart';

class DetailState extends Equatable {
  final int currentImageIndex;
  final bool isLoadingDirections;

  const DetailState({
    this.currentImageIndex = 0,
    this.isLoadingDirections = false,
  });

  DetailState copyWith({
    int? currentImageIndex,
    bool? isLoadingDirections,
  }) {
    return DetailState(
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      isLoadingDirections: isLoadingDirections ?? this.isLoadingDirections,
    );
  }

  @override
  List<Object> get props => [currentImageIndex, isLoadingDirections];
}