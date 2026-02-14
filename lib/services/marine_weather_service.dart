import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:Bahaar/models/weather/marine_weather_model.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

/// Service for fetching marine weather data from Open-Meteo and mapping it
/// to the navigation grid for safety-aware routing.
///
/// Samples weather at coarse grid points (~0.2 degrees) covering the Bahrain
/// bounding box. Each coarse point covers ~250x250 navigation cells.
class MarineWeatherService {
  final http.Client _client;
  final MarineSafetyThresholds _thresholds;

  // Bounding box for weather sampling (matches navigation mask)
  final double _minLat;
  final double _maxLat;
  final double _minLon;
  final double _maxLon;

  // Cache: coarse grid index -> assessment
  final Map<(int, int), WeatherSafetyAssessment> _assessmentCache = {};
  // Previous assessments for change detection
  final Map<(int, int), SafetyLevel> _previousLevels = {};

  DateTime? _lastFetchTime;
  bool _hasData = false;
  bool _conditionsChanged = false;

  MarineWeatherService({
    http.Client? client,
    MarineSafetyThresholds? thresholds,
    double minLat = 25.8,
    double maxLat = 26.4,
    double minLon = 50.3,
    double maxLon = 50.9,
  })  : _client = client ?? http.Client(),
        _thresholds = thresholds ?? const MarineSafetyThresholds(),
        _minLat = minLat,
        _maxLat = maxLat,
        _minLon = minLon,
        _maxLon = maxLon;

  bool get hasData => _hasData;
  DateTime? get lastFetchTime => _lastFetchTime;

  /// Initialize the service with an initial weather fetch
  Future<void> initialize() async {
    log('Initializing marine weather service');
    await refreshWeather();
  }

  /// Fetch weather data from Open-Meteo for all sample points
  Future<void> refreshWeather() async {
    // Skip if recently fetched
    if (_lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!).inSeconds;
      if (elapsed < NavigationConstants.weatherRefreshIntervalSeconds) {
        log('Weather cache still valid ($elapsed s old)');
        return;
      }
    }

    log('Refreshing marine weather data');

    // Save previous levels for change detection
    _previousLevels.clear();
    for (final entry in _assessmentCache.entries) {
      _previousLevels[entry.key] = entry.value.level;
    }

    _assessmentCache.clear();
    _conditionsChanged = false;

    // Generate sample points across the bounding box
    final resolution = NavigationConstants.weatherGridResolution;
    final samplePoints = <(double lat, double lon, int latIdx, int lonIdx)>[];

    for (double lat = _minLat; lat <= _maxLat; lat += resolution) {
      for (double lon = _minLon; lon <= _maxLon; lon += resolution) {
        final latIdx = ((lat - _minLat) / resolution).floor();
        final lonIdx = ((lon - _minLon) / resolution).floor();
        samplePoints.add((lat, lon, latIdx, lonIdx));
      }
    }

    log('Fetching weather for ${samplePoints.length} sample points');

    for (final (lat, lon, latIdx, lonIdx) in samplePoints) {
      try {
        final weatherData = await _fetchWeatherForPoint(lat, lon);
        if (weatherData != null) {
          final assessment = _thresholds.evaluate(weatherData);
          _assessmentCache[(latIdx, lonIdx)] = assessment;

          // Check if conditions changed from previous fetch
          final prevLevel = _previousLevels[(latIdx, lonIdx)];
          if (prevLevel != null && prevLevel != assessment.level) {
            _conditionsChanged = true;
          }

          if (assessment.level != SafetyLevel.safe) {
            log('Weather warning at ($lat, $lon): ${assessment.level.displayName} - ${assessment.warnings.join(", ")}');
          }
        }
      } catch (e) {
        log('Error fetching weather for ($lat, $lon): $e');
        // On error, don't block the cell - assume safe
      }
    }

