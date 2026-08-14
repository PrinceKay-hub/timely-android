// lib/repositories/search_repository_impl.dart
import 'package:booking/core/utils/error_mapper.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import '../models/search_response.dart';

class SearchRepositoryImpl {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Position? _cachedUserPosition;
  DateTime? _lastLocationUpdate;
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  // ─── Location helpers ───────────────────────────────────────────────────

  Future<Position> _getUserLocation({bool forceRefresh = false}) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedUserPosition != null &&
        _lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!) < _locationCacheDuration) {
      return _cachedUserPosition!;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const LocationPermissionDenied();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedForever();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _cachedUserPosition = position;
      _lastLocationUpdate = now;
      return position;
    } catch (e) {
      throw mapLocationError(e);
    }
  }

  // ─── Search methods ─────────────────────────────────────────────────────

  Future<SearchResponse> searchProviders({
    required String query,
    required String region,
    String? district,
    double maxDistanceKm = 10,
    String sortBy = 'distance',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final position = await _getUserLocation();

      final callable = _functions.httpsCallable('searchProviders');
      final result = await callable.call({
        'query': query,
        'region': region,
        'district': district,
        'userLat': position.latitude,
        'userLng': position.longitude,
        'maxDistanceKm': maxDistanceKm,
        'sortBy': sortBy,
        'page': page,
        'pageSize': pageSize,
      });

      return SearchResponse.fromMap(result.data as Map<String, dynamic>);
    } catch (e) {
      throw mapSearchError(e);
    }
  }

  Future<SearchResponse> searchByCategory({
    required String category,
    double maxDistanceKm = 10,
    String sortBy = 'distance',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final position = await _getUserLocation();

      final callable = _functions.httpsCallable('searchByCategory');
      final result = await callable.call({
        'category': category,
        'userLat': position.latitude,
        'userLng': position.longitude,
        'maxDistanceKm': maxDistanceKm,
        'sortBy': sortBy,
        'page': page,
        'pageSize': pageSize,
      });

      return SearchResponse.fromMap(result.data as Map<String, dynamic>);
    } catch (e) {
      throw mapSearchError(e);
    }
  }

  void clearLocationCache() {
    _cachedUserPosition = null;
    _lastLocationUpdate = null;
  }
}