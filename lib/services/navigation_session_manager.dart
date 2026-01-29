import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/models/navigation/navigation_session_model.dart';
import 'package:Bahaar/models/navigation/waypoint_model.dart';
import 'package:Bahaar/services/hybrid_route_coordinator.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

/// Service for managing active navigation sessions with real-time tracking
///
/// Features:
/// - Real-time GPS location updates
/// - Waypoint proximity detection and advancement
/// - Off-route detection and automatic recalculation
/// - Breadcrumb trail tracking
/// - Progress metrics (distance traveled, time elapsed, ETA)
/// - Navigation state management
class NavigationSessionManager extends ChangeNotifier {
  final Location _location;
  final HybridRouteCoordinator _routeCoordinator;

  NavigationSession? _session;
  StreamSubscription<LocationData>? _locationSubscription;
  DateTime? _sessionStartTime;
  int _recalculationCount = 0;
  bool _isRecalculating = false;

  NavigationSessionManager({
    required Location location,
    required HybridRouteCoordinator routeCoordinator,
  })  : _location = location,
        _routeCoordinator = routeCoordinator;

  // ============================================================
  // Getters
  // ============================================================

  NavigationSession? get session => _session;
  bool get isNavigating => _session?.state == NavigationState.active;
  bool get isPaused => _session?.state == NavigationState.paused;
  bool get isRecalculating => _isRecalculating;

  // ============================================================
  // Session Management
  // ============================================================

  /// Start a new navigation session
  Future<void> startNavigation(NavigationRoute route) async {
    log('Starting navigation session for route: ${route.id}');

    try {
      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: NavigationConstants.locationUpdateInterval,
        distanceFilter: 5, // Update every 5 meters minimum
      );

      // Get initial location
      final initialLocation = await _location.getLocation();
      final currentLocation = LatLng(
        initialLocation.latitude ?? route.origin.latitude,
        initialLocation.longitude ?? route.origin.longitude,
      );

      // Create session
      _session = NavigationSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        route: route,
        state: NavigationState.active,
        currentLocation: currentLocation,
        currentBearing: initialLocation.heading,
        currentSpeed: initialLocation.speed,
        currentSegmentIndex: 0,
        currentWaypointIndex: 0,
        startTime: DateTime.now(),
        breadcrumbs: [currentLocation],
        metrics: NavigationMetrics(
          distanceTraveled: 0,
          elapsedTime: 0,
          maxSpeed: 0,
        ),
      );

      _sessionStartTime = DateTime.now();
      _recalculationCount = 0;

      // Subscribe to location updates
      _locationSubscription = _location.onLocationChanged.listen(
        _handleLocationUpdate,
        onError: (error) {
          log('Location stream error: $error');
          _handleNavigationError('GPS signal lost');
        },
      );

