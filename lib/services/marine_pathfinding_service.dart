import 'dart:developer';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/navigation_mask.dart';
import 'package:Bahaar/services/marine_weather_service.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

/// Service for marine pathfinding using A* algorithm on water grid
class MarinePathfindingService {
  final NavigationMask _navigationMask;
  final MarineWeatherService? _weatherService;
  late int _gridWidth;
  late int _gridHeight;
  late double _resolution;
  late double _minLon;
  late double _minLat;
  late double _maxLon;
  late double _maxLat;

  MarinePathfindingService(this._navigationMask, {MarineWeatherService? weatherService})
      : _weatherService = weatherService {
    _initializeGridParameters();
  }

  /// Initialize grid parameters from navigation mask metadata
  void _initializeGridParameters() {
    final metadata = _navigationMask.getMetadata();
    final bbox = metadata['bbox'];
    final grid = metadata['grid'];

    _gridWidth = grid['width'] as int;
    _gridHeight = grid['height'] as int;
    _resolution = grid['resolution_degrees'] as double;

    _minLon = bbox['min_lon'] as double;
    _minLat = bbox['min_lat'] as double;
    _maxLon = bbox['max_lon'] as double;
    _maxLat = bbox['max_lat'] as double;

    log('Marine pathfinding initialized: ${_gridWidth}x$_gridHeight grid');
  }

  /// Find marine route between two points using A* pathfinding
  ///
  /// Returns null if no path exists or points are not on water
  Future<RouteSegment?> findMarineRoute({
    required LatLng origin,
    required LatLng destination,
    required List<Polygon> restrictedAreas,
  }) async {
    log('Finding marine route from $origin to $destination');

    // 1. Snap start/end to navigable water grid
    final startCell = _snapToWaterGrid(origin);
    final endCell = _snapToWaterGrid(destination);

    if (startCell == null) {
      log('Origin is not on water or too far from water');
      return null;
    }

    if (endCell == null) {
      log('Destination is not on water or too far from water');
      return null;
    }

    // 2. Run A* pathfinding
    final stopwatch = Stopwatch()..start();
    final path = await _aStarSearch(startCell, endCell, restrictedAreas);
    stopwatch.stop();

    if (path == null || path.isEmpty) {
      log('No marine path found');
      return null;
    }

    log('Marine path found: ${path.length} cells in ${stopwatch.elapsedMilliseconds}ms');

    // 3. Convert grid path to geographic coordinates
    final geometry = path.map((cell) => _cellToLatLng(cell)).toList();

    // 4. Calculate metrics
    final distance = _calculatePathDistance(geometry);
    final duration = _estimateMarineDuration(distance);

    return RouteSegment(
      type: SegmentType.marine,
      geometry: geometry,
      distance: distance,
      duration: duration,
      transportMode: 'boat',
    );
  }

  /// Snap a point to the nearest water grid cell
  GridCell? _snapToWaterGrid(LatLng point) {
    // First check if point is already on water
    if (_navigationMask.isPointNavigable(point)) {
      return _latLngToCell(point);
    }

    // Find nearest water within snap distance
    final nearestWater = _navigationMask.findNearestWaterPoint(
      point,
      maxSearchRadius: NavigationConstants.maxWaterSnapDistance.toInt(),
    );

    if (nearestWater == null) {
      return null;
    }

    return _latLngToCell(nearestWater);
  }

  /// A* pathfinding algorithm
  ///
  /// Returns list of grid cells forming the path, or null if no path exists
  Future<List<GridCell>?> _aStarSearch(
    GridCell start,
    GridCell goal,
    List<Polygon> restrictedAreas,
  ) async {
    // Priority queue for open set (cells to explore)
    final openSet = PriorityQueue<AStarNode>((a, b) => a.fScore.compareTo(b.fScore));

    // Closed set (already explored)
    final closedSet = <GridCell>{};

    // G-scores (cost from start to each cell)
    final gScores = <GridCell, double>{start: 0};

    // Came-from map for path reconstruction
    final cameFrom = <GridCell, GridCell>{};

    // Add start node to open set
    openSet.add(AStarNode(
      cell: start,
      gScore: 0,
      hScore: _heuristic(start, goal),
    ));

    int iterations = 0;
    final startTime = DateTime.now();

    while (openSet.isNotEmpty) {
      iterations++;

      // Check timeout
      if (iterations > NavigationConstants.aStarMaxIterations ||
          DateTime.now().difference(startTime).inSeconds >
              NavigationConstants.aStarTimeoutSeconds) {
        log('A* timeout or max iterations reached');
        return null;
      }

      // Get cell with lowest f-score
      final current = openSet.removeFirst();

      // Goal reached!
      if (current.cell == goal) {
        log('A* completed in $iterations iterations');
        return _reconstructPath(cameFrom, goal);
      }

      closedSet.add(current.cell);

      // Explore neighbors
      for (final neighbor in _getNeighbors(current.cell)) {
        if (closedSet.contains(neighbor)) continue;

        // Check if neighbor is navigable water
        if (!_isCellNavigable(neighbor)) continue;

        // HARD BLOCK: Skip cells in restricted areas (no penalty, absolute block)
        if (_isInRestrictedArea(neighbor, restrictedAreas)) continue;

        // HARD BLOCK: Skip cells with blocked weather conditions
        if (_isWeatherBlocked(neighbor)) continue;

        // Calculate movement cost
        final moveCost = _getMoveCost(current.cell, neighbor);
        final tentativeGScore = gScores[current.cell]! + moveCost;

        // Update if this is a better path
        if (!gScores.containsKey(neighbor) || tentativeGScore < gScores[neighbor]!) {
          cameFrom[neighbor] = current.cell;
          gScores[neighbor] = tentativeGScore;

          // Add to open set if not already there
          openSet.add(AStarNode(
            cell: neighbor,
            gScore: tentativeGScore,
            hScore: _heuristic(neighbor, goal),
          ));
        }
      }
    }

    // No path found
    log('A* failed to find path after $iterations iterations');
    return null;
  }