    _lastFetchTime = DateTime.now();
    _hasData = _assessmentCache.isNotEmpty;
    log('Weather refresh complete: ${_assessmentCache.length} points cached');
  }

  /// Fetch weather data for a single coordinate from both Open-Meteo APIs
  Future<MarineWeatherData?> _fetchWeatherForPoint(double lat, double lon) async {
    double waveHeight = 0;
    double wavePeriod = 0;
    double windWaveHeight = 0;
    double swellWaveHeight = 0;
    double windSpeed = 0;
    double windGusts = 0;
    double visibility = 10000;

    // Fetch marine data (wave height, swell, period)
    try {
      final marineUrl = Uri.parse(
        '${NavigationConstants.openMeteoMarineBaseUrl}'
        '?latitude=$lat&longitude=$lon'
        '&current=wave_height,wave_period,wind_wave_height,swell_wave_height',
      );

      final marineResponse = await _client.get(marineUrl).timeout(
        const Duration(seconds: 10),
      );

      if (marineResponse.statusCode == 200) {
        final data = json.decode(marineResponse.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          waveHeight = (current['wave_height'] as num?)?.toDouble() ?? 0;
          wavePeriod = (current['wave_period'] as num?)?.toDouble() ?? 0;
          windWaveHeight = (current['wind_wave_height'] as num?)?.toDouble() ?? 0;
          swellWaveHeight = (current['swell_wave_height'] as num?)?.toDouble() ?? 0;
        }
      } else {
        log('Marine API returned ${marineResponse.statusCode} for ($lat, $lon)');
      }
    } catch (e) {
      log('Marine API error for ($lat, $lon): $e');
    }

    // Fetch forecast data (wind, visibility)
    try {
      final forecastUrl = Uri.parse(
        '${NavigationConstants.openMeteoForecastBaseUrl}'
        '?latitude=$lat&longitude=$lon'
        '&current=wind_speed_10m,wind_gusts_10m,visibility',
      );

      final forecastResponse = await _client.get(forecastUrl).timeout(
        const Duration(seconds: 10),
      );

      if (forecastResponse.statusCode == 200) {
        final data = json.decode(forecastResponse.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;
          windGusts = (current['wind_gusts_10m'] as num?)?.toDouble() ?? 0;
          visibility = (current['visibility'] as num?)?.toDouble() ?? 10000;
        }
      } else {
        log('Forecast API returned ${forecastResponse.statusCode} for ($lat, $lon)');
      }
    } catch (e) {
      log('Forecast API error for ($lat, $lon): $e');
    }

    return MarineWeatherData(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      waveHeight: waveHeight,
      wavePeriod: wavePeriod,
      windWaveHeight: windWaveHeight,
      swellWaveHeight: swellWaveHeight,
      windSpeed: windSpeed,
      windGusts: windGusts,
      visibility: visibility,
    );
  }

  /// Get safety assessment for a navigation grid cell.
  /// Maps the fine grid cell to the nearest coarse weather sample point.
  WeatherSafetyAssessment? getAssessmentForCell(
    int row,
    int col, {
    required double minLat,
    required double minLon,
    required double resolution,
    required int gridHeight,
  }) {
    if (!_hasData) return null;

    // Convert navigation grid cell to lat/lon
    final lon = minLon + (col + 0.5) * resolution;
    final lat = minLat + ((gridHeight - 1 - row) + 0.5) * resolution;

    // Map to coarse weather grid index
    final weatherRes = NavigationConstants.weatherGridResolution;
    final latIdx = ((lat - _minLat) / weatherRes).floor();
    final lonIdx = ((lon - _minLon) / weatherRes).floor();

    return _assessmentCache[(latIdx, lonIdx)];
  }

  /// Get all active weather warnings (non-safe assessments)
  List<WeatherSafetyAssessment> getActiveWarnings() {
    return _assessmentCache.values
        .where((a) => a.level != SafetyLevel.safe)
        .toList();
  }

  /// Get the worst safety level across all sample points
  SafetyLevel getOverallSafetyLevel() {
    if (!_hasData) return SafetyLevel.safe;

    SafetyLevel worst = SafetyLevel.safe;
    for (final assessment in _assessmentCache.values) {
      if (assessment.level.index > worst.index) {
        worst = assessment.level;
      }
    }
    return worst;
  }

  /// Check if weather conditions have changed since the last fetch
  bool hasConditionsChanged() {
    return _conditionsChanged;
  }

  void dispose() {
    _assessmentCache.clear();
    _previousLevels.clear();
    _client.close();
  }
}
