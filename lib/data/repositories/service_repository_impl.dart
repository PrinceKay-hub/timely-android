import 'dart:math';

import 'package:booking/core/utils/geohash_util.dart';
import 'package:booking/domain/entities/service_entity.dart';
import 'package:booking/domain/repositories/service_repository.dart';
import 'package:booking/data/models/service_model.dart';
import 'package:booking/core/network/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
  Future<String> createService(ServiceEntity service, bool isProvider) async {
    try {
      final serviceData = ServiceModel.fromEntity(service).toJson();

      // Remove id from data since Firestore will generate it
      serviceData.remove('id');

      final docRef = await _firestore.collection('services').add(serviceData);

      // Update the service with the generated ID
      await _firestore.collection('services').doc(docRef.id).update({
        'id': docRef.id,
      });

      // Log provider signup/onboarding conversion
      if (isProvider != true) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'provider_signup_complete',
          parameters: {
            'provider_id': service.providerId,
            'service_id': docRef.id,
            'method': 'app',
          },
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  @override
  Future<void> updateService(String serviceId, ServiceEntity service) async {
    try {
      final serviceData = ServiceModel.fromEntity(service).toJson();

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
  Future<List<Map<String, dynamic>>> getServicesByProvider(
    String providerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .get(); // no limit

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get provider services: $e');
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



Future<({
  List<Map<String, dynamic>> items,
  bool hasMore,
  bool wrapped,
  double? lastRandomValue,
})> getServicesPage({
  required double anchor,
  required bool wrapped,
  required double? lastRandomValue,
  int limit = 20,
}) async {
  try {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getServicesPage');
    final result = await callable.call<Map<String, dynamic>>({
      'anchor': anchor,
      'wrapped': wrapped,
      'lastRandomValue': lastRandomValue,
      'limit': limit,
    });

    final data = result.data;
    final items = (data['items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return (
      items: items,
      hasMore: data['hasMore'] as bool,
      wrapped: data['wrapped'] as bool,
      lastRandomValue: (data['lastRandomValue'] as num?)?.toDouble(),
    );
  } on FirebaseFunctionsException catch (e) {
    throw Exception('Failed to get services page: ${e.message}');
  }
}

/// Bounding-box + real-distance (Haversine) nearby search.
/// No geohash field needed — ADJUST 'latitude'/'longitude' field
/// names below if your service docs store location differently.
Future<List<Map<String, dynamic>>> getNearbyServices({
  required double latitude,
  required double longitude,
  double radiusKm = 15,
  int limit = 15,
}) async {
  try {
    final precision = GeoHashUtil.precisionForRadiusKm(radiusKm);
    final cellHashes = GeoHashUtil.neighborsAndSelf(
      latitude,
      longitude,
      precision: precision,
    );
 
    // One range query per cell. \uf8ff is a high-codepoint character
    // used as the standard Firestore "prefix range" upper bound.
    // Capped at 25/cell — generous enough to find real nearby matches
    // per cell without over-fetching, since only `limit` (15) are
    // ever shown.
    final futures = cellHashes.map((prefix) {
      return serviceCollection
          .where('status', isEqualTo: 'approved')
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThanOrEqualTo: '$prefix\uf8ff')
          .limit(25)
          .get();
    });
 
    final snapshots = await Future.wait(futures);
 
    // Merge + dedupe (a doc could theoretically show up if cell
    // boundaries overlap due to clamping/wrapping).
    final seenIds = <String>{};
    final withDistance = <MapEntry<double, Map<String, dynamic>>>[];
 
    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        if (!seenIds.add(doc.id)) continue;
        final data = doc.data() as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
 
        final distanceKm = _haversineKm(latitude, longitude, lat, lng);
        if (distanceKm <= radiusKm) {
          // Attach distance under a key that won't collide with your
          // Firestore schema, so the UI can display it.
          final withDistanceEntry = {...data, 'distanceKm': distanceKm};
          withDistance.add(MapEntry(distanceKm, withDistanceEntry));
        }
      }
    }
 
    withDistance.sort((a, b) => a.key.compareTo(b.key));
    return withDistance.take(limit).map((e) => e.value).toList();
  } catch (e) {
    throw Exception('Failed to get nearby services: $e');
  }
}
 
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}
/// Fetches a pool sorted by raw rating, then re-ranks with a
/// confidence weight so a 5.0 with 2 reviews doesn't outrank a 4.8
/// with 300 reviews. ADJUST 'rating'/'reviews' field names if needed.
Future<List<Map<String, dynamic>>> getTopRatedServices({
  int poolSize = 60,
  int limit = 15,
}) async {
  try {
    final snap = await serviceCollection
        .where('status', isEqualTo: 'approved')
        .orderBy('rating', descending: true)
        .limit(poolSize)
        .get();

    final scored = snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final reviews = (data['reviews'] as num?)?.toDouble() ?? 0.0;
      final confidence = (reviews / (reviews + 20.0)).clamp(0.0, 1.0);
      return MapEntry(rating * confidence, data);
    }).toList();

    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(limit).map((e) => e.value).toList();
  } catch (e) {
    throw Exception('Failed to get top rated services: $e');
  }
}

/// Most recently added approved services.
Future<List<Map<String, dynamic>>> getNewServices({int limit = 10}) async {
  try {
    final snap = await serviceCollection
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  } catch (e) {
    throw Exception('Failed to get new services: $e');
  }
}
}
