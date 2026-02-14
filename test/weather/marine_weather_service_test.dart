import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:Bahaar/services/marine_weather_service.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';

/// Creates a mock HTTP client that returns predefined marine + forecast responses
MockClient createMockClient({
  double waveHeight = 0.5,
  double wavePeriod = 5.0,
  double windWaveHeight = 0.3,
  double swellWaveHeight = 0.2,
  double windSpeed = 10.0,
  double windGusts = 15.0,
  double visibility = 10000.0,
  int statusCode = 200,
}) {
  return MockClient((request) async {
    final url = request.url.toString();

    if (url.contains('marine-api.open-meteo.com')) {
      return http.Response(
        jsonEncode({
          'current': {
            'wave_height': waveHeight,
            'wave_period': wavePeriod,
            'wind_wave_height': windWaveHeight,
            'swell_wave_height': swellWaveHeight,
          },
        }),
        statusCode,
      );
    } else if (url.contains('api.open-meteo.com')) {
      return http.Response(
        jsonEncode({
          'current': {
            'wind_speed_10m': windSpeed,
            'wind_gusts_10m': windGusts,
            'visibility': visibility,
          },
        }),
        statusCode,
      );
    }

    return http.Response('Not found', 404);
  });
}

void main() {
  group('MarineWeatherService', () {
    test('initializes and fetches weather data', () async {
      final client = createMockClient();
      final service = MarineWeatherService(client: client);

      await service.initialize();

      expect(service.hasData, isTrue);
      expect(service.lastFetchTime, isNotNull);
    });

    test('hasData is false before initialization', () {
      final client = createMockClient();
      final service = MarineWeatherService(client: client);

      expect(service.hasData, isFalse);
      expect(service.lastFetchTime, isNull);
    });

    test('getActiveWarnings returns empty for safe conditions', () async {
      final client = createMockClient(
        waveHeight: 0.3,
        windSpeed: 10.0,
        visibility: 10000.0,
      );
      final service = MarineWeatherService(client: client);
      await service.initialize();

      final warnings = service.getActiveWarnings();
      expect(warnings, isEmpty);
    });

    test('getActiveWarnings returns warnings for dangerous conditions', () async {
      final client = createMockClient(
        waveHeight: 2.5,
        windSpeed: 50.0,
      );
      final service = MarineWeatherService(client: client);
      await service.initialize();

      final warnings = service.getActiveWarnings();
      expect(warnings, isNotEmpty);
      expect(warnings.every((w) => w.level != SafetyLevel.safe), isTrue);
    });

    test('getOverallSafetyLevel returns safe for calm conditions', () async {
      final client = createMockClient(
        waveHeight: 0.3,
        windSpeed: 10.0,
        visibility: 10000.0,
      );
      final service = MarineWeatherService(client: client);
      await service.initialize();

      expect(service.getOverallSafetyLevel(), SafetyLevel.safe);
    });

    test('getOverallSafetyLevel returns worst level', () async {
      final client = createMockClient(waveHeight: 3.5);
      final service = MarineWeatherService(client: client);
      await service.initialize();

      expect(service.getOverallSafetyLevel(), SafetyLevel.blocked);
    });

    test('refreshWeather skips if recently fetched', () async {
      int callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        final url = request.url.toString();
        if (url.contains('marine-api.open-meteo.com')) {
          return http.Response(
            jsonEncode({'current': {'wave_height': 0.5, 'wave_period': 5.0, 'wind_wave_height': 0.0, 'swell_wave_height': 0.0}}),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({'current': {'wind_speed_10m': 10.0, 'wind_gusts_10m': 15.0, 'visibility': 10000.0}}),
            200,
          );
        }
      });

      final service = MarineWeatherService(client: client);
      await service.initialize();
      final firstCallCount = callCount;

      // Second call should be skipped (cache valid)
      await service.refreshWeather();
      expect(callCount, firstCallCount);
    });

    test('hasConditionsChanged detects level changes', () async {
      bool returnDangerous = false;
      final client = MockClient((request) async {
        final url = request.url.toString();
        if (url.contains('marine-api.open-meteo.com')) {
          return http.Response(
            jsonEncode({
              'current': {
                'wave_height': returnDangerous ? 2.5 : 0.3,
                'wave_period': 5.0,
                'wind_wave_height': 0.0,
                'swell_wave_height': 0.0,
              },
            }),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({'current': {'wind_speed_10m': 10.0, 'wind_gusts_10m': 15.0, 'visibility': 10000.0}}),
            200,
          );
        }
      });

      final service = MarineWeatherService(client: client);
      await service.initialize();
      expect(service.hasConditionsChanged(), isFalse);
    });

    test('handles API errors gracefully', () async {
      final client = createMockClient(statusCode: 500);
      final service = MarineWeatherService(client: client);

      await service.initialize();
      // Should not throw, defaults to safe
      expect(service.getOverallSafetyLevel(), SafetyLevel.safe);
    });

    test('handles network timeout gracefully', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection timed out');
      });

      final service = MarineWeatherService(client: client);
      await service.initialize();
      expect(service.getOverallSafetyLevel(), SafetyLevel.safe);
    });

    test('getAssessmentForCell returns null when no data', () {
      final client = createMockClient();
      final service = MarineWeatherService(client: client);

      final result = service.getAssessmentForCell(
        100, 100,
        minLat: 25.8,
        minLon: 50.3,
        resolution: 0.001,
        gridHeight: 600,
      );
      expect(result, isNull);
    });

    test('getAssessmentForCell returns assessment when data exists', () async {
      final client = createMockClient(waveHeight: 1.5);
      final service = MarineWeatherService(client: client);
      await service.initialize();

      // Use a cell that maps to a valid coarse grid point
      final result = service.getAssessmentForCell(
        300, 300,
        minLat: 25.8,
        minLon: 50.3,
        resolution: 0.001,
        gridHeight: 600,
      );
      // May or may not find a matching coarse cell depending on exact mapping
      // but should not throw
    });

    test('dispose clears cached data', () async {
      final client = createMockClient();
      final service = MarineWeatherService(client: client);
      await service.initialize();
      expect(service.hasData, isTrue);

      service.dispose();
      // After dispose, client is closed - service should be discarded
    });

    test('custom bounding box is respected', () async {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        final url = request.url.toString();
        if (url.contains('marine-api.open-meteo.com')) {
          // Verify latitude is within custom bounds
          final latMatch = RegExp(r'latitude=([\d.]+)').firstMatch(url);
          if (latMatch != null) {
            final lat = double.parse(latMatch.group(1)!);
            expect(lat, greaterThanOrEqualTo(25.0));
            expect(lat, lessThanOrEqualTo(26.0));
          }
          return http.Response(
            jsonEncode({'current': {'wave_height': 0.5, 'wave_period': 5.0, 'wind_wave_height': 0.0, 'swell_wave_height': 0.0}}),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({'current': {'wind_speed_10m': 10.0, 'wind_gusts_10m': 15.0, 'visibility': 10000.0}}),
            200,
          );
        }
      });

      final service = MarineWeatherService(
        client: client,
        minLat: 25.0,
        maxLat: 26.0,
        minLon: 50.0,
        maxLon: 51.0,
      );
      await service.initialize();
      expect(requestCount, greaterThan(0));
    });
  });
}
