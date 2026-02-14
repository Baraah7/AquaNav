import 'package:Bahaar/utilities/navigation_constants.dart';

/// Safety level for marine weather conditions
enum SafetyLevel {
  safe('Safe', 'Conditions are safe for navigation'),
  caution('Caution', 'Conditions require extra caution'),
  dangerous('Dangerous', 'Conditions are dangerous for navigation'),
  blocked('Blocked', 'Conditions are too dangerous for navigation');

  final String displayName;
  final String description;

  const SafetyLevel(this.displayName, this.description);
}

/// Marine weather data from Open-Meteo API for a single sample point
class MarineWeatherData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double waveHeight;
  final double wavePeriod;
  final double windWaveHeight;
  final double swellWaveHeight;
  final double windSpeed;
  final double windGusts;
  final double visibility;

  const MarineWeatherData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.waveHeight,
    required this.wavePeriod,
    required this.windWaveHeight,
    required this.swellWaveHeight,
    required this.windSpeed,
    required this.windGusts,
    required this.visibility,
  });

  factory MarineWeatherData.fromJson(Map<String, dynamic> json) {
    return MarineWeatherData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      waveHeight: (json['wave_height'] as num?)?.toDouble() ?? 0.0,
      wavePeriod: (json['wave_period'] as num?)?.toDouble() ?? 0.0,
      windWaveHeight: (json['wind_wave_height'] as num?)?.toDouble() ?? 0.0,
      swellWaveHeight: (json['swell_wave_height'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      windGusts: (json['wind_gusts'] as num?)?.toDouble() ?? 0.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 10000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'wave_height': waveHeight,
      'wave_period': wavePeriod,
      'wind_wave_height': windWaveHeight,
      'swell_wave_height': swellWaveHeight,
      'wind_speed': windSpeed,
      'wind_gusts': windGusts,
      'visibility': visibility,
    };
  }

  MarineWeatherData copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? waveHeight,
    double? wavePeriod,
    double? windWaveHeight,
    double? swellWaveHeight,
    double? windSpeed,
    double? windGusts,
    double? visibility,
  }) {
    return MarineWeatherData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      waveHeight: waveHeight ?? this.waveHeight,
      wavePeriod: wavePeriod ?? this.wavePeriod,
      windWaveHeight: windWaveHeight ?? this.windWaveHeight,
      swellWaveHeight: swellWaveHeight ?? this.swellWaveHeight,
      windSpeed: windSpeed ?? this.windSpeed,
      windGusts: windGusts ?? this.windGusts,
      visibility: visibility ?? this.visibility,
    );
  }

  @override
  String toString() =>
      'MarineWeatherData(lat: $latitude, lon: $longitude, waves: ${waveHeight}m, wind: ${windSpeed}km/h, vis: ${visibility}m)';
}

/// Safety assessment result for a weather data point
class WeatherSafetyAssessment {
  final SafetyLevel level;
  final double costMultiplier;
  final List<String> warnings;
  final MarineWeatherData data;

  const WeatherSafetyAssessment({
    required this.level,
    required this.costMultiplier,
    required this.warnings,
    required this.data,
  });

  @override
  String toString() =>
      'WeatherSafetyAssessment(level: ${level.displayName}, multiplier: $costMultiplier, warnings: $warnings)';
}

/// Configurable safety thresholds for marine weather conditions
class MarineSafetyThresholds {
  final double waveHeightCaution;
  final double waveHeightDangerous;
  final double waveHeightBlocked;
  final double windSpeedCaution;
  final double windSpeedDangerous;
  final double windSpeedBlocked;
  final double visibilityCaution;
  final double visibilityDangerous;
  final double visibilityBlocked;
  final double cautionMultiplier;
  final double dangerousMultiplier;

