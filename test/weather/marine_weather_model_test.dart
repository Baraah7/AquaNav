import 'package:flutter_test/flutter_test.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';

void main() {
  group('SafetyLevel', () {
    test('has correct display names', () {
      expect(SafetyLevel.safe.displayName, 'Safe');
      expect(SafetyLevel.caution.displayName, 'Caution');
      expect(SafetyLevel.dangerous.displayName, 'Dangerous');
      expect(SafetyLevel.blocked.displayName, 'Blocked');
    });

    test('has correct descriptions', () {
      expect(SafetyLevel.safe.description, contains('safe'));
      expect(SafetyLevel.blocked.description, contains('dangerous'));
    });

    test('index ordering is safe < caution < dangerous < blocked', () {
      expect(SafetyLevel.safe.index, lessThan(SafetyLevel.caution.index));
      expect(SafetyLevel.caution.index, lessThan(SafetyLevel.dangerous.index));
      expect(SafetyLevel.dangerous.index, lessThan(SafetyLevel.blocked.index));
    });
  });

  group('MarineWeatherData', () {
    late MarineWeatherData data;

    setUp(() {
      data = MarineWeatherData(
        latitude: 26.1,
        longitude: 50.5,
        timestamp: DateTime(2026, 1, 15, 12, 0),
        waveHeight: 1.5,
        wavePeriod: 6.0,
        windWaveHeight: 0.8,
        swellWaveHeight: 0.7,
        windSpeed: 35.0,
        windGusts: 45.0,
        visibility: 8000.0,
      );
    });

    test('constructor sets all fields correctly', () {
      expect(data.latitude, 26.1);
      expect(data.longitude, 50.5);
      expect(data.waveHeight, 1.5);
      expect(data.wavePeriod, 6.0);
      expect(data.windWaveHeight, 0.8);
      expect(data.swellWaveHeight, 0.7);
      expect(data.windSpeed, 35.0);
      expect(data.windGusts, 45.0);
      expect(data.visibility, 8000.0);
    });

    test('fromJson parses correctly with string timestamp', () {
      final json = {
        'latitude': 26.1,
        'longitude': 50.5,
        'timestamp': '2026-01-15T12:00:00.000',
        'wave_height': 1.5,
        'wave_period': 6.0,
        'wind_wave_height': 0.8,
        'swell_wave_height': 0.7,
        'wind_speed': 35.0,
        'wind_gusts': 45.0,
        'visibility': 8000.0,
      };

      final parsed = MarineWeatherData.fromJson(json);
      expect(parsed.latitude, 26.1);
      expect(parsed.waveHeight, 1.5);
      expect(parsed.windSpeed, 35.0);
      expect(parsed.visibility, 8000.0);
    });

    test('fromJson parses correctly with millisecond timestamp', () {
      final ts = DateTime(2026, 1, 15).millisecondsSinceEpoch;
      final json = {
        'latitude': 26.0,
        'longitude': 50.0,
        'timestamp': ts,
        'wave_height': 0.5,
      };

      final parsed = MarineWeatherData.fromJson(json);
      expect(parsed.latitude, 26.0);
      expect(parsed.waveHeight, 0.5);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final json = {
        'latitude': 26.0,
        'longitude': 50.0,
        'timestamp': '2026-01-15T12:00:00.000',
      };

      final parsed = MarineWeatherData.fromJson(json);
      expect(parsed.waveHeight, 0.0);
      expect(parsed.wavePeriod, 0.0);
      expect(parsed.windSpeed, 0.0);
      expect(parsed.visibility, 10000.0);
    });

    test('toJson produces correct output', () {
      final json = data.toJson();
      expect(json['latitude'], 26.1);
      expect(json['longitude'], 50.5);
      expect(json['wave_height'], 1.5);
      expect(json['wind_speed'], 35.0);
      expect(json['visibility'], 8000.0);
      expect(json['timestamp'], isA<String>());
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final json = data.toJson();
      final restored = MarineWeatherData.fromJson(json);
      expect(restored.latitude, data.latitude);
      expect(restored.longitude, data.longitude);
      expect(restored.waveHeight, data.waveHeight);
      expect(restored.windSpeed, data.windSpeed);
      expect(restored.visibility, data.visibility);
    });

    test('copyWith creates modified copy', () {
      final modified = data.copyWith(waveHeight: 3.5, windSpeed: 70.0);
      expect(modified.waveHeight, 3.5);
      expect(modified.windSpeed, 70.0);
      // Unmodified fields stay the same
      expect(modified.latitude, data.latitude);
      expect(modified.visibility, data.visibility);
    });

    test('copyWith with no arguments returns identical data', () {
      final copy = data.copyWith();
      expect(copy.waveHeight, data.waveHeight);
      expect(copy.windSpeed, data.windSpeed);
      expect(copy.latitude, data.latitude);
    });

    test('toString contains key info', () {
      final str = data.toString();
      expect(str, contains('26.1'));
      expect(str, contains('50.5'));
      expect(str, contains('1.5'));
    });
  });

  group('MarineSafetyThresholds', () {
    late MarineSafetyThresholds thresholds;

    setUp(() {
      thresholds = const MarineSafetyThresholds();
    });

    MarineWeatherData makeData({
      double waveHeight = 0.0,
      double windSpeed = 0.0,
      double visibility = 10000.0,
    }) {
      return MarineWeatherData(
        latitude: 26.1,
        longitude: 50.5,
        timestamp: DateTime.now(),
        waveHeight: waveHeight,
        wavePeriod: 5.0,
        windWaveHeight: 0.0,
        swellWaveHeight: 0.0,
        windSpeed: windSpeed,
        windGusts: 0.0,
        visibility: visibility,
      );
    }

    test('safe conditions return SafetyLevel.safe', () {
      final data = makeData(waveHeight: 0.5, windSpeed: 15.0, visibility: 8000.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.safe);
      expect(result.warnings, isEmpty);
      expect(result.costMultiplier, 1.0);
    });

    // --- Wave height tests ---
    test('caution wave height returns SafetyLevel.caution', () {
      final data = makeData(waveHeight: 1.2);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.caution);
      expect(result.warnings, hasLength(1));
      expect(result.warnings.first, contains('wave'));
      expect(result.costMultiplier, 2.0);
    });

    test('dangerous wave height returns SafetyLevel.dangerous', () {
      final data = makeData(waveHeight: 2.5);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.dangerous);
      expect(result.warnings, hasLength(1));
      expect(result.costMultiplier, 5.0);
    });

    test('blocked wave height returns SafetyLevel.blocked', () {
      final data = makeData(waveHeight: 3.5);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.blocked);
      expect(result.warnings, hasLength(1));
      expect(result.costMultiplier, double.infinity);
    });

    // --- Wind speed tests ---
    test('caution wind speed returns SafetyLevel.caution', () {
      final data = makeData(windSpeed: 35.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.caution);
      expect(result.warnings.any((w) => w.toLowerCase().contains('wind')), isTrue);
    });

    test('dangerous wind speed returns SafetyLevel.dangerous', () {
      final data = makeData(windSpeed: 50.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.dangerous);
    });

    test('blocked wind speed returns SafetyLevel.blocked', () {
      final data = makeData(windSpeed: 65.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.blocked);
      expect(result.costMultiplier, double.infinity);
    });

    // --- Visibility tests ---
    test('caution visibility returns SafetyLevel.caution', () {
      final data = makeData(visibility: 4000.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.caution);
      expect(result.warnings.any((w) => w.toLowerCase().contains('visibility')), isTrue);
    });

    test('dangerous visibility returns SafetyLevel.dangerous', () {
      final data = makeData(visibility: 1500.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.dangerous);
    });

    test('blocked visibility returns SafetyLevel.blocked', () {
      final data = makeData(visibility: 300.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.blocked);
    });

    // --- Combined conditions ---
    test('worst level wins when multiple conditions are bad', () {
      // Caution waves + dangerous wind → dangerous
      final data = makeData(waveHeight: 1.2, windSpeed: 50.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.dangerous);
      expect(result.warnings, hasLength(2));
    });

    test('blocked overrides everything', () {
      // Caution waves + blocked wind → blocked
      final data = makeData(waveHeight: 1.2, windSpeed: 65.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.blocked);
      expect(result.costMultiplier, double.infinity);
    });

    test('all three conditions generate three warnings', () {
      final data = makeData(waveHeight: 1.5, windSpeed: 35.0, visibility: 4000.0);
      final result = thresholds.evaluate(data);
      expect(result.warnings, hasLength(3));
    });

    test('assessment contains source data', () {
      final data = makeData(waveHeight: 2.5);
      final result = thresholds.evaluate(data);
      expect(result.data.waveHeight, 2.5);
      expect(result.data.latitude, 26.1);
    });

    // --- Boundary value tests ---
    test('exactly at caution threshold is caution', () {
      final data = makeData(waveHeight: 1.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.caution);
    });

    test('just below caution threshold is safe', () {
      final data = makeData(waveHeight: 0.99);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.safe);
    });

    test('exactly at blocked threshold is blocked', () {
      final data = makeData(waveHeight: 3.0);
      final result = thresholds.evaluate(data);
      expect(result.level, SafetyLevel.blocked);
    });

    // --- Custom thresholds ---
    test('custom thresholds are respected', () {
      final custom = MarineSafetyThresholds(
        waveHeightCaution: 0.5,
        waveHeightDangerous: 1.0,
        waveHeightBlocked: 1.5,
      );
      final data = makeData(waveHeight: 0.6);
      final result = custom.evaluate(data);
      expect(result.level, SafetyLevel.caution);
    });
  });

  group('WeatherSafetyAssessment', () {
    test('toString contains level and warnings', () {
      final assessment = WeatherSafetyAssessment(
        level: SafetyLevel.dangerous,
        costMultiplier: 5.0,
        warnings: ['High waves: 2.5m'],
        data: MarineWeatherData(
          latitude: 26.1,
          longitude: 50.5,
          timestamp: DateTime.now(),
          waveHeight: 2.5,
          wavePeriod: 5.0,
          windWaveHeight: 0.0,
          swellWaveHeight: 0.0,
          windSpeed: 0.0,
          windGusts: 0.0,
          visibility: 10000.0,
        ),
      );
      final str = assessment.toString();
      expect(str, contains('Dangerous'));
      expect(str, contains('5.0'));
    });
  });
}
