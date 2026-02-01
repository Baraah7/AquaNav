import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/navigation/waypoint_model.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';
import 'package:Bahaar/services/map/navigation_mask.dart';

/// Complete navigation route with segments, waypoints, and validation
class NavigationRoute {
  final String id;
  final LatLng origin;
  final LatLng destination;
  final List<RouteSegment> segments;
  final List<LatLng> geometry;
  final List<Waypoint> waypoints;
  final double totalDistance;
  final int estimatedDuration;
  final RouteValidation validation;
  final DateTime createdAt;
  final RouteMetrics metrics;

  const NavigationRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.segments,
    required this.geometry,
    required this.waypoints,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.validation,
    required this.createdAt,
    required this.metrics,
  });

  /// Check if this is a hybrid route (contains both land and marine segments)
  bool get isHybrid =>
      segments.any((s) => s.type == SegmentType.marine) &&
      segments.any((s) => s.type == SegmentType.land);

  /// Check if route crosses restricted areas
  bool get crossesRestrictedAreas => !validation.isValid;

  /// Get the current segment based on user location
  RouteSegment? currentSegment(LatLng userLocation, double distanceTraveled) {
    double accumulated = 0;
    for (final segment in segments) {
      accumulated += segment.distance;
      if (distanceTraveled < accumulated) {
        return segment;
      }
    }
    return segments.isNotEmpty ? segments.last : null;
  }

  /// Calculate progress percentage
  double progressPercentage(double distanceTraveled) {
    if (totalDistance == 0) return 0;
    return (distanceTraveled / totalDistance * 100).clamp(0, 100);
  }

  /// Create a copy with modified fields
  NavigationRoute copyWith({
    String? id,
    LatLng? origin,
    LatLng? destination,
    List<RouteSegment>? segments,
    List<LatLng>? geometry,
    List<Waypoint>? waypoints,
    double? totalDistance,
    int? estimatedDuration,
    RouteValidation? validation,
    DateTime? createdAt,
    RouteMetrics? metrics,
  }) {
    return NavigationRoute(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      segments: segments ?? this.segments,
      geometry: geometry ?? this.geometry,
      waypoints: waypoints ?? this.waypoints,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      validation: validation ?? this.validation,
      createdAt: createdAt ?? this.createdAt,
      metrics: metrics ?? this.metrics,
    );
  }

  @override
  String toString() {
    return 'NavigationRoute(id: $id, segments: ${segments.length}, distance: ${totalDistance}m, duration: ${estimatedDuration}s, hybrid: $isHybrid)';
  }
}

/// Segment of a route (land or marine section)
class RouteSegment {
  final SegmentType type;
  final List<LatLng> geometry;
  final double distance;
  final int duration;
  final String? transportMode;
  final Marina? entryMarina;
  final Marina? exitMarina;

  const RouteSegment({
    required this.type,
    required this.geometry,
    required this.distance,
    required this.duration,
    this.transportMode,
    this.entryMarina,
    this.exitMarina,
  });

  /// Create RouteSegment from JSON
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    final geometryList = json['geometry'] as List;
    final geometry = geometryList
        .map((coord) => LatLng(coord['lat'] as double, coord['lon'] as double))
        .toList();

    return RouteSegment(
      type: SegmentType.values.byName(json['type'] as String),
      geometry: geometry,
      distance: json['distance'] as double,
      duration: json['duration'] as int,
      transportMode: json['transport_mode'] as String?,
      entryMarina: json['entry_marina'] != null
          ? Marina.fromJson(json['entry_marina'])
          : null,
      exitMarina: json['exit_marina'] != null
          ? Marina.fromJson(json['exit_marina'])
          : null,
    );
  }

  /// Convert RouteSegment to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'geometry': geometry
          .map((point) => {'lat': point.latitude, 'lon': point.longitude})
          .toList(),
      'distance': distance,
      'duration': duration,
      if (transportMode != null) 'transport_mode': transportMode,
      if (entryMarina != null) 'entry_marina': entryMarina!.toJson(),
      if (exitMarina != null) 'exit_marina': exitMarina!.toJson(),
    };
  }

  @override
  String toString() {
    return 'RouteSegment(type: ${type.displayName}, distance: ${distance}m, duration: ${duration}s, mode: $transportMode)';
  }
}

/// Type of route segment
enum SegmentType {
  land('Land'),
  marine('Marine');

  final String displayName;

  const SegmentType(this.displayName);
}

/// Metrics for a navigation route
class RouteMetrics {
  final double landDistance;
  final double marineDistance;
  final int landDuration;
  final int marineDuration;
  final int numRestrictedAreaViolations;
  final double? averageDepth;

  const RouteMetrics({
    required this.landDistance,
    required this.marineDistance,
    required this.landDuration,
    required this.marineDuration,
    this.numRestrictedAreaViolations = 0,
    this.averageDepth,
  });

  /// Total distance (land + marine)
  double get totalDistance => landDistance + marineDistance;

  /// Total duration (land + marine)
  int get totalDuration => landDuration + marineDuration;

  /// Percentage of route on land
  double get landPercentage =>
      totalDistance > 0 ? (landDistance / totalDistance * 100) : 0;

  /// Percentage of route on marine
  double get marinePercentage =>
      totalDistance > 0 ? (marineDistance / totalDistance * 100) : 0;

  /// Create RouteMetrics from JSON
  factory RouteMetrics.fromJson(Map<String, dynamic> json) {
    return RouteMetrics(
      landDistance: json['land_distance'] as double,
      marineDistance: json['marine_distance'] as double,
      landDuration: json['land_duration'] as int,
      marineDuration: json['marine_duration'] as int,
      numRestrictedAreaViolations:
          json['num_restricted_area_violations'] as int? ?? 0,
      averageDepth: json['average_depth'] as double?,
    );
  }

  /// Convert RouteMetrics to JSON
  Map<String, dynamic> toJson() {
    return {
      'land_distance': landDistance,
      'marine_distance': marineDistance,
      'land_duration': landDuration,
      'marine_duration': marineDuration,
      'num_restricted_area_violations': numRestrictedAreaViolations,
      if (averageDepth != null) 'average_depth': averageDepth,
    };
  }

  /// Create a copy with modified fields
  RouteMetrics copyWith({
    double? landDistance,
    double? marineDistance,
    int? landDuration,
    int? marineDuration,
    int? numRestrictedAreaViolations,
    double? averageDepth,
  }) {
    return RouteMetrics(
      landDistance: landDistance ?? this.landDistance,
      marineDistance: marineDistance ?? this.marineDistance,
      landDuration: landDuration ?? this.landDuration,
      marineDuration: marineDuration ?? this.marineDuration,
      numRestrictedAreaViolations:
          numRestrictedAreaViolations ?? this.numRestrictedAreaViolations,
      averageDepth: averageDepth ?? this.averageDepth,
    );
  }

  @override
  String toString() {
    return 'RouteMetrics(total: ${totalDistance}m, land: ${landDistance}m, marine: ${marineDistance}m, violations: $numRestrictedAreaViolations)';
  }
}
