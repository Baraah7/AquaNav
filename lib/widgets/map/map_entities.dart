import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Fishing Activity Point
class FishingActivity extends Equatable {
  final String id;
  final LatLng position;
  final String vesselName;
  final String vesselType;
  final double speed;
  final DateTime timestamp;
  final double activityScore;

  const FishingActivity({
    required this.id,
    required this.position,
    required this.vesselName,
    required this.vesselType,
    required this.speed,
    required this.timestamp,
    required this.activityScore,
  });

  @override
  List<Object?> get props => [id, position, vesselName, vesselType, speed, timestamp, activityScore];
}

/// Fish Probability Data
class FishProbability extends Equatable {
  final LatLng position;
  final double probability;
  final double temperature;
  final double chlorophyll;
  final double fishingActivity;
  final DateTime timestamp;

  const FishProbability({
    required this.position,
    required this.probability,
    required this.temperature,
    required this.chlorophyll,
    required this.fishingActivity,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [position, probability, temperature, chlorophyll, fishingActivity, timestamp];
}

/// Restricted Area
class RestrictedArea extends Equatable {
  final String id;
  final String name;
  final String type; // "protected", "military", "fishing_restricted"
  final List<LatLng> polygon;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;

  const RestrictedArea({
    required this.id,
    required this.name,
    required this.type,
    required this.polygon,
    required this.description,
    this.startDate,
    this.endDate,
  });

  bool isActive() {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [id, name, type, polygon, description, startDate, endDate];
}

/// Weather Data Point
class WeatherData extends Equatable {
  final LatLng position;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final double waveHeight;
  final double visibility;
  final String condition;
  final DateTime timestamp;

  const WeatherData({
    required this.position,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.waveHeight,
    required this.visibility,
    required this.condition,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [position, temperature, windSpeed, windDirection, waveHeight, visibility, condition, timestamp];
}

/// Bathymetry Data
class BathymetryData extends Equatable {
  final LatLng position;
  final double depth;

  const BathymetryData({
    required this.position,
    required this.depth,
  });

  @override
  List<Object?> get props => [position, depth];
}