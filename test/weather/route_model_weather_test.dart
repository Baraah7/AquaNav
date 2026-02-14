import 'package:flutter_test/flutter_test.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';

void main() {
  group('RouteMetrics weather fields', () {
    test('default weather fields are null', () {
      const metrics = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
      );

      expect(metrics.weatherSafetyLevel, isNull);
      expect(metrics.weatherWarnings, isNull);
    });

    test('weather fields can be set via constructor', () {
      const metrics = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
        weatherSafetyLevel: SafetyLevel.caution,
        weatherWarnings: ['Moderate waves: 1.5m'],
      );

      expect(metrics.weatherSafetyLevel, SafetyLevel.caution);
      expect(metrics.weatherWarnings, hasLength(1));
      expect(metrics.weatherWarnings!.first, contains('waves'));
    });

    test('copyWith preserves weather fields when not overridden', () {
      const original = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
        weatherSafetyLevel: SafetyLevel.dangerous,
        weatherWarnings: ['High waves: 2.5m', 'Strong wind: 50 km/h'],
      );

      final copy = original.copyWith(landDistance: 1500);
      expect(copy.landDistance, 1500);
      expect(copy.weatherSafetyLevel, SafetyLevel.dangerous);
      expect(copy.weatherWarnings, hasLength(2));
    });

    test('copyWith can update weather fields', () {
      const original = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
        weatherSafetyLevel: SafetyLevel.caution,
        weatherWarnings: ['Moderate waves'],
      );

      final updated = original.copyWith(
        weatherSafetyLevel: SafetyLevel.blocked,
        weatherWarnings: ['Blocked: extreme waves'],
      );

      expect(updated.weatherSafetyLevel, SafetyLevel.blocked);
      expect(updated.weatherWarnings!.first, contains('Blocked'));
      // Other fields unchanged
      expect(updated.landDistance, 1000);
    });

    test('toJson includes weather fields when present', () {
      const metrics = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
        weatherSafetyLevel: SafetyLevel.dangerous,
        weatherWarnings: ['High waves: 2.5m'],
      );

      final json = metrics.toJson();
      expect(json['weather_safety_level'], SafetyLevel.dangerous.index);
      expect(json['weather_warnings'], ['High waves: 2.5m']);
    });

    test('toJson omits weather fields when null', () {
      const metrics = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
      );

      final json = metrics.toJson();
      expect(json.containsKey('weather_safety_level'), isFalse);
      expect(json.containsKey('weather_warnings'), isFalse);
    });

    test('fromJson parses weather fields correctly', () {
      final json = {
        'land_distance': 1000.0,
        'marine_distance': 2000.0,
        'land_duration': 60,
        'marine_duration': 120,
        'weather_safety_level': SafetyLevel.caution.index,
        'weather_warnings': ['Moderate waves: 1.5m'],
      };

      final metrics = RouteMetrics.fromJson(json);
      expect(metrics.weatherSafetyLevel, SafetyLevel.caution);
      expect(metrics.weatherWarnings, hasLength(1));
    });

    test('fromJson handles missing weather fields', () {
      final json = {
        'land_distance': 1000.0,
        'marine_distance': 2000.0,
        'land_duration': 60,
        'marine_duration': 120,
      };

      final metrics = RouteMetrics.fromJson(json);
      expect(metrics.weatherSafetyLevel, isNull);
      expect(metrics.weatherWarnings, isNull);
    });

    test('roundtrip toJson/fromJson preserves weather data', () {
      const original = RouteMetrics(
        landDistance: 1500,
        marineDistance: 3000,
        landDuration: 90,
        marineDuration: 180,
        weatherSafetyLevel: SafetyLevel.dangerous,
        weatherWarnings: ['High waves: 2.5m', 'Low visibility: 1500m'],
      );

      final restored = RouteMetrics.fromJson(original.toJson());
      expect(restored.weatherSafetyLevel, original.weatherSafetyLevel);
      expect(restored.weatherWarnings, original.weatherWarnings);
      expect(restored.landDistance, original.landDistance);
      expect(restored.marineDistance, original.marineDistance);
    });

    test('totalDistance and totalDuration still work with weather fields', () {
      const metrics = RouteMetrics(
        landDistance: 1000,
        marineDistance: 2000,
        landDuration: 60,
        marineDuration: 120,
        weatherSafetyLevel: SafetyLevel.blocked,
        weatherWarnings: ['Blocked'],
      );

      expect(metrics.totalDistance, 3000);
      expect(metrics.totalDuration, 180);
      expect(metrics.landPercentage, closeTo(33.33, 0.01));
      expect(metrics.marinePercentage, closeTo(66.67, 0.01));
    });
  });
}