  /// Heuristic function (Euclidean distance)
  double _heuristic(GridCell a, GridCell b) {
    final dx = (a.col - b.col).abs();
    final dy = (a.row - b.row).abs();
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Get movement cost between two adjacent cells
  double _getMoveCost(GridCell from, GridCell to) {
    // Diagonal moves cost more (sqrt(2) ≈ 1.414)
    final isDiagonal = (from.col != to.col) && (from.row != to.row);
    double baseCost = isDiagonal ? NavigationConstants.aStarDiagonalCost : 1.0;

    // Apply weather-based cost multiplier
    if (_weatherService != null && _weatherService!.hasData) {
      final assessment = _weatherService!.getAssessmentForCell(
        to.row, to.col,
        minLat: _minLat,
        minLon: _minLon,
        resolution: _resolution,
        gridHeight: _gridHeight,
      );
      if (assessment != null && assessment.costMultiplier.isFinite) {
        baseCost *= assessment.costMultiplier;
      }
    }

    return baseCost;
  }

  /// Check if a cell is blocked due to dangerous weather conditions
  bool _isWeatherBlocked(GridCell cell) {
    if (_weatherService == null || !_weatherService!.hasData) return false;

    final assessment = _weatherService!.getAssessmentForCell(
      cell.row, cell.col,
      minLat: _minLat,
      minLon: _minLon,
      resolution: _resolution,
      gridHeight: _gridHeight,
    );

    return assessment != null && assessment.level == SafetyLevel.blocked;
  }

  /// Check if a cell is inside any restricted area (HARD BLOCK)
  bool _isInRestrictedArea(GridCell cell, List<Polygon> restrictedAreas) {
    final point = _cellToLatLng(cell);

    for (final area in restrictedAreas) {
      if (_isPointInPolygon(point, area.points)) {
        return true;  // Cell is in restricted area - block it
      }
    }

    return false;  // Cell is safe to use
  }

  /// Check if a cell is navigable (on water and in bounds)
  bool _isCellNavigable(GridCell cell) {
    if (cell.row < 0 || cell.row >= _gridHeight) return false;
    if (cell.col < 0 || cell.col >= _gridWidth) return false;

    final point = _cellToLatLng(cell);
    return _navigationMask.isPointNavigable(point);
  }

  /// Get 8-directional neighbors of a cell
  List<GridCell> _getNeighbors(GridCell cell) {
    return [
      GridCell(cell.row - 1, cell.col - 1), // NW
      GridCell(cell.row - 1, cell.col),     // N
      GridCell(cell.row - 1, cell.col + 1), // NE
      GridCell(cell.row, cell.col - 1),     // W
      GridCell(cell.row, cell.col + 1),     // E
      GridCell(cell.row + 1, cell.col - 1), // SW
      GridCell(cell.row + 1, cell.col),     // S
      GridCell(cell.row + 1, cell.col + 1), // SE
    ];
  }

  /// Reconstruct path from came-from map
  List<GridCell> _reconstructPath(
    Map<GridCell, GridCell> cameFrom,
    GridCell goal,
  ) {
    final path = <GridCell>[goal];
    var current = goal;

    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }

    return path;
  }

  /// Point-in-polygon test using ray casting algorithm
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    final n = polygon.length;

    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];

      // Check if point is on the same horizontal line
      if ((p1.latitude <= point.latitude && point.latitude < p2.latitude) ||
          (p2.latitude <= point.latitude && point.latitude < p1.latitude)) {
        // Calculate x-coordinate of intersection
        final x = p1.longitude +
            (point.latitude - p1.latitude) *
                (p2.longitude - p1.longitude) /
                (p2.latitude - p1.latitude);

        if (point.longitude < x) {
          intersections++;
        }
      }
    }

    // Odd number of intersections = inside polygon
    return intersections % 2 == 1;
  }

  /// Convert LatLng to grid cell
  GridCell _latLngToCell(LatLng point) {
    final col = ((point.longitude - _minLon) / _resolution).floor();
    final row = (_gridHeight - 1) -
        ((point.latitude - _minLat) / _resolution).floor();

    return GridCell(
      row.clamp(0, _gridHeight - 1),
      col.clamp(0, _gridWidth - 1),
    );
  }

  /// Convert grid cell to LatLng (cell center)
  LatLng _cellToLatLng(GridCell cell) {
    final lon = _minLon + (cell.col + 0.5) * _resolution;
    final lat = _minLat + ((_gridHeight - 1 - cell.row) + 0.5) * _resolution;

    return LatLng(lat, lon);
  }

  /// Calculate total distance along a path
  double _calculatePathDistance(List<LatLng> path) {
    if (path.length < 2) return 0;

    double distance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      distance += _navigationMask.calculateDistance(path[i], path[i + 1]);
    }

    return distance;
  }

  /// Estimate duration for marine route
  int _estimateMarineDuration(double distanceMeters) {
    // Use average boat speed from constants
    return (distanceMeters / NavigationConstants.averageBoatSpeedMs).round();
  }
}

/// Grid cell representation
class GridCell {
  final int row;
  final int col;

  const GridCell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridCell($row, $col)';
}

/// A* algorithm node
class AStarNode {
  final GridCell cell;
  final double gScore;
  final double hScore;

  const AStarNode({
    required this.cell,
    required this.gScore,
    required this.hScore,
  });

  double get fScore => gScore + hScore;

  @override
  String toString() => 'AStarNode($cell, f=${fScore.toStringAsFixed(2)})';
}
