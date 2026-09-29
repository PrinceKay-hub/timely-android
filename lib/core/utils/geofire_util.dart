import 'dart:math';

const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
const _bitsPerChar = 5;
const _metersPerDegreeLat = 110574.0;
const _earthMeridionalCircumference = 40007860.0;
const _maxBitsPrecision = 22 * _bitsPerChar;
const _earthEqRadius = 6378137.0;
const _e2 = 0.00669447819799;
const _epsilon = 1e-12;

double _log2(num x) => log(x) / ln2;
double _rad(double deg) => deg * pi / 180;

/// Same encoding geofire-common uses (10 chars by default).
String geohashForLocation(double lat, double lng, {int precision = 10}) {
  var latMin = -90.0, latMax = 90.0;
  var lonMin = -180.0, lonMax = 180.0;
  final sb = StringBuffer();
  var isLon = true;
  var bits = 0;
  var ch = 0;

  while (sb.length < precision) {
    if (isLon) {
      final mid = (lonMin + lonMax) / 2;
      if (lng > mid) {
        ch = (ch << 1) + 1;
        lonMin = mid;
      } else {
        ch = ch << 1;
        lonMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (lat > mid) {
        ch = (ch << 1) + 1;
        latMin = mid;
      } else {
        ch = ch << 1;
        latMax = mid;
      }
    }
    isLon = !isLon;
    if (++bits == _bitsPerChar) {
      sb.write(_base32[ch]);
      bits = 0;
      ch = 0;
    }
  }
  return sb.toString();
}

double _metersToLongitudeDegrees(double distance, double latitude) {
  final radians = _rad(latitude);
  final num = cos(radians) * _earthEqRadius * pi / 180;
  final denom = 1 / sqrt(1 - _e2 * sin(radians) * sin(radians));
  final deltaDeg = num * denom;
  if (deltaDeg < _epsilon) return distance > 0 ? 360 : 0;
  return min(360, distance / deltaDeg);
}

double _longitudeBitsForResolution(double resolution, double latitude) {
  final degs = _metersToLongitudeDegrees(resolution, latitude);
  return degs.abs() > 0.000001 ? max(1.0, _log2(360 / degs)) : 1.0;
}

double _latitudeBitsForResolution(double resolution) => min(
      _log2(_earthMeridionalCircumference / 2 / resolution),
      _maxBitsPrecision.toDouble(),
    );

double _wrapLongitude(double lon) {
  if (lon <= 180 && lon >= -180) return lon;
  return ((lon + 180) % 360) - 180; // Dart's % is non-negative here
}

int _boundingBoxBits(double lat, double size) {
  final latDelta = size / _metersPerDegreeLat;
  final north = min(90.0, lat + latDelta);
  final south = max(-90.0, lat - latDelta);
  final bitsLat = _latitudeBitsForResolution(size).floor() * 2;
  final bitsLonN = _longitudeBitsForResolution(size, north).floor() * 2 - 1;
  final bitsLonS = _longitudeBitsForResolution(size, south).floor() * 2 - 1;
  return min(min(bitsLat, bitsLonN), min(bitsLonS, _maxBitsPrecision));
}

List<List<double>> _boundingBoxCoordinates(double lat, double lng, double radius) {
  final latDeg = radius / _metersPerDegreeLat;
  final north = min(90.0, lat + latDeg);
  final south = max(-90.0, lat - latDeg);
  final lonDeg = max(
    _metersToLongitudeDegrees(radius, north),
    _metersToLongitudeDegrees(radius, south),
  );
  final west = _wrapLongitude(lng - lonDeg);
  final east = _wrapLongitude(lng + lonDeg);
  return [
    [lat, lng], [lat, west], [lat, east],
    [north, lng], [north, west], [north, east],
    [south, lng], [south, west], [south, east],
  ];
}

(String, String) _geohashQuery(String geohash, int bits) {
  final precision = (bits / _bitsPerChar).ceil();
  if (geohash.length < precision) return (geohash, geohash);
  final hash = geohash.substring(0, precision);
  final base = hash.substring(0, hash.length - 1);
  final lastValue = _base32.indexOf(hash[hash.length - 1]);
  final significantBits = bits - base.length * _bitsPerChar;
  final unusedBits = _bitsPerChar - significantBits;
  final startValue = (lastValue >> unusedBits) << unusedBits;
  final endValue = startValue + (1 << unusedBits);
  return endValue > 31
      ? ('$base${_base32[startValue]}', '$base~')
      : ('$base${_base32[startValue]}', '$base${_base32[endValue]}');
}

/// Geohash [start, end] ranges covering a circle of [radiusMeters].
List<(String, String)> geohashQueryBounds(
  double lat,
  double lng,
  double radiusMeters,
) {
  final queryBits = max(1, _boundingBoxBits(lat, radiusMeters));
  final precision = (queryBits / _bitsPerChar).ceil();

  final seen = <String>{};
  final bounds = <(String, String)>[];
  for (final c in _boundingBoxCoordinates(lat, lng, radiusMeters)) {
    final q = _geohashQuery(
      geohashForLocation(c[0], c[1], precision: precision),
      queryBits,
    );
    if (seen.add('${q.$1}|${q.$2}')) bounds.add(q);
  }
  return bounds;
}