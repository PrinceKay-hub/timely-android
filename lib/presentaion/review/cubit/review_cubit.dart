// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:booking/data/repositories/review_repository_impl.dart';

part 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final ReviewRepositoryImpl repositoryImpl;
  ReviewCubit({required this.repositoryImpl}) : super(ReviewInitial());

  Future<void> createReview(
    String providerId,
    String userId,
    String userName,
    double rating,
    String comment,
    String serviceId,
  ) async {
    emit(ReviewLoading());

    try {
      await repositoryImpl.submitReview(
        providerId: providerId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        serviceId: serviceId,
      );
      emit(ReviewSuccess(message: 'Review submited successful'));
    } catch (e) {
      emit(ReviewError('An error occurred: ${e.toString()}'));
    }
  }


  Future<void> fetcReviews(String providerId) async {
    // Don't emit loading if we're already loading
    if (state is ReviewLoading) return;

    emit(ReviewLoading());

    try {
      final reviews = await repositoryImpl.getReviews(providerId);
      emit(ReviewLoaded(reviews));
    } catch (e) {
      emit(ReviewError('Failed to load reviews: ${e.toString()}'));
    }
  }
}
