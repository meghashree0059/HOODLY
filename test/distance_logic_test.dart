import 'package:flutter_test/flutter_test.dart';
import 'package:hoodly/services/location_service.dart';

void main() {
  test(
    'business-to-user distance uses the actual saved coordinates and stays in a realistic range',
    () {
      const userLat = 13.0685;
      const userLng = 80.2203;
      const businessLat = 13.0834;
      const businessLng = 80.2389;

      final distanceKm = LocationService.instance.calculateDistanceKm(
        userLat,
        userLng,
        businessLat,
        businessLng,
      );

      expect(distanceKm, inExclusiveRange(0.0, 20.0));
      expect(distanceKm, greaterThan(1.0));
      expect(distanceKm, lessThan(10.0));
    },
  );
}
