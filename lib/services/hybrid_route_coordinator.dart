import 'dart:developer';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/osrm_routing_service.dart';
import 'package:Bahaar/services/marine_pathfinding_service.dart';
import 'package:Bahaar/services/marina_data_service.dart';
import 'package:Bahaar/services/navigation_mask.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/models/navigation/waypoint_model.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';

/// Service for orchestrating hybrid land-marine-land routing with marina handoffs
class HybridRouteCoordinator {
  final OsrmRoutingService _osrmService;
  final MarinePathfindingService _marineService;
  final MarinaDataService _marinaService;
  final NavigationMask _navigationMask;
  final GeoJsonLayerBuilder _geoJsonBuilder;

  HybridRouteCoordinator({
    required OsrmRoutingService osrmService,
    required MarinePathfindingService marineService,
    required MarinaDataService marinaService,
    required NavigationMask navigationMask,
    required GeoJsonLayerBuilder geoJsonBuilder,
  })  : _osrmService = osrmService,
        _marineService = marineService,
        _marinaService = marinaService,
        _navigationMask = navigationMask,
        _geoJsonBuilder = geoJsonBuilder;

  /// Calculate optimal route between origin and destination
  ///
  /// Automatically determines if route should be land-only, marine-only, or hybrid
  Future<NavigationRoute?> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    RoutePreference preference = RoutePreference.shortest,
  }) async {
    log('Calculating route from $origin to $destination');

    // Determine route type based on origin/destination locations
    final originOnWater = _navigationMask.isPointNavigable(origin);
    final destOnWater = _navigationMask.isPointNavigable(destination);

    log('Origin on water: $originOnWater, Destination on water: $destOnWater');

    NavigationRoute? route;

    if (!originOnWater && !destOnWater) {
      // Pure land route
      log('Calculating land-only route');
      route = await _calculateLandOnlyRoute(origin, destination);
    } else if (originOnWater && destOnWater) {
      // Pure marine route
      log('Calculating marine-only route');
      route = await _calculateMarineOnlyRoute(origin, destination);
    } else {
      // Hybrid route (the interesting case!)
      log('Calculating hybrid route');
      route = await _calculateHybridRoute(origin, destination, originOnWater);
    }

    // Validate route against restricted areas
    if (route != null) {
      route = _validateAndEnhance(route);
    }

    return route;
  }

  /// Calculate strict land-to-sea route (enforced pattern)
  ///
  /// REQUIRED ROUTING PATTERN:
  /// 1. Land origin (never water)
  /// 2. Auto-selected shore/port/marina
  /// 3. Sea destination (never land)
  ///
  /// Returns null if:
  /// - No suitable marina found
  /// - Land routing fails
  /// - Marine routing fails
  Future<NavigationRoute?> calculateLandToSeaRoute({
    required LatLng landOrigin,
    required LatLng seaDestination,
  }) async {
    log('Calculating strict land-to-sea route');
    log('  Land origin: $landOrigin');
    log('  Sea destination: $seaDestination');

    // VALIDATION: Enforce routing rules
    if (_navigationMask.isPointNavigable(landOrigin)) {
      log('ERROR: Origin is on water, must be on land');
      return null;
    }

    if (!_navigationMask.isPointNavigable(seaDestination)) {
      log('ERROR: Destination is on land, must be on water');
      return null;
    }

    // 1. Find optimal shore point (marina/port)
    final shorePoint = _marinaService.findBestShorePoint(
      landOrigin: landOrigin,
      seaDestination: seaDestination,
    );

    if (shorePoint == null) {
      log('ERROR: No suitable shore point found within search radius');
      return null;
    }

    log('Selected shore point: ${shorePoint.name} at ${shorePoint.location}');

    // 2. Calculate land segment: origin → shore
    log('Calculating land segment: $landOrigin → ${shorePoint.location}');
    final landSegment = await _osrmService.getRoute(
      origin: landOrigin,
      destination: shorePoint.location,
      profile: OsrmProfile.driving,
    );

    if (landSegment == null) {
      log('ERROR: Failed to calculate land route to shore point');
      return null;
    }

    log('Land segment: ${landSegment.distance}m, ${landSegment.duration}s');

    // 3. Calculate marine segment: shore → sea destination
    log('Calculating marine segment: ${shorePoint.location} → $seaDestination');
    final marineSegment = await _marineService.findMarineRoute(
      origin: shorePoint.location,
      destination: seaDestination,
      restrictedAreas: _getRestrictedAreas(),
    );

    if (marineSegment == null) {
      log('ERROR: Failed to calculate marine route from shore point');
      return null;
    }

    log('Marine segment: ${marineSegment.distance}m, ${marineSegment.duration}s');

    // 4. Assemble complete route
    final route = _buildRouteFromSegments(
      landOrigin,
      seaDestination,
      [landSegment, marineSegment],
    );

    log('Route assembled: ${route.totalDistance}m total');
    return route;
  }

  /// Calculate a hybrid route with marina handoff
  Future<NavigationRoute?> _calculateHybridRoute(
    LatLng origin,
    LatLng destination,
    bool startOnWater,
  ) async {
    final segments = <RouteSegment>[];

    if (startOnWater) {
      // Marine → Land transition
      log('Calculating Marine → Land hybrid route');

      // 1. Find nearest marina to destination
      final destMarina = _marinaService.findNearestMarina(destination);
      if (destMarina == null) {
        log('No marina found near destination');
        return null;
      }

      log('Using marina for land transition: ${destMarina.name}');

      // 2. Route marine segment: origin → destMarina
      final marineSegment = await _marineService.findMarineRoute(
        origin: origin,
        destination: destMarina.location,
        restrictedAreas: _getRestrictedAreas(),
      );

      if (marineSegment == null) {
        log('Failed to find marine route to marina');
        return null;
      }

      segments.add(marineSegment.copyWith(exitMarina: destMarina));

      // 3. Route land segment: destMarina → destination
      final landSegment = await _osrmService.getRoute(
        origin: destMarina.location,
        destination: destination,
      );

      if (landSegment == null) {
        log('Failed to find land route from marina');
        return null;
      }

      segments.add(landSegment.copyWith(entryMarina: destMarina));
    } else {
      // Land → Marine transition
      log('Calculating Land → Marine hybrid route');

      // 1. Find nearest marina to origin
      final originMarina = _marinaService.findNearestMarina(origin);
      if (originMarina == null) {
        log('No marina found near origin');
        return null;
      }

      log('Using marina for water transition: ${originMarina.name}');

      // 2. Route land segment: origin → originMarina
      final landSegment = await _osrmService.getRoute(
        origin: origin,
        destination: originMarina.location,
      );

      if (landSegment == null) {
        log('Failed to find land route to marina');
        return null;
      }

      segments.add(landSegment.copyWith(exitMarina: originMarina));

      // 3. Route marine segment: originMarina → destination
      final marineSegment = await _marineService.findMarineRoute(
        origin: originMarina.location,
        destination: destination,
        restrictedAreas: _getRestrictedAreas(),
      );

      if (marineSegment == null) {
        log('Failed to find marine route from marina');
        return null;
      }

      segments.add(marineSegment.copyWith(entryMarina: originMarina));
    }

    // Merge segments into complete route
    return _buildRouteFromSegments(origin, destination, segments);
  }

  /// Calculate land-only route
  Future<NavigationRoute?> _calculateLandOnlyRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final segment = await _osrmService.getRoute(
      origin: origin,
      destination: destination,
    );

    if (segment == null) return null;

    return _buildRouteFromSegments(origin, destination, [segment]);
  }

  /// Calculate marine-only route
  Future<NavigationRoute?> _calculateMarineOnlyRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final segment = await _marineService.findMarineRoute(
      origin: origin,
      destination: destination,
      restrictedAreas: _getRestrictedAreas(),
    );

    if (segment == null) return null;

    return _buildRouteFromSegments(origin, destination, [segment]);
  }

  /// Build complete navigation route from segments
  NavigationRoute _buildRouteFromSegments(
    LatLng origin,
    LatLng destination,
    List<RouteSegment> segments,
  ) {
    // Merge all segment geometries
    final fullGeometry = segments.expand((s) => s.geometry).toList();

    // Generate waypoints from segments
    final waypoints = _generateWaypoints(segments, origin, destination);

    // Calculate totals
    final totalDistance = segments.fold<double>(
      0,
      (sum, seg) => sum + seg.distance,
    );
    final totalDuration = segments.fold<int>(
      0,
      (sum, seg) => sum + seg.duration,
    );

    // Validate route
    final validation = _validateRouteGeometry(fullGeometry);

    // Calculate metrics
    final metrics = _calculateMetrics(segments, validation);

    return NavigationRoute(
      id: _generateRouteId(),
      origin: origin,
      destination: destination,
      segments: segments,
      geometry: fullGeometry,
      waypoints: waypoints,
      totalDistance: totalDistance,
      estimatedDuration: totalDuration,
      validation: validation,
      createdAt: DateTime.now(),
      metrics: metrics,
    );
  }

  /// Generate waypoints from route segments
  List<Waypoint> _generateWaypoints(
    List<RouteSegment> segments,
    LatLng origin,
    LatLng destination,
  ) {
    final waypoints = <Waypoint>[];
    double distanceAccumulator = 0;
    int timeAccumulator = 0;

    // Start waypoint
    waypoints.add(Waypoint(
      id: 'waypoint_start',
      location: origin,
      type: WaypointType.start,
      distanceFromStart: 0,
      instruction: 'Start navigation',
      estimatedTime: 0,
      segmentType: segments.first.type == SegmentType.land
          ? RouteSegmentType.land
          : RouteSegmentType.marine,
    ));

    // Segment transition waypoints
    for (int i = 0; i < segments.length - 1; i++) {
      final currentSegment = segments[i];
      distanceAccumulator += currentSegment.distance;
      timeAccumulator += currentSegment.duration;

      final transitionPoint = currentSegment.geometry.last;
      final nextSegment = segments[i + 1];

      // Determine transition type
      final isLandToMarine = currentSegment.type == SegmentType.land &&
          nextSegment.type == SegmentType.marine;
      final isMarineToLand = currentSegment.type == SegmentType.marine &&
          nextSegment.type == SegmentType.land;

      String instruction = 'Continue';
      WaypointType waypointType = WaypointType.intermediate;

      if (isLandToMarine) {
        final marina = currentSegment.exitMarina ?? nextSegment.entryMarina;
        instruction = 'Launch boat at ${marina?.name ?? "marina"}';
        waypointType = WaypointType.marinaEntry;
      } else if (isMarineToLand) {
        final marina = currentSegment.exitMarina ?? nextSegment.entryMarina;
        instruction = 'Dock boat at ${marina?.name ?? "marina"}';
        waypointType = WaypointType.marinaExit;
      }

      waypoints.add(Waypoint(
        id: 'waypoint_transition_$i',
        location: transitionPoint,
        type: waypointType,
        distanceFromStart: distanceAccumulator,
        instruction: instruction,
        estimatedTime: timeAccumulator,
        segmentType: RouteSegmentType.transition,
      ));
    }

    // End waypoint
    distanceAccumulator += segments.last.distance;
    timeAccumulator += segments.last.duration;

    waypoints.add(Waypoint(
      id: 'waypoint_end',
      location: destination,
      type: WaypointType.end,
      distanceFromStart: distanceAccumulator,
      instruction: 'Arrived at destination',
      estimatedTime: timeAccumulator,
      segmentType: segments.last.type == SegmentType.land
          ? RouteSegmentType.land
          : RouteSegmentType.marine,
    ));

    return waypoints;
  }

  /// Validate route geometry against navigation mask
  RouteValidation _validateRouteGeometry(List<LatLng> geometry) {
    return _navigationMask.validateRoute(geometry);
  }

  /// Get restricted area polygons from GeoJSON
  List<Polygon> _getRestrictedAreas() {
    return _geoJsonBuilder.buildRestrictedAreas(isVisible: true);
  }

  /// Calculate route metrics
  RouteMetrics _calculateMetrics(
    List<RouteSegment> segments,
    RouteValidation validation,
  ) {
    double landDistance = 0;
    double marineDistance = 0;
    int landDuration = 0;
    int marineDuration = 0;

    for (final segment in segments) {
      if (segment.type == SegmentType.land) {
        landDistance += segment.distance;
        landDuration += segment.duration;
      } else {
        marineDistance += segment.distance;
        marineDuration += segment.duration;
      }
    }

    return RouteMetrics(
      landDistance: landDistance,
      marineDistance: marineDistance,
      landDuration: landDuration,
      marineDuration: marineDuration,
      numRestrictedAreaViolations: validation.landPoints,
    );
  }

  /// Validate and enhance route
  NavigationRoute _validateAndEnhance(NavigationRoute route) {
    // Check for restricted area crossings
    if (!route.validation.isValid) {
      log('Warning: Route crosses ${route.validation.landPoints} restricted points');
    }

    return route;
  }

  /// Generate unique route ID
  String _generateRouteId() {
    return 'route_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Route calculation preferences
enum RoutePreference {
  shortest,
  fastest,
  safest,
}

/// Extension to add copyWith to RouteSegment
extension RouteSegmentCopyWith on RouteSegment {
  RouteSegment copyWith({
    SegmentType? type,
    List<LatLng>? geometry,
    double? distance,
    int? duration,
    String? transportMode,
    Marina? entryMarina,
    Marina? exitMarina,
  }) {
    return RouteSegment(
      type: type ?? this.type,
      geometry: geometry ?? this.geometry,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      transportMode: transportMode ?? this.transportMode,
      entryMarina: entryMarina ?? this.entryMarina,
      exitMarina: exitMarina ?? this.exitMarina,
    );
  }
}
