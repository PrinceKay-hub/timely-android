import 'package:bloc/bloc.dart';
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:equatable/equatable.dart';

part 'service_detail_state.dart';

class ServiceDetailCubit extends Cubit<ServiceDetailState> {
  final ServiceRepositoryImpl serviceRepository;
  ServiceDetailCubit(this.serviceRepository) : super(ServiceDetailInitial());


  Future<void> getServiceById(String serviceId) async {
    emit(ServiceDetailLoading());
    try {
      final  data = await serviceRepository.getServiceById(serviceId);

      emit(ServiceDetailLoaded(data));

    } catch (e) {
      emit(ServiceDetailError('Failed to get service data'));
    }
  }
}
