import 'dart:convert';
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
      final response = await http.get(url, headers: {
        'User-Agent': 'HoodlyAppCollegePrototype/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb = address['suburb'] ??
              address['neighbourhood'] ??
              address['quarter'] ??
              address['city_district'] ??
              address['village'] ??
              address['town'] ??
              address['suburb'];
          final city = address['city'] ?? address['county'] ?? address['state'] ?? '';
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

  /// Calculates the distance in kilometers between two coordinates.
  double calculateDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    try {
      final double distanceInMeters = Geolocator.distanceBetween(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      return distanceInMeters / 1000.0;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return 0.0;
    }
  }
}
