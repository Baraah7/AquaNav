import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'dart:math';

/// Navigation mask service for validating routes against Bahrain's coastline
/// Prevents routing through land areas using pre-generated binary mask data
class NavigationMask {
  late Uint8List _maskData;
  late Map<String, dynamic> _metadata;
  bool _isInitialized = false;

  // Bounding box coordinates
  late double _minLon;
  late double _minLat;
  late double _maxLon;
  late double _maxLat;

  // Grid dimensions
  late int _width;
  late int _height;
  late double _resolution;

  /// Check if the mask has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the navigation mask by loading binary data and metadata
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load metadata
      final metadataJson = await rootBundle.loadString('assets/navigation/mask_metadata.json');
      _metadata = json.decode(metadataJson);

      // Parse metadata
      _minLon = _metadata['bbox']['min_lon'].toDouble();
      _minLat = _metadata['bbox']['min_lat'].toDouble();
      _maxLon = _metadata['bbox']['max_lon'].toDouble();
      _maxLat = _metadata['bbox']['max_lat'].toDouble();
      _width = _metadata['grid']['width'];
      _height = _metadata['grid']['height'];
      _resolution = _metadata['grid']['resolution_degrees'].toDouble();

      // Load binary mask data
      final ByteData byteData = await rootBundle.load('assets/navigation/bahrain_navigation_mask.bin');
      _maskData = byteData.buffer.asUint8List();

      _isInitialized = true;
      // Navigation mask initialized successfully
    } catch (e) {
      // Error initializing navigation mask
      rethrow;
    }
  }

  /// Convert geographic coordinates to grid indices
  /// Returns null if coordinates are outside the bounding box
  ({int? row, int? col}) _coordsToGrid(double lon, double lat) {
    if (lon < _minLon || lon > _maxLon || lat < _minLat || lat > _maxLat) {
      return (row: null, col: null);
    }

    // Calculate grid position
    final col = ((lon - _minLon) / _resolution).floor();
    final row = ((_maxLat - lat) / _resolution).floor(); // Flip Y axis

    // Clamp to grid bounds
    final clampedCol = col.clamp(0, _width - 1);
    final clampedRow = row.clamp(0, _height - 1);

    return (row: clampedRow, col: clampedCol);
  }

  /// Convert grid indices to geographic coordinates (center of cell)
  LatLng _gridToCoords(int row, int col) {
    final lon = _minLon + (col + 0.5) * _resolution;
    final lat = _maxLat - (row + 0.5) * _resolution;
    return LatLng(lat, lon);
  }

  /// Check if a location is navigable (water)
  /// Returns true for water (navigable), false for land (blocked)
  bool isNavigable(double lon, double lat) {
    if (!_isInitialized) {
      throw StateError('NavigationMask not initialized. Call initialize() first.');
    }

    final grid = _coordsToGrid(lon, lat);
    if (grid.row == null || grid.col == null) {
      // Outside mask bounds - assume not navigable
      return false;
    }

    final index = grid.row! * _width + grid.col!;
    if (index >= _maskData.length) {
      return false;
    }

    // 1 = water (navigable), 0 = land (blocked)
    return _maskData[index] == 1;
  }

  /// Check if a LatLng point is navigable
  bool isPointNavigable(LatLng point) {
    return isNavigable(point.longitude, point.latitude);
  }

  /// Find the nearest navigable water location to a given point
  /// Searches in expanding circles up to maxSearchRadius cells
  LatLng? findNearestWater(double lon, double lat, {int maxSearchRadius = 50}) {
    if (!_isInitialized) {
      throw StateError('NavigationMask not initialized. Call initialize() first.');
    }

    final startGrid = _coordsToGrid(lon, lat);
    if (startGrid.row == null || startGrid.col == null) {
      return null;
    }

    // If already on water, return original location
    if (isNavigable(lon, lat)) {
      return LatLng(lat, lon);
    }

    // Expanding circle search
    for (int radius = 1; radius <= maxSearchRadius; radius++) {
      for (int dRow = -radius; dRow <= radius; dRow++) {
        for (int dCol = -radius; dCol <= radius; dCol++) {
          // Only check points on the circle perimeter (optimization)
          if (dRow.abs() != radius && dCol.abs() != radius) continue;

          final checkRow = startGrid.row! + dRow;
          final checkCol = startGrid.col! + dCol;

          if (checkRow < 0 || checkRow >= _height || checkCol < 0 || checkCol >= _width) {
            continue;
          }

          final index = checkRow * _width + checkCol;
          if (index < _maskData.length && _maskData[index] == 1) {
            return _gridToCoords(checkRow, checkCol);
          }
        }
      }
    }

    return null; // No water found within search radius
  }

  /// Find the nearest water location to a LatLng point
  LatLng? findNearestWaterPoint(LatLng point, {int maxSearchRadius = 50}) {
    return findNearestWater(point.longitude, point.latitude, maxSearchRadius: maxSearchRadius);
  }

  /// Validate a route and check if all points are navigable
  /// Returns a validation result with details
  RouteValidation validateRoute(List<LatLng> route) {
    if (!_isInitialized) {
      throw StateError('NavigationMask not initialized. Call initialize() first.');
    }

    int landPoints = 0;
    int waterPoints = 0;
    final List<int> landPointIndices = [];

    for (int i = 0; i < route.length; i++) {
      final point = route[i];
      if (isNavigable(point.longitude, point.latitude)) {
        waterPoints++;
      } else {
        landPoints++;
        landPointIndices.add(i);
      }
    }

    return RouteValidation(
      isValid: landPoints == 0,
      totalPoints: route.length,
      waterPoints: waterPoints,
      landPoints: landPoints,
      landPointIndices: landPointIndices,
    );
  }

  /// Calculate great circle distance between two points (in meters)
  double calculateDistance(LatLng from, LatLng to) {
    const earthRadius = 6371000.0; // meters

    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLat = (to.latitude - from.latitude) * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Check if coordinates are within the mask's bounding box
  bool isInBounds(double lon, double lat) {
    return lon >= _minLon && lon <= _maxLon && lat >= _minLat && lat <= _maxLat;
  }

  /// Get mask metadata
  Map<String, dynamic> getMetadata() {
    if (!_isInitialized) {
      throw StateError('NavigationMask not initialized. Call initialize() first.');
    }
    return Map.from(_metadata);
  }
}

/// Result of route validation
class RouteValidation {
  final bool isValid;
  final int totalPoints;
  final int waterPoints;
  final int landPoints;
  final List<int> landPointIndices;

  RouteValidation({
    required this.isValid,
    required this.totalPoints,
    required this.waterPoints,
    required this.landPoints,
    required this.landPointIndices,
  });

  double get validPercentage => (waterPoints / totalPoints) * 100;

  @override
  String toString() {
    return 'RouteValidation(valid: $isValid, water: $waterPoints/$totalPoints, land: $landPoints)';
  }
}
