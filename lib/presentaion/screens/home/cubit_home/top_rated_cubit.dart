
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int kTopRatedPoolSize = 60; // fetch a pool, then re-rank
const int kTopRatedLimit = 15;
const double kMinReviewsForFullWeight = 20.0; // tune to your data

abstract class TopRatedState {}

class TopRatedInitial extends TopRatedState {}

class TopRatedLoading extends TopRatedState {}

class TopRatedLoaded extends TopRatedState {
  final List<Map<String, dynamic>> services;
  TopRatedLoaded(this.services);
}

class TopRatedError extends TopRatedState {
  final String message;
  TopRatedError([this.message = 'Could not load top rated services']);
}

class TopRatedCubit extends Cubit<TopRatedState> {
  final ServiceRepositoryImpl serviceRepository;
 
  TopRatedCubit(this.serviceRepository) : super(TopRatedInitial());
 
  Future<void> loadTopRated() async {
    emit(TopRatedLoading());
    try {
      final services = await serviceRepository.getTopRatedServices();
      emit(TopRatedLoaded(services));
    } catch (e) {
      emit(TopRatedError('Could not load top rated services'));
    }
  }
}