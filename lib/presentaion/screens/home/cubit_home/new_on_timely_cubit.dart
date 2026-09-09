
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int kNewOnTimelyLimit = 10;

abstract class NewOnTimelyState {}

class NewOnTimelyInitial extends NewOnTimelyState {}

class NewOnTimelyLoading extends NewOnTimelyState {}

class NewOnTimelyLoaded extends NewOnTimelyState {
  final List<Map<String, dynamic>> services;
  NewOnTimelyLoaded(this.services);
}

class NewOnTimelyError extends NewOnTimelyState {
  final String message;
  NewOnTimelyError([this.message = 'Could not load new providers']);
}

class NewOnTimelyCubit extends Cubit<NewOnTimelyState> {
  final ServiceRepositoryImpl serviceRepository;
 
  NewOnTimelyCubit(this.serviceRepository) : super(NewOnTimelyInitial());
 
  Future<void> loadNew() async {
    emit(NewOnTimelyLoading());
    try {
      final services = await serviceRepository.getNewServices();
      emit(NewOnTimelyLoaded(services));
    } catch (e) {
      emit(NewOnTimelyError('Could not load new providers'));
    }
  }
}
 