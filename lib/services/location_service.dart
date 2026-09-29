import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Service for handling GPS coordinates, permissions, and reverse geocoding.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  /// Determine the current position of the device.
  /// Returns null if location services are disabled or permissions are denied.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Resolve a neighborhood or locality name using OSM Nominatim reverse geocoding.
  Future<String> getLocalityName(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'HoodlyAppCollegePrototype/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb =
              address['suburb'] ??
              address['neighbourhood'] ??
              address['quarter'] ??
              address['city_district'] ??
              address['village'] ??
              address['town'] ??
              address['suburb'];
          final city =
              address['city'] ?? address['county'] ?? address['state'] ?? '';
          if (suburb != null && city.isNotEmpty) {
            return '$suburb, $city';
          } else if (suburb != null) {
            return suburb.toString();
          }
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          return displayName.split(',').take(2).join(', ').trim();
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding via OSM: $e');
    }
    return 'Velachery, Chennai'; // Sensible prototype fallback
  }

  /// Forward geocode an address string to latitude/longitude using OSM Nominatim.
  /// Returns null if the address cannot be resolved.
  Future<({double lat, double lng})?> geocodeAddress(String address) async {
    final raw = address.trim();
    if (raw.isEmpty) return null;

    // Generate prioritized query candidates
    final candidates = <String>[];

    // 1. Direct raw string
    candidates.add(raw);

    // 2. Remove descriptive prefixes like "Inside", "Inside the", "Near", "Opposite", "Behind"
    final strippedPrefix = raw
        .replaceAll(
          RegExp(
            r'^(inside\s+(the\s+)?|near\s+|opposite\s+(to\s+)?|opp\.?\s+|behind\s+)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (strippedPrefix.isNotEmpty && strippedPrefix != raw) {
      candidates.add(strippedPrefix);
    }

    // 3. Extract parts separated by commas
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      // e.g. "CIT Chennai Campus, Sarathy Nagar, Kundrathur, Chennai" -> "CIT Chennai Campus, Sarathy Nagar, Kundrathur"
      candidates.add(parts.sublist(0, parts.length - 1).join(', '));
      // Try last 2 parts (e.g. "Kundrathur, Chennai")
      candidates.add(parts.sublist(parts.length - 2).join(', '));
    }

    final tried = <String>{};
    for (final q in candidates) {
      if (q.isEmpty || !tried.add(q)) continue;
      try {
        final queryStr = q.toLowerCase().contains('india') ? q : '$q, India';
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(queryStr)}&format=json&limit=1&countrycodes=in',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'HoodlyAppCollegePrototype/1.0'})
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final List<dynamic> results =
              json.decode(response.body) as List<dynamic>;
          if (results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final lat = double.tryParse(first['lat'] as String? ?? '');
            final lng = double.tryParse(first['lon'] as String? ?? '');
            if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
              debugPrint(
                'LocationService.geocodeAddress SUCCESS: "$q" → ($lat, $lng)',
              );
              return (lat: lat, lng: lng);
            }
          }
        }
      } catch (e) {
        debugPrint('LocationService.geocodeAddress query "$q" failed: $e');
      }
    }

    debugPrint('LocationService.geocodeAddress FAILED for: "$address"');
    return null;
  }

  /// Calculates the straight-line geographic distance in kilometers between the user's
  /// current GPS coordinates and the business's saved latitude/longitude.
  ///
  /// This intentionally uses the raw user-device GPS and business coordinates, and rejects
  /// invalid coordinate pairs before computing the distance.
  double calculateDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    try {
      final startLatNormalized = startLat.toDouble();
      final startLngNormalized = startLng.toDouble();
      final endLatNormalized = endLat.toDouble();
      final endLngNormalized = endLng.toDouble();

      final bool isValidStart = _isValidCoordinates(
        startLatNormalized,
        startLngNormalized,
      );
      final bool isValidEnd = _isValidCoordinates(
        endLatNormalized,
        endLngNormalized,
      );

      if (!isValidStart || !isValidEnd) {
        debugPrint(
          'LocationService.calculateDistanceKm rejected invalid coordinates: '
          'start=($startLatNormalized, $startLngNormalized), '
          'end=($endLatNormalized, $endLngNormalized)',
        );
        return 0.0;
      }

      const double earthRadiusKm = 6371.0;
      final startLatRad = startLatNormalized * (3.141592653589793 / 180.0);
      final startLngRad = startLngNormalized * (3.141592653589793 / 180.0);
      final endLatRad = endLatNormalized * (3.141592653589793 / 180.0);
      final endLngRad = endLngNormalized * (3.141592653589793 / 180.0);

      final latitudeDiff = endLatRad - startLatRad;
      final longitudeDiff = endLngRad - startLngRad;

      final haversine =
          math.sin(latitudeDiff / 2) * math.sin(latitudeDiff / 2) +
          math.cos(startLatRad) *
              math.cos(endLatRad) *
              math.sin(longitudeDiff / 2) *
              math.sin(longitudeDiff / 2);

      final centralAngle = 2 * math.asin(math.sqrt(haversine));
      return earthRadiusKm * centralAngle;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return 0.0;
    }
  }

  bool _isValidCoordinates(double lat, double lng) {
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
  }
}