      notifyListeners();
      log('Navigation session started successfully');
    } catch (e) {
      log('Error starting navigation: $e');
      _session = _session?.copyWith(state: NavigationState.error);
      notifyListeners();
      rethrow;
    }
  }

  /// Pause navigation (stops location updates but keeps state)
  void pauseNavigation() {
    if (_session == null || _session!.state != NavigationState.active) return;

    log('Pausing navigation session');
    _locationSubscription?.pause();
    _session = _session!.copyWith(state: NavigationState.paused);
    notifyListeners();
  }

  /// Resume navigation
  void resumeNavigation() {
    if (_session == null || _session!.state != NavigationState.paused) return;

    log('Resuming navigation session');
    _locationSubscription?.resume();
    _session = _session!.copyWith(state: NavigationState.active);
    notifyListeners();
  }

  /// Cancel navigation and clean up
  void cancelNavigation() {
    log('Canceling navigation session');
    _cleanupSession();
    _session = _session?.copyWith(state: NavigationState.cancelled);
    notifyListeners();

    // Clear session after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _session = null;
      notifyListeners();
    });
  }

  /// Complete navigation when destination is reached
  void _completeNavigation() {
    log('Navigation completed!');
    _cleanupSession();
    _session = _session?.copyWith(state: NavigationState.completed);
    notifyListeners();
  }

  /// Clean up resources
  void _cleanupSession() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _sessionStartTime = null;
  }

  // ============================================================
  // Location Update Handler
  // ============================================================

  void _handleLocationUpdate(LocationData locationData) {
    if (_session == null || _session!.state != NavigationState.active) return;
    if (_isRecalculating) return;

    final lat = locationData.latitude;
    final lon = locationData.longitude;
    if (lat == null || lon == null) return;

    final currentLocation = LatLng(lat, lon);
    final bearing = locationData.heading;
    final speed = locationData.speed;

    // Update breadcrumbs
    final updatedBreadcrumbs = List<LatLng>.from(_session!.breadcrumbs);
    updatedBreadcrumbs.add(currentLocation);

    // Limit breadcrumb history
    if (updatedBreadcrumbs.length > NavigationConstants.maxBreadcrumbs) {
      updatedBreadcrumbs.removeAt(0);
    }

    // Calculate metrics
    final metrics = _calculateMetrics(updatedBreadcrumbs);

    // Update session
    _session = _session!.copyWith(
      currentLocation: currentLocation,
      currentBearing: bearing,
      currentSpeed: speed,
      breadcrumbs: updatedBreadcrumbs,
      metrics: metrics,
    );

    // Check waypoint proximity
    _checkWaypointProximity(currentLocation);

    // Check if off route
    _checkOffRoute(currentLocation);

    notifyListeners();
  }

  // ============================================================
  // Waypoint Management
  // ============================================================

  void _checkWaypointProximity(LatLng currentLocation) {
    if (_session == null) return;

    final nextWaypoint = _session!.nextWaypoint;
    if (nextWaypoint == null) {
      // No more waypoints - check if reached destination
      final distanceToDestination = _calculateDistance(
        currentLocation,
        _session!.route.destination,
      );

      if (distanceToDestination <= NavigationConstants.waypointProximity) {
        _completeNavigation();
      }
      return;
    }

    final distanceToWaypoint = _calculateDistance(
      currentLocation,
      nextWaypoint.location,
    );

    // Check if within proximity threshold
    if (distanceToWaypoint <= NavigationConstants.waypointProximity) {
      log('Reached waypoint: ${nextWaypoint.instruction}');
      _advanceToNextWaypoint();
    }
  }

  void _advanceToNextWaypoint() {
    if (_session == null) return;

    final nextIndex = _session!.currentWaypointIndex + 1;

    // Check if this advances to a new segment
    int newSegmentIndex = _session!.currentSegmentIndex;
    if (nextIndex < _session!.route.waypoints.length) {
      final nextWaypoint = _session!.route.waypoints[nextIndex];
      if (nextWaypoint.type == WaypointType.marinaEntry ||
          nextWaypoint.type == WaypointType.marinaExit) {
        newSegmentIndex++;
      }
    }

    _session = _session!.copyWith(
      currentWaypointIndex: nextIndex,
      currentSegmentIndex: newSegmentIndex,
    );

    notifyListeners();
  }

  // ============================================================
  // Off-Route Detection
  // ============================================================

  void _checkOffRoute(LatLng currentLocation) {
    if (_session == null) return;

    // Get current segment geometry
    if (_session!.currentSegmentIndex >= _session!.route.segments.length) {
      return;
    }

    final currentSegment = _session!.route.segments[_session!.currentSegmentIndex];
    final geometry = currentSegment.geometry;

    if (geometry.isEmpty) return;

    // Find minimum distance to route
    double minDistance = double.infinity;
    for (int i = 0; i < geometry.length - 1; i++) {
      final distance = _distanceToLineSegment(
        currentLocation,
        geometry[i],
        geometry[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // Check if off route
    if (minDistance > NavigationConstants.offRouteThreshold) {
      log('Off route detected: ${minDistance.toStringAsFixed(1)}m from route');
      _handleOffRoute();
    }
  }

  void _handleOffRoute() async {
    if (_isRecalculating) return;
    if (_recalculationCount >= NavigationConstants.maxRecalculations) {
      log('Max recalculations reached, stopping auto-recalculation');
      _handleNavigationError('Unable to recalculate route');
      return;
    }

    _isRecalculating = true;
    _recalculationCount++;
    notifyListeners();

    log('Recalculating route (attempt $_recalculationCount)...');

    try {
      final newRoute = await _routeCoordinator.calculateRoute(
        origin: _session!.currentLocation!,
        destination: _session!.route.destination,
      );

      if (newRoute != null) {
        log('Route recalculated successfully');

        // Update session with new route
        _session = NavigationSession(
          id: _session!.id,
          route: newRoute,
          state: NavigationState.active,
          currentLocation: _session!.currentLocation,
          currentBearing: _session!.currentBearing,
          currentSpeed: _session!.currentSpeed,
          currentSegmentIndex: 0,
          currentWaypointIndex: 0,
          startTime: _session!.startTime,
          breadcrumbs: _session!.breadcrumbs,
          metrics: _session!.metrics,
        );
      } else {
        log('Failed to recalculate route');
        _handleNavigationError('Could not find alternative route');
      }
    } catch (e) {
      log('Error recalculating route: $e');
      _handleNavigationError('Route recalculation failed');
    } finally {
      _isRecalculating = false;
      notifyListeners();
    }
  }

  void _handleNavigationError(String message) {
    log('Navigation error: $message');
    _session = _session?.copyWith(state: NavigationState.error);
    notifyListeners();
  }

  // ============================================================
  // Metrics Calculation
  // ============================================================

  NavigationMetrics _calculateMetrics(List<LatLng> breadcrumbs) {
    if (breadcrumbs.length < 2 || _sessionStartTime == null) {
      return NavigationMetrics(
        distanceTraveled: 0,
        elapsedTime: 0,
        maxSpeed: 0,
      );
    }

    // Calculate distance traveled
    double distanceTraveled = 0;
    for (int i = 0; i < breadcrumbs.length - 1; i++) {
      distanceTraveled += _calculateDistance(breadcrumbs[i], breadcrumbs[i + 1]);
    }

    // Calculate time elapsed
    final elapsedTime = DateTime.now().difference(_sessionStartTime!).inSeconds;

    // Calculate max speed (use current speed if available)
    final currentMaxSpeed = _session?.currentSpeed ?? 0;
    final previousMaxSpeed = _session?.metrics.maxSpeed ?? 0;
    final maxSpeed = math.max(currentMaxSpeed, previousMaxSpeed);

    return NavigationMetrics(
      distanceTraveled: distanceTraveled,
      elapsedTime: elapsedTime,
      numRecalculations: _recalculationCount,
      hadOffRouteEvents: _recalculationCount > 0,
      maxSpeed: maxSpeed,
    );
  }

  // ============================================================
  // Geometry Utilities
  // ============================================================

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate perpendicular distance from point to line segment
  double _distanceToLineSegment(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final x0 = point.longitude;
    final y0 = point.latitude;
    final x1 = lineStart.longitude;
    final y1 = lineStart.latitude;
    final x2 = lineEnd.longitude;
    final y2 = lineEnd.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      // Line segment is a point
      return _calculateDistance(point, lineStart);
    }

    // Calculate projection
    final t = ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      // Point is before line segment
      return _calculateDistance(point, lineStart);
    } else if (t > 1) {
      // Point is after line segment
      return _calculateDistance(point, lineEnd);
    } else {
      // Point projects onto line segment
      final projectionX = x1 + t * dx;
      final projectionY = y1 + t * dy;
      return _calculateDistance(point, LatLng(projectionY, projectionX));
    }
  }

  // ============================================================
  // Cleanup
  // ============================================================

  @override
  void dispose() {
    _cleanupSession();
    super.dispose();
  }
}
