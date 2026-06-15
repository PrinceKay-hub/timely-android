part of 'review_cubit.dart';

sealed class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object> get props => [];
}

final class ReviewInitial extends ReviewState {}

final class ReviewLoading extends ReviewState {}

final class ReviewLoaded extends ReviewState {
  final List reviews;

  const ReviewLoaded(this.reviews);

  @override
  List<Object> get props => [reviews];
}

final class ReviewSuccess extends ReviewState {
  final String message;

  const ReviewSuccess({required this.message});

  @override
  List<Object> get props => [ message];
}

final class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object> get props => [message];
}
