
import 'package:booking/core/services/send_notification.dart';
import 'package:booking/core/services/storage_service.dart';
import 'package:booking/domain/repositories/user_repository.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/domain/repositories/service_repository.dart';


class ServiceRegistrationCubit extends Cubit<ServiceRegistrationState> {
  final ServiceRepository serviceRepository;
  final UserRepository userRepository;
  final StorageService storageService;
  
  ServiceRegistrationCubit({
    required this.serviceRepository,
    required this.userRepository,
    required this.storageService,
   }) :  super(ServiceRegistrationInitial());

  
  ServiceEntity _currentService = ServiceEntity(
    id: '',
    providerId: '',
    name: '',
    description: '',
    category: '',
    location: '',
    workingDays: [],
    workingHours: const WorkingHours(
      startHour: 9,
      endHour: 17,
      startMinute: 0,
      endMinute: 0,
    ),
    durationMinutes: 60,
    createdAt: DateTime.now(),
    workers: 1, 
    services: [],
    status: 'pending',
    amenities: [],
    number: '',
    region: '',
    district: ''
  );


  

  void updateServiceName(String name) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers, 
      services: _currentService.services, 
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceDescription(String description) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceCategory(String category) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceLocation(String location) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceCoordinates(double latitude, double longitude) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: latitude,
      longitude: longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateWorkingDays(List<String> workingDays) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateWorkingHours(WorkingHours workingHours) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities,
      number: _currentService.number,  
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServicePrice(double price) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceDuration(int durationMinutes) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceImages(List<String> images) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceWorkers(int workers) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServices(List<Map<String, dynamic>> service) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: service,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateAmenities(List<String> amenities) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceNumber(String number) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: number, 
      region: _currentService.region,
      district: _currentService.district
    );
  }

  void updateServiceRegion(String region) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: region,
      district: _currentService.district
    );
  }

  void updateServiceDistrict(String district) {
    _currentService = ServiceEntity(
      id: _currentService.id,
      providerId: _currentService.providerId,
      name: _currentService.name,
      description: _currentService.description,
      category: _currentService.category,
      location: _currentService.location,
      workingDays: _currentService.workingDays,
      workingHours: _currentService.workingHours,
      durationMinutes: _currentService.durationMinutes,
      images: _currentService.images,
      rating: _currentService.rating,
      totalReviews: _currentService.totalReviews,
      createdAt: _currentService.createdAt,
      latitude: _currentService.latitude,
      longitude: _currentService.longitude,
      workers: _currentService.workers,
      services: _currentService.services,
      status: _currentService.status, 
      amenities: _currentService.amenities, 
      number: _currentService.number, 
      region: _currentService.region,
      district: district
    );
  }


  Future<void> registerService(String providerId, List<String> files) async {
    emit(ServiceRegistrationLoading());
    
    try {
      
      //final urls = await storageService.uploadMultipleServiceFiles(files.map((file) => XFile(file)).toList());
      
      final urls = await storageService.uploadMultipleImages(imageFiles: files, userId: providerId);

      // Validate service data
      if (_currentService.name.isEmpty) {
        throw Exception('Service name is required');
      }
      if (_currentService.category.isEmpty) {
        throw Exception('Category is required');
      }
      if (_currentService.location.isEmpty) {
        throw Exception('Location is required');
      }
      if (_currentService.number.isEmpty) {
        throw Exception('Service number is required');
      }
      if (_currentService.workingDays.isEmpty) {
        throw Exception('At least one working day is required');
      }
      if (_currentService.durationMinutes <= 0) {
        throw Exception('Duration must be greater than 0');
      }
      if (files.isEmpty) {
        throw Exception('At least one image is required');
      }
      
      // Create service with provider ID
      final service = ServiceEntity(
        id: '',
        providerId: providerId,
        name: _currentService.name,
        description: _currentService.description,
        category: _currentService.category,
        location: _currentService.location,
        latitude: _currentService.latitude,
        longitude: _currentService.longitude,
        workingDays: _currentService.workingDays,
        workingHours: _currentService.workingHours,
        durationMinutes: _currentService.durationMinutes,
        images: urls,
        rating: 0.0,
        totalReviews: 0,
        createdAt: DateTime.now(),
        workers: _currentService.workers, 
        services: _currentService.services,
        status: 'pending', 
        amenities: _currentService.amenities, 
        number: _currentService.number,
        region: _currentService.region,
        district: _currentService.district
        
      );
      
      final serviceId = await serviceRepository.createService(service);

      sendnotification('MPwYNw6jTPWYsvgL6dkuufYKFjx2','New Listing','Waiting for approval');

      
      // Update user's provider profile
      await userRepository.updateProviderProfile(
        providerId: providerId,
        serviceId: serviceId,
      );
      
      emit(ServiceRegistrationSuccess());
      
    } catch (e) {
      emit(ServiceRegistrationError(e.toString()));
    }
  }


  void resetForm() {
    _currentService = ServiceEntity(
      id: '',
      providerId: '',
      name: '',
      description: '',
      category: '',
      location: '',
      workingDays: [],
      workingHours: const WorkingHours(
        startHour: 9,
        endHour: 17,
        startMinute: 0,
        endMinute: 0,
      ),
      durationMinutes: 60,
      createdAt: DateTime.now(),
      workers: 1,
      services: [],
      status: '', 
      amenities: [], 
      number: '',
      region: '',
      district: ''
    );
    emit(ServiceRegistrationInitial());
  }


  Future<void> loadServiceDataById(String providerId) async {
    emit(ServiceRegistrationLoading());
    try {
      // Simulate data fetching with a delay
      final results = await serviceRepository.getServicesByProvider(providerId);
      
      emit(ServiceRegistrationDataLoaded(results));

    } catch (e) {
      emit(ServiceRegistrationError('Failed to fetch service data'));
    }
  }

  Future<void> deleteService(String serviceId) async {
    emit(ServiceRegistrationLoading());
    try {
      await serviceRepository.deleteService(serviceId);

      emit(ServiceDeletionSuccess());
    } catch (e) {
      
    }
  }

  void sendnotification(String userIDs, title, body) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc(userIDs)
        .get();

    String token = snapshot['fcmToken'];

    SendNotificationService().sendNotificationViaCloudFunction(
      title: title,
      body: body,
      deviceToken: token,
    );
  }

  ServiceEntity get currentService => _currentService;
}