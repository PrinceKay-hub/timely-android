// lib/services/provider_service_complete.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';

class SearchRepositoryImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Position? _cachedUserPosition;
  DateTime? _lastLocationUpdate;
  
  // Cache location for 5 minutes
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  Future<Position?> _getUserLocation({bool forceRefresh = false}) async {
    // Use cached location if available and recent
    if (!forceRefresh &&
        _cachedUserPosition != null &&
        _lastLocationUpdate != null &&
        DateTime.now().difference(_lastLocationUpdate!) < _locationCacheDuration) {
      return _cachedUserPosition;
    }

    try {
      // Check location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache it
      _cachedUserPosition = position;
      _lastLocationUpdate = DateTime.now();

      return position;
    } catch (e) {
      print('Error getting user location: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchProviders({
  required String query,
  String? category,
  required String region,
  String? district,
  double maxDistanceKm = 10.0,
  String sortBy = 'distance',
  int page = 1,
  int pageSize = 20,
}) async {
  try {
    final userPosition = await _getUserLocation();
    if (userPosition == null) throw Exception('Location not available');

    final function = FirebaseFunctions.instance.httpsCallable('searchProviders');
    final result = await function.call({
      'query': query,
      'region': region,
      'district': district,
      'userLat': userPosition.latitude,
      'userLng': userPosition.longitude,
      'maxDistanceKm': maxDistanceKm,
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    });

    // Safely cast the outer data map
    final data = Map<String, dynamic>.from(result.data);

    // Safely cast the providers list
    final providersList = List<dynamic>.from(data['providers'] ?? []);

    // Convert each provider map to Map<String, dynamic>
    final providers = providersList.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    return providers;
  } catch (e) {
    print('Error searching providers: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> searchByCategory({
  required String category,
  double maxDistanceKm = 10.0,
  String sortBy = 'distance',
  int page = 1,
  int pageSize = 20,
}) async {
  try {
    final userPosition = await _getUserLocation();
    if (userPosition == null) throw Exception('Location not available');

    final function = FirebaseFunctions.instance.httpsCallable('searchByCategory');
    final result = await function.call({
      'category': category,
      'userLat': userPosition.latitude,
      'userLng': userPosition.longitude,
      'maxDistanceKm': maxDistanceKm,
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    });

    // Safely cast the outer data map
    final data = Map<String, dynamic>.from(result.data);

    // Safely cast the providers list
    final providersList = List<dynamic>.from(data['providers'] ?? []);

    // Convert each provider map to Map<String, dynamic>
    final providers = providersList.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    return providers;
  } catch (e) {
    print('Error searching providers: $e');
    rethrow;
  }
}

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // Get single provider with distance from user
  Future<Map<String, dynamic>?> getProviderWithDistance(String providerId) async {
    try {
      final userPosition = await _getUserLocation();
      final doc = await _firestore.collection('providers').doc(providerId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final locationData = data['location'] as Map<String, dynamic>?;

      if (userPosition != null && locationData != null) {
        final providerLat = locationData['latitude'] as double?;
        final providerLng = locationData['longitude'] as double?;

        if (providerLat != null && providerLng != null) {
          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            providerLat,
            providerLng,
          ) / 1000;

          return {
            ...data,
            'distance': distance,
            'distanceText': _formatDistance(distance),
          };
        }
      }

      return data;
    } catch (e) {
      print('Error getting provider: $e');
      return null;
    }
  }
}

