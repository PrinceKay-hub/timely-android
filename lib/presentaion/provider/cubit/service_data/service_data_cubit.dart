import 'package:bloc/bloc.dart';
import 'package:booking/core/services/storage_service.dart';
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:equatable/equatable.dart';

part 'service_data_state.dart';

class ServiceDataCubit extends Cubit<ServiceDataState> {
  final ServiceRepositoryImpl serviceRepository;
  final StorageService storageService = StorageService();

  ServiceDataCubit(this.serviceRepository) : super(ServiceDataInitial());



  Future<void> fetchServiceData() async {
    emit(ServiceDataLoading());
    try {
      // Simulate data fetching with a delay
      final results = await serviceRepository.getAllServices();
      
      emit(ServiceDataLoaded(results));

    } catch (e) {
      emit(ServiceDataError('Failed to fetch service data'));
    }
  }

  Future<void> updateServiceData(String serviceId, Map<String, dynamic> service) async {
   emit(ServiceDataLoading()); 
   try { 
   
    // Simulate data fetching with a delay 
    await serviceRepository.updateService(serviceId, service); 

    emit(ServiceDataUpdateSuccess()); 
  } catch (e) { 
    emit(ServiceDataError('Failed to update service data')); }
  
  }

  Future<void> deleteServiceImage(String imageUrl, String serviceId) async {
    emit(ServiceDataLoading());
    try {
       await storageService.deleteImage(imageUrl, serviceId);

      emit(ServiceDataUpdateSuccess());
     
    } catch (e) {
      emit(ServiceDataError('Failed to delete service data'));
    }
  }

  
}
