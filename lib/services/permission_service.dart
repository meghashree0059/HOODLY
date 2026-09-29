import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Real Android permission service.
///
/// Uses the Android OS directly for all permission checks and requests.
/// Does NOT store any permission state in SharedPreferences.
/// Does NOT show fake Flutter dialogs — the real Android system dialog
/// is shown by [Geolocator.requestPermission()].
///
/// For photos: [image_picker]'s pickImage() triggers the real Android
/// OS media permission dialog natively — no extra work needed here.
class PermissionService {
  static final PermissionService instance = PermissionService._();
  PermissionService._();

  /// Returns the current location permission status directly from the Android OS.
  Future<LocationPermission> getLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('PermissionService.getLocationPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Requests location permission — triggers the real Android system dialog.
  /// Should only be called when permission is [LocationPermission.denied].
  Future<LocationPermission> requestLocationPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      debugPrint('PermissionService.requestLocationPermission error: $e');
      return LocationPermission.denied;
    }
  }

  /// Returns true if location access is usable (whileInUse or always).
  Future<bool> isLocationGranted() async {
    final perm = await getLocationPermission();
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  /// Opens the Android App Settings page for this app.
  /// Use this when permission is [LocationPermission.deniedForever].
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('PermissionService.openAppSettings error: $e');
    }
  }
}
