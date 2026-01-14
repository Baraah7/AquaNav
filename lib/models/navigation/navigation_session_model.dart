import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/models/navigation/waypoint_model.dart';

/// Active navigation session tracking user progress along a route
class NavigationSession {
  final String id;
  final NavigationRoute route;
  final NavigationState state;
  final LatLng? currentLocation;
  final double? currentBearing;
  final double? currentSpeed;
  final int currentSegmentIndex;
  final int currentWaypointIndex;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LatLng> breadcrumbs;
  final NavigationMetrics metrics;

  const NavigationSession({
    required this.id,
    required this.route,
    required this.state,
    this.currentLocation,
    this.currentBearing,
    this.currentSpeed,
    required this.currentSegmentIndex,
    required this.currentWaypointIndex,
    required this.startTime,
    this.endTime,
    required this.breadcrumbs,
    required this.metrics,
  });

  /// Get distance remaining to destination (meters)
  double get distanceRemaining {
    if (currentLocation == null) return route.totalDistance;
    return route.totalDistance - metrics.distanceTraveled;
  }

  /// Get estimated time remaining (seconds)
  int get timeRemaining {
    if (route.estimatedDuration == 0) return 0;
    final elapsed = metrics.elapsedTime;
    final estimated = route.estimatedDuration;
    return (estimated - elapsed).clamp(0, estimated);
  }

  /// Get the next waypoint to reach
  Waypoint? get nextWaypoint {
    if (currentWaypointIndex >= route.waypoints.length - 1) return null;
    return route.waypoints[currentWaypointIndex + 1];
  }

  /// Check if user is off route
  bool get isOffRoute {
    // Implementation would check if current location is far from route geometry
    // This is a placeholder - actual implementation in NavigationSessionManager
    return false;
  }

  /// Check if nearing a marina transition
  bool get isNearingTransition {
    final next = nextWaypoint;
    if (next == null) return false;
    return next.type == WaypointType.marinaEntry ||
        next.type == WaypointType.marinaExit;
  }

  /// Get current route segment
  RouteSegment? get currentSegment {
    if (currentSegmentIndex >= route.segments.length) return null;
    return route.segments[currentSegmentIndex];
  }

  /// Calculate progress percentage
  double get progressPercentage {
    if (route.totalDistance == 0) return 0;
    return (metrics.distanceTraveled / route.totalDistance * 100).clamp(0, 100);
  }

  /// Create a copy with modified fields
  NavigationSession copyWith({
    String? id,
    NavigationRoute? route,
    NavigationState? state,
    LatLng? currentLocation,
    double? currentBearing,
    double? currentSpeed,
    int? currentSegmentIndex,
    int? currentWaypointIndex,
    DateTime? startTime,
    DateTime? endTime,
    List<LatLng>? breadcrumbs,
    NavigationMetrics? metrics,
  }) {
    return NavigationSession(
      id: id ?? this.id,
      route: route ?? this.route,
      state: state ?? this.state,
      currentLocation: currentLocation ?? this.currentLocation,
      currentBearing: currentBearing ?? this.currentBearing,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      metrics: metrics ?? this.metrics,
    );
  }

  @override
  String toString() {
    return 'NavigationSession(id: $id, state: ${state.displayName}, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}

/// Navigation session state
enum NavigationState {
  planning('Planning', 'Route preview'),
  ready('Ready', 'Ready to start'),
  active('Active', 'Currently navigating'),
  paused('Paused', 'Temporarily stopped'),
  completed('Completed', 'Reached destination'),
  cancelled('Cancelled', 'User aborted'),
  error('Error', 'Navigation failure');

  final String displayName;
  final String description;

  const NavigationState(this.displayName, this.description);
}

/// Metrics for tracking navigation progress
class NavigationMetrics {
  final double distanceTraveled;
  final int elapsedTime;
  final int numRecalculations;
  final bool hadOffRouteEvents;
  final double maxSpeed;

  const NavigationMetrics({
    required this.distanceTraveled,
    required this.elapsedTime,
    this.numRecalculations = 0,
    this.hadOffRouteEvents = false,
    required this.maxSpeed,
  });

  /// Create NavigationMetrics from JSON
  factory NavigationMetrics.fromJson(Map<String, dynamic> json) {
    return NavigationMetrics(
      distanceTraveled: json['distance_traveled'] as double,
      elapsedTime: json['elapsed_time'] as int,
      numRecalculations: json['num_recalculations'] as int? ?? 0,
      hadOffRouteEvents: json['had_off_route_events'] as bool? ?? false,
      maxSpeed: json['max_speed'] as double,
    );
  }

  /// Convert NavigationMetrics to JSON
  Map<String, dynamic> toJson() {
    return {
      'distance_traveled': distanceTraveled,
      'elapsed_time': elapsedTime,
      'num_recalculations': numRecalculations,
      'had_off_route_events': hadOffRouteEvents,
      'max_speed': maxSpeed,
    };
  }

  /// Create a copy with modified fields
  NavigationMetrics copyWith({
    double? distanceTraveled,
    int? elapsedTime,
    int? numRecalculations,
    bool? hadOffRouteEvents,
    double? maxSpeed,
  }) {
    return NavigationMetrics(
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      numRecalculations: numRecalculations ?? this.numRecalculations,
      hadOffRouteEvents: hadOffRouteEvents ?? this.hadOffRouteEvents,
      maxSpeed: maxSpeed ?? this.maxSpeed,
    );
  }

  @override
  String toString() {
    return 'NavigationMetrics(distance: ${distanceTraveled}m, time: ${elapsedTime}s, recalc: $numRecalculations, maxSpeed: ${maxSpeed}m/s)';
  }
}
