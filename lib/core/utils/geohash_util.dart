class GeoHashUtil {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a lat/lon into a geohash string of the given length.
  static String encode(double latitude, double longitude, {int precision = 9}) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    final buffer = StringBuffer();
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return buffer.toString();
  }

  /// Decodes a geohash into its bounding box (lat/lon min/max).
  static ({double latMin, double latMax, double lonMin, double lonMax})
      decodeBbox(String geohash) {
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    bool isEven = true;

    for (final c in geohash.split('')) {
      final idx = _base32.indexOf(c);
      if (idx == -1) continue;
      for (int n = 4; n >= 0; n--) {
        final bitN = (idx >> n) & 1;
        if (isEven) {
          final mid = (lonMin + lonMax) / 2;
          if (bitN == 1) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if (bitN == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isEven = !isEven;
      }
    }
    return (latMin: latMin, latMax: latMax, lonMin: lonMin, lonMax: lonMax);
  }

  /// Returns the geohash prefixes for the center cell plus its 8
  /// neighbors, covering a 3x3 grid around (latitude, longitude) at
  /// the given precision. Deduplicated.
  static Set<String> neighborsAndSelf(
    double latitude,
    double longitude, {
    required int precision,
  }) {
    final center = encode(latitude, longitude, precision: precision);
    final bbox = decodeBbox(center);
    final latSpan = bbox.latMax - bbox.latMin;
    final lonSpan = bbox.lonMax - bbox.lonMin;

    final hashes = <String>{};
    for (final dLat in [-1, 0, 1]) {
      for (final dLon in [-1, 0, 1]) {
        final lat = (latitude + dLat * latSpan).clamp(-90.0, 90.0);
        // Wrap longitude instead of clamping, so cells near the
        // antimeridian don't collapse onto the edge.
        var lon = longitude + dLon * lonSpan;
        if (lon > 180.0) lon -= 360.0;
        if (lon < -180.0) lon += 360.0;
        hashes.add(encode(lat, lon, precision: precision));
      }
    }
    return hashes;
  }

  /// Rough geohash precision to use for a given search radius, chosen
  /// generously (larger cells than strictly needed) since results are
  /// always re-filtered by exact Haversine distance afterward — better
  /// to over-fetch than to miss a match near a cell edge.
  static int precisionForRadiusKm(double radiusKm) {
    if (radiusKm > 630) return 2;
    if (radiusKm > 78) return 3;
    if (radiusKm > 20) return 4;
    if (radiusKm > 2.4) return 5;
    if (radiusKm > 0.61) return 6;
    return 7;
  }
}