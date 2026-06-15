import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/domain/repositories/service_repository.dart';
import 'package:booking/data/models/service_model.dart';
import 'package:booking/core/network/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ServiceRepositoryImpl extends ServiceRepository {
  final FirebaseService firebaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference serviceCollection = FirebaseFirestore.instance
      .collection("services");
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ServiceRepositoryImpl({FirebaseService? firebaseService})
    : firebaseService = firebaseService ?? FirebaseService();

  @override
  Future<String> createService(ServiceEntity service) async {
    try {
      final serviceData = ServiceModel.fromEntity(service).toJson();

      // Remove id from data since Firestore will generate it
      serviceData.remove('id');

      final docRef = await _firestore.collection('services').add(serviceData);

      // Update the service with the generated ID
      await _firestore.collection('services').doc(docRef.id).update({
        'id': docRef.id,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  @override
  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> service,
  ) async {
    try {
      final serviceData = service;

      await _firestore
          .collection('services')
          .doc(serviceId)
          .update(serviceData);
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  @override
  Future<void> deleteService(String serviceId) async {
    try {
      // 1. Get the service document to retrieve image URLs
      final DocumentSnapshot doc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();

      if (!doc.exists) {
        print('Service document $serviceId does not exist.');
        return;
      }

      // Assuming the image URLs are stored in a field called 'imageUrls' (List<String>)
      final List<dynamic> imageUrls = doc.get('images') ?? [];

      // 2. Delete each image from Storage
      for (final String url in imageUrls) {
        try {
          final Reference ref = _storage.refFromURL(url);
          await ref.delete();
          print('Deleted image: $url');
        } catch (e) {
          // Log individual image deletion error but continue with others
          print('Error deleting image $url: $e');
        }
      }

      // 3. Delete the Firestore document
      await _firestore.collection('services').doc(serviceId).delete();
      print('Service document $serviceId deleted.');
    } catch (e) {
      // Catch any unexpected error (e.g., failed to fetch document)
      print('Error in deleteService: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();

      if (!doc.exists) {
        throw Exception('Service not found');
      }

      final serviceData = doc.data()!;
      serviceData['id'] = doc.id;

      return serviceData;
    } catch (e) {
      throw Exception('Failed to get service: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getServicesByProvider(String providerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .limit(1) // ensure we only fetch one document
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // or throw a custom exception if you prefer
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id; // add document ID to the map
      return data;
    } catch (e) {
      throw Exception('Failed to get provider service: $e');
    }
  }


  @override
  Future<List> getAllServices() async {
    List<Map<dynamic, dynamic>> servicetList = [];
    List item = [];
    try {
      await serviceCollection
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .then((value) {
            servicetList = value.docs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList();
            if (servicetList.isNotEmpty) {
              for (var l in servicetList) {
                item.add(l);
              }
            }
          });
      return item;
    } catch (e) {
      throw Exception('Failed to get all services: $e');
    }
  }

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .orderBy('rating', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Failed to get services by category: $e');
    }
  }

  @override
  Future<List<ServiceEntity>> getFeaturedServices() async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('rating', isGreaterThanOrEqualTo: 4.0)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data).toEntity();
      }).toList();
    } catch (e) {
      throw Exception('Failed to get featured services: $e');
    }
  }

  @override
  Future<void> deleteImage(
    String serviceId,
    Map<String, dynamic> service,
  ) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        'images': FieldValue.arrayRemove(service['images']),
      });
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }
}