  const MarineSafetyThresholds({
    this.waveHeightCaution = NavigationConstants.waveHeightCaution,
    this.waveHeightDangerous = NavigationConstants.waveHeightDangerous,
    this.waveHeightBlocked = NavigationConstants.waveHeightBlocked,
    this.windSpeedCaution = NavigationConstants.windSpeedCautionKph,
    this.windSpeedDangerous = NavigationConstants.windSpeedDangerousKph,
    this.windSpeedBlocked = NavigationConstants.windSpeedBlockedKph,
    this.visibilityCaution = NavigationConstants.visibilityCautionMeters,
    this.visibilityDangerous = NavigationConstants.visibilityDangerousMeters,
    this.visibilityBlocked = NavigationConstants.visibilityBlockedMeters,
    this.cautionMultiplier = NavigationConstants.weatherCautionMultiplier,
    this.dangerousMultiplier = NavigationConstants.weatherDangerousMultiplier,
  });

  /// Evaluate weather data and return the worst safety level with warnings
  WeatherSafetyAssessment evaluate(MarineWeatherData data) {
    SafetyLevel worstLevel = SafetyLevel.safe;
    final warnings = <String>[];

    // Evaluate wave height
    if (data.waveHeight >= waveHeightBlocked) {
      worstLevel = SafetyLevel.blocked;
      warnings.add('Wave height ${data.waveHeight.toStringAsFixed(1)}m exceeds safe limit');
    } else if (data.waveHeight >= waveHeightDangerous) {
      worstLevel = _worst(worstLevel, SafetyLevel.dangerous);
      warnings.add('High waves: ${data.waveHeight.toStringAsFixed(1)}m');
    } else if (data.waveHeight >= waveHeightCaution) {
      worstLevel = _worst(worstLevel, SafetyLevel.caution);
      warnings.add('Moderate waves: ${data.waveHeight.toStringAsFixed(1)}m');
    }

    // Evaluate wind speed
    if (data.windSpeed >= windSpeedBlocked) {
      worstLevel = SafetyLevel.blocked;
      warnings.add('Wind speed ${data.windSpeed.toStringAsFixed(0)} km/h exceeds safe limit');
    } else if (data.windSpeed >= windSpeedDangerous) {
      worstLevel = _worst(worstLevel, SafetyLevel.dangerous);
      warnings.add('Strong wind: ${data.windSpeed.toStringAsFixed(0)} km/h');
    } else if (data.windSpeed >= windSpeedCaution) {
      worstLevel = _worst(worstLevel, SafetyLevel.caution);
      warnings.add('Moderate wind: ${data.windSpeed.toStringAsFixed(0)} km/h');
    }

    // Evaluate visibility (lower is worse)
    if (data.visibility <= visibilityBlocked) {
      worstLevel = SafetyLevel.blocked;
      warnings.add('Visibility ${data.visibility.toStringAsFixed(0)}m below safe limit');
    } else if (data.visibility <= visibilityDangerous) {
      worstLevel = _worst(worstLevel, SafetyLevel.dangerous);
      warnings.add('Low visibility: ${data.visibility.toStringAsFixed(0)}m');
    } else if (data.visibility <= visibilityCaution) {
      worstLevel = _worst(worstLevel, SafetyLevel.caution);
      warnings.add('Reduced visibility: ${data.visibility.toStringAsFixed(0)}m');
    }

    // Determine cost multiplier
    double multiplier;
    switch (worstLevel) {
      case SafetyLevel.safe:
        multiplier = 1.0;
      case SafetyLevel.caution:
        multiplier = cautionMultiplier;
      case SafetyLevel.dangerous:
        multiplier = dangerousMultiplier;
      case SafetyLevel.blocked:
        multiplier = double.infinity;
    }

    return WeatherSafetyAssessment(
      level: worstLevel,
      costMultiplier: multiplier,
      warnings: warnings,
      data: data,
    );
  }

  /// Return the more severe of two safety levels
  SafetyLevel _worst(SafetyLevel a, SafetyLevel b) {
    return a.index >= b.index ? a : b;
  }
}
