
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:booking/core/services/location_service.dart';

class NavigationUtils {
  static Future<void> openDirectionsWithExplicitStart(
    double destLat,
    double destLng,
  ) async {
    Position? currentPos = await LocationService().getCurrentLocation();
    if (currentPos == null) {
      await openDirections(destLat, destLng);
      return;
    }

    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${currentPos.latitude},${currentPos.longitude}'
        '&destination=$destLat,$destLng'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }

  static Future<void> openDirections(double destLat, double destLng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=Current+Location&destination=$destLat,$destLng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps.';
    }
  }
}