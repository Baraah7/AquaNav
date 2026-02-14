import 'package:flutter_test/flutter_test.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

void main() {
  group('NavigationConstants - Weather & Safety', () {
    test('Open-Meteo API URLs are valid HTTPS URLs', () {
      expect(
        NavigationConstants.openMeteoMarineBaseUrl,
        startsWith('https://'),
      );
      expect(
        NavigationConstants.openMeteoForecastBaseUrl,
        startsWith('https://'),
      );
      expect(
        NavigationConstants.openMeteoMarineBaseUrl,
        contains('marine'),
      );
    });

    test('weather refresh interval is reasonable (5-60 minutes)', () {
      expect(
        NavigationConstants.weatherRefreshIntervalSeconds,
        greaterThanOrEqualTo(300), // at least 5 min
      );
      expect(
        NavigationConstants.weatherRefreshIntervalSeconds,
        lessThanOrEqualTo(3600), // at most 60 min
      );
    });

    test('weather grid resolution is positive', () {
      expect(NavigationConstants.weatherGridResolution, greaterThan(0));
    });

    test('wave height thresholds are in ascending order', () {
      expect(
        NavigationConstants.waveHeightCaution,
        lessThan(NavigationConstants.waveHeightDangerous),
      );
      expect(
        NavigationConstants.waveHeightDangerous,
        lessThan(NavigationConstants.waveHeightBlocked),
      );
    });

    test('wind speed thresholds are in ascending order', () {
      expect(
        NavigationConstants.windSpeedCautionKph,
        lessThan(NavigationConstants.windSpeedDangerousKph),
      );
      expect(
        NavigationConstants.windSpeedDangerousKph,
        lessThan(NavigationConstants.windSpeedBlockedKph),
      );
    });

    test('visibility thresholds are in descending order (lower = worse)', () {
      expect(
        NavigationConstants.visibilityCautionMeters,
        greaterThan(NavigationConstants.visibilityDangerousMeters),
      );
      expect(
        NavigationConstants.visibilityDangerousMeters,
        greaterThan(NavigationConstants.visibilityBlockedMeters),
      );
    });

    test('cost multipliers increase with severity', () {
      expect(NavigationConstants.weatherCautionMultiplier, greaterThan(1.0));
      expect(
        NavigationConstants.weatherDangerousMultiplier,
        greaterThan(NavigationConstants.weatherCautionMultiplier),
      );
    });

    test('wave height thresholds are realistic for marine navigation', () {
      // Caution should be around 1m (small craft advisory)
      expect(NavigationConstants.waveHeightCaution, greaterThanOrEqualTo(0.5));
      expect(NavigationConstants.waveHeightCaution, lessThanOrEqualTo(2.0));

      // Blocked should be 3m+ (storm conditions)
      expect(NavigationConstants.waveHeightBlocked, greaterThanOrEqualTo(2.5));
    });

    test('wind speed thresholds are realistic', () {
      // Caution around 30 km/h (small craft advisory ~15 knots)
      expect(NavigationConstants.windSpeedCautionKph, greaterThanOrEqualTo(20));
      expect(NavigationConstants.windSpeedCautionKph, lessThanOrEqualTo(40));

      // Blocked around 60 km/h (gale force ~33 knots)
      expect(NavigationConstants.windSpeedBlockedKph, greaterThanOrEqualTo(50));
    });
  });

  group('NavigationConstants - Helper Methods', () {
    test('metersToNauticalMiles converts correctly', () {
      // 1852 meters = 1 nautical mile
      expect(NavigationConstants.metersToNauticalMiles(1852), closeTo(1.0, 0.001));
      expect(NavigationConstants.metersToNauticalMiles(0), 0.0);
    });

    test('nauticalMilesToMeters converts correctly', () {
      expect(NavigationConstants.nauticalMilesToMeters(1), closeTo(1852.0, 0.001));
    });

    test('roundtrip meter/nautical mile conversion', () {
      const original = 5000.0;
      final nm = NavigationConstants.metersToNauticalMiles(original);
      final back = NavigationConstants.nauticalMilesToMeters(nm);
      expect(back, closeTo(original, 0.01));
    });

    test('formatDistance shows meters for short distances', () {
      expect(NavigationConstants.formatDistance(500), '500 m');
      expect(NavigationConstants.formatDistance(999), '999 m');
    });

    test('formatDistance shows km for long distances', () {
      expect(NavigationConstants.formatDistance(1500), '1.5 km');
      expect(NavigationConstants.formatDistance(10000), '10.0 km');
    });

    test('formatDuration shows seconds for very short durations', () {
      expect(NavigationConstants.formatDuration(30), '30 sec');
    });

    test('formatDuration shows minutes for moderate durations', () {
      expect(NavigationConstants.formatDuration(300), '5 min');
    });

    test('formatDuration shows hours and minutes for long durations', () {
      expect(NavigationConstants.formatDuration(3700), '1h 1m');
      expect(NavigationConstants.formatDuration(7200), '2h 0m');
    });

    test('formatSpeed converts m/s to knots', () {
      // 1 m/s ≈ 1.94 knots
      final result = NavigationConstants.formatSpeed(1.0);
      expect(result, contains('kn'));
      expect(result, contains('1.9'));
    });
  });
}
