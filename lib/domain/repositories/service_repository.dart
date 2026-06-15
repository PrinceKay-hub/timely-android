import 'package:booking/domain/entities/service_entity.dart';

abstract class ServiceRepository {
  Future<String> createService(ServiceEntity service);
  
  Future<void> updateService(String serviceId, Map<String, dynamic>  service);
  
  Future<void> deleteService(String serviceId);
  
  Future<Map<String, dynamic>> getServiceById(String serviceId);

  Future<void> deleteImage(String serviceId, Map<String, dynamic> service);
  
  Future<Map<String, dynamic>?>  getServicesByProvider(String providerId);
  
  Future<List>getAllServices();
  
  Future<List<ServiceEntity>> getServicesByCategory(String category);
  
  Future<List<ServiceEntity>> getFeaturedServices();
}