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
  List<String> _deletedImageUrls = [];

  ServiceRegistrationCubit({
    required this.serviceRepository,
    required this.userRepository,
    required this.storageService,
  }) : super(ServiceRegistrationInitial());

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
    district: '',
    landmark: '',
  );

  void _update(ServiceEntity Function(ServiceEntity) updater) {
    _currentService = updater(_currentService);
    emit(ServiceRegistrationUpdated(_currentService));
  }

  void updateServiceStatus(String status) =>
      _update((s) => s.copyWith(status: status));

  void updateServiceName(String name) =>
      _update((s) => s.copyWith(name: name));

  void updateServiceDescription(String description) =>
      _update((s) => s.copyWith(description: description));

  void updateServiceCategory(String category) =>
      _update((s) => s.copyWith(category: category));

  void updateServiceLocation(String location) =>
      _update((s) => s.copyWith(location: location));

  void updateServiceCoordinates(double latitude, double longitude) =>
      _update((s) => s.copyWith(latitude: latitude, longitude: longitude));

  void updateWorkingDays(List<String> workingDays) =>
      _update((s) => s.copyWith(workingDays: workingDays));

  void updateWorkingHours(WorkingHours workingHours) =>
      _update((s) => s.copyWith(workingHours: workingHours));

  void updateServiceDuration(int durationMinutes) =>
      _update((s) => s.copyWith(durationMinutes: durationMinutes));

  void updateServiceImages(List<String> images) =>
      _update((s) => s.copyWith(images: images));

  void updateServiceWorkers(int workers) =>
      _update((s) => s.copyWith(workers: workers));

  void updateServices(List<Map<String, dynamic>> services) =>
      _update((s) => s.copyWith(services: services));

  void updateAmenities(List<String> amenities) =>
      _update((s) => s.copyWith(amenities: amenities));

  void updateServiceNumber(String number) =>
      _update((s) => s.copyWith(number: number));

  void updateServiceRegion(String region) =>
      _update((s) => s.copyWith(region: region));

  void updateServiceDistrict(String district) =>
      _update((s) => s.copyWith(district: district));

  void updateServiceLandmark(String landmark) =>
    _update((s) => s.copyWith(landmark: landmark));
  
  Future<void> registerService(List<String> files) async {
    print('registerService called with files: $files');
    emit(ServiceRegistrationLoading());
    try {
      final urls = await storageService.uploadMultipleImages(
        imageFiles: files, userId: _currentService.providerId);

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

      final service = _currentService.copyWith(
        providerId: _currentService.providerId,
        images: urls,
        rating: 0.0,
        totalReviews: 0,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final serviceId = await serviceRepository.createService(service);

      sendnotification('MPwYNw6jTPWYsvgL6dkuufYKFjx2', 'New Listing',
          'Waiting for approval');

      await userRepository.updateProviderProfile(
        providerId: _currentService.providerId,
        serviceId: serviceId,
      );
      print('Registration success');
      emit(ServiceRegistrationSuccess());
    } catch (e) {
      print('Registration error: $e');
      emit(ServiceRegistrationError(e.toString()));
    }
  }

  Future<void> updateService(List<String> files) async {
  emit(ServiceRegistrationLoading());
  try {
    // 1. Delete marked images from storage & Firestore
    for (final url in _deletedImageUrls) {
      try {
        // This is your existing deleteImage method (from your repository or service)
        await storageService.deleteImage(url, _currentService.id);
      } catch (e) {
        // Log but continue – don't block the update if one deletion fails
        print('Failed to delete image $url: $e');
      }
    }
    _deletedImageUrls.clear();

    // 2. Upload new images
    final urls = await storageService.uploadMultipleImages(
        imageFiles: files, userId: _currentService.providerId);

    // 3. Combine remaining existing images + new uploads
    final List<String> allImages = [
      ..._currentService.images,
      ...urls,
    ];

    final updatedService = _currentService.copyWith(
      images: allImages,
    );

    // 4. Update Firestore
    await serviceRepository.updateService(_currentService.id, updatedService);

    emit(ServiceUpdateSuccess());
  } catch (e) {
    emit(ServiceRegistrationError(e.toString()));
  }
}

  void setServiceData(ServiceEntity service) {
    _currentService = service;
    emit(ServiceRegistrationUpdated(_currentService));
  }

  void markImageForDeletion(String imageUrl) {
    // Remove from current images list (UI will update)
    final updatedImages = List<String>.from(_currentService.images)
      ..remove(imageUrl);
    _currentService = _currentService.copyWith(images: updatedImages);

    // Add to deletion queue
    if (!_deletedImageUrls.contains(imageUrl)) {
      _deletedImageUrls.add(imageUrl);
    }

    emit(ServiceRegistrationUpdated(_currentService));
  }

  void clearDeletedImages() {
    _deletedImageUrls.clear();
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
      district: '',
      landmark: ''
    );
    _deletedImageUrls.clear();
    emit(ServiceRegistrationInitial());
  }

  void updateProviderId(String providerId) {
    _currentService = _currentService.copyWith(providerId: providerId);
    emit(ServiceRegistrationUpdated(_currentService));
  }

  Future<void> loadServicesByProvider(String providerId) async {
  emit(ServiceRegistrationLoading());
  try {
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
      emit(ServiceRegistrationError('Failed to delete service'));
    }
  }

  void sendnotification(String userIDs, title, body) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('admin').doc(userIDs).get();
    String token = snapshot['fcmToken'];
    SendNotificationService().sendNotificationViaCloudFunction(
      title: title,
      body: body,
      deviceToken: token,
    );
  }

  ServiceEntity get currentService => _currentService;
}