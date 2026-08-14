// lib/utils/error_mapper.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import '../exceptions/app_exception.dart';

/// Converts any error thrown during a search call into a friendly AppException.
AppException mapSearchError(Object error) {
  if (error is AppException) return error; // already friendly

  if (error is FirebaseFunctionsException) {
    return AppException(_messageForFunctionsCode(error.code),
        code: error.code, cause: error);
  }

  if (error is SocketException) {
    return AppException(
      "You're offline. Check your connection and try again.",
      code: 'network-error',
      cause: error,
    );
  }

  return const AppException(
    "Something went wrong. Please try again.",
    code: 'unknown',
  );
}

String _messageForFunctionsCode(String code) {
  switch (code) {
    case 'invalid-argument':
      return "We couldn't understand that search. Please try adjusting your filters.";
    case 'unauthenticated':
      return "Please sign in to search for services.";
    case 'permission-denied':
      return "You don't have permission to do that.";
    case 'resource-exhausted':
      return "You're searching a bit too fast. Please wait a moment and try again.";
    case 'unavailable':
      return "You're offline. Check your connection and try again.";
    case 'deadline-exceeded':
      return "That's taking longer than expected. Please try again.";
    case 'internal':
    default:
      return "We couldn't complete your search right now. Please try again.";
  }
}

/// Converts location-related errors into friendly AppExceptions.
AppException mapLocationError(Object error) {
  if (error is AppException) return error;

  if (error is LocationServiceDisabledException) {
    return const AppException(
      "Turn on location services to find providers near you.",
      code: 'location-service-disabled',
    );
  }

  // Our own permission signals thrown below use these codes.
  if (error is _LocationPermissionDenied) {
    return AppException(error.message, code: error.code, cause: error);
  }

  if (error is TimeoutException) {
    return const AppException(
      "We couldn't get your location in time. Please try again.",
      code: 'location-timeout',
    );
  }

  return const AppException(
    "We couldn't get your location. Please try again.",
    code: 'location-unknown',
  );
}

/// Internal marker exceptions so mapLocationError can give tailored copy.
class _LocationPermissionDenied implements Exception {
  final String message;
  final String code;
  const _LocationPermissionDenied(this.message, this.code);
}

class LocationPermissionDenied extends _LocationPermissionDenied {
  const LocationPermissionDenied()
      : super(
          "Location access is needed to search nearby. Please allow it and try again.",
          'location-permission-denied',
        );
}

class LocationPermissionDeniedForever extends _LocationPermissionDenied {
  const LocationPermissionDeniedForever()
      : super(
          "Location access is turned off for this app. Enable it in your device settings to search nearby.",
          'location-permission-denied-forever',
        );
}