import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'package:Bahaar/services/mask_storage_service.dart';

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

  // Storage service for persistence
  final MaskStorageService _storageService = MaskStorageService();

  // Track if mask has unsaved changes
  bool _hasUnsavedChanges = false;

  // Track if using user-modified mask
  bool _isUserModified = false;

  /// Check if the mask has been initialized
  bool get isInitialized => _isInitialized;

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Check if mask is user-modified
  bool get isUserModified => _isUserModified;

  /// Get grid width
  int get width => _width;

  /// Get grid height
  int get height => _height;

  /// Get grid resolution in degrees
  double get resolution => _resolution;

  /// Get minimum longitude
  double get minLon => _minLon;

  /// Get maximum longitude
  double get maxLon => _maxLon;

  /// Get minimum latitude
  double get minLat => _minLat;

  /// Get maximum latitude
  double get maxLat => _maxLat;

  /// Get raw mask data (for visualization)
  Uint8List get maskData => _maskData;

  /// Initialize the navigation mask by loading binary data and metadata
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load asset metadata (needed for default values and reset)
      final metadataJson = await rootBundle.loadString('assets/navigation/mask_metadata.json');
      _metadata = json.decode(metadataJson);

      // Try to load user's modified mask first (with its own metadata)
      final userMask = await _storageService.loadUserMask();
      if (userMask != null) {
        // Use user's saved dimensions
        _maskData = userMask.maskData;
        _width = userMask.width;
        _height = userMask.height;
        _minLon = userMask.minLon;
        _maxLon = userMask.maxLon;
        _minLat = userMask.minLat;
        _maxLat = userMask.maxLat;
        _resolution = userMask.resolution;
        _isUserModified = true;

        // Update metadata to match
        _metadata['bbox']['min_lon'] = _minLon;
        _metadata['bbox']['max_lon'] = _maxLon;
        _metadata['bbox']['min_lat'] = _minLat;
        _metadata['bbox']['max_lat'] = _maxLat;
        _metadata['grid']['width'] = _width;
        _metadata['grid']['height'] = _height;
      } else {
        // Fall back to asset mask with original dimensions
        _minLon = _metadata['bbox']['min_lon'].toDouble();
        _minLat = _metadata['bbox']['min_lat'].toDouble();
        _maxLon = _metadata['bbox']['max_lon'].toDouble();
        _maxLat = _metadata['bbox']['max_lat'].toDouble();
        _width = _metadata['grid']['width'];
        _height = _metadata['grid']['height'];
        _resolution = _metadata['grid']['resolution_degrees'].toDouble();

        final ByteData byteData = await rootBundle.load('assets/navigation/bahrain_navigation_mask.bin');
        _maskData = Uint8List.fromList(byteData.buffer.asUint8List());
      }

      _isInitialized = true;
    } catch (e) {
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

  /// Get all water cells as LatLng polygons for visualization
  /// Returns a list of polygons representing water cell boundaries
  List<List<LatLng>> getWaterCellPolygons() {
    if (!_isInitialized) return [];

    final polygons = <List<LatLng>>[];
    final halfRes = _resolution / 2;

    for (int row = 0; row < _height; row++) {
      for (int col = 0; col < _width; col++) {
        final index = row * _width + col;
        if (index < _maskData.length && _maskData[index] == 1) {
          final center = _gridToCoords(row, col);
          polygons.add([
            LatLng(center.latitude - halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude + halfRes),
            LatLng(center.latitude - halfRes, center.longitude + halfRes),
          ]);
        }
      }
    }
    return polygons;
  }

  /// Get boundary cells (water cells adjacent to land or edge)
  /// More efficient for outline visualization
  List<LatLng> getBoundaryWaterCells() {
    if (!_isInitialized) return [];

    final boundaryCells = <LatLng>[];

    for (int row = 0; row < _height; row++) {
      for (int col = 0; col < _width; col++) {
        final index = row * _width + col;
        if (index >= _maskData.length || _maskData[index] != 1) continue;

        // Check if this water cell is on the boundary
        bool isBoundary = false;

        // Check all 4 neighbors
        final neighbors = [
          (row - 1, col), // top
          (row + 1, col), // bottom
          (row, col - 1), // left
          (row, col + 1), // right
        ];

        for (final (nRow, nCol) in neighbors) {
          if (nRow < 0 || nRow >= _height || nCol < 0 || nCol >= _width) {
            // Edge of grid
            isBoundary = true;
            break;
          }
          final nIndex = nRow * _width + nCol;
          if (nIndex >= _maskData.length || _maskData[nIndex] == 0) {
            // Adjacent to land
            isBoundary = true;
            break;
          }
        }

        if (isBoundary) {
          boundaryCells.add(_gridToCoords(row, col));
        }
      }
    }
    return boundaryCells;
  }

  // ============================================================
  // Admin Editing Methods
  // ============================================================

  /// Convert geographic coordinates to grid indices (public for editing)
  ({int? row, int? col}) coordsToGrid(double lon, double lat) {
    return _coordsToGrid(lon, lat);
  }

  /// Convert grid indices to geographic coordinates (public for editing)
  LatLng gridToCoords(int row, int col) {
    return _gridToCoords(row, col);
  }

  /// Set a cell to water (1) or land (0)
  bool setCellValue(int row, int col, int value) {
    if (!_isInitialized) return false;
    if (row < 0 || row >= _height || col < 0 || col >= _width) return false;
    if (value != 0 && value != 1) return false;

    final index = row * _width + col;
    if (index >= _maskData.length) return false;

    _maskData[index] = value;
    _hasUnsavedChanges = true;
    return true;
  }

  /// Set a cell at geographic coordinates to water (1) or land (0)
  bool setCellAtCoords(double lon, double lat, int value) {
    final grid = _coordsToGrid(lon, lat);
    if (grid.row == null || grid.col == null) return false;
    return setCellValue(grid.row!, grid.col!, value);
  }

  /// Paint cells in a circular radius (brush tool)
  /// Returns list of cells that were painted
  /// If painting outside bounds, the mask will be expanded
  List<({int row, int col})> paintBrush(double lon, double lat, int radius, int value) {
    final painted = <({int row, int col})>[];

    // Check if we need to expand the mask
    final needsExpansion = !isInBounds(lon, lat);
    if (needsExpansion) {
      _expandMaskToInclude(lon, lat, radius);
    }

    final center = _coordsToGrid(lon, lat);
    if (center.row == null || center.col == null) return painted;

    for (int dr = -radius; dr <= radius; dr++) {
      for (int dc = -radius; dc <= radius; dc++) {
        // Circular brush (not square)
        if (dr * dr + dc * dc <= radius * radius) {
          final row = center.row! + dr;
          final col = center.col! + dc;
          if (setCellValue(row, col, value)) {
            painted.add((row: row, col: col));
          }
        }
      }
    }
    return painted;
  }

  /// Expand the mask grid to include coordinates outside current bounds
  void _expandMaskToInclude(double lon, double lat, int extraCells) {
    if (!_isInitialized) return;

    // Calculate new bounds with some padding
    final padding = _resolution * (extraCells + 5); // Add extra padding
    final newMinLon = lon < _minLon ? lon - padding : _minLon;
    final newMaxLon = lon > _maxLon ? lon + padding : _maxLon;
    final newMinLat = lat < _minLat ? lat - padding : _minLat;
    final newMaxLat = lat > _maxLat ? lat + padding : _maxLat;

    // Calculate new grid dimensions
    final newWidth = ((newMaxLon - newMinLon) / _resolution).ceil() + 1;
    final newHeight = ((newMaxLat - newMinLat) / _resolution).ceil() + 1;

    // Create new mask data (default to land/0)
    final newMaskData = Uint8List(newWidth * newHeight);

    // Calculate offset for copying old data
    final colOffset = (((_minLon - newMinLon) / _resolution)).round();
    final rowOffset = (((newMaxLat - _maxLat) / _resolution)).round();

    // Copy old mask data to new position
    for (int oldRow = 0; oldRow < _height; oldRow++) {
      for (int oldCol = 0; oldCol < _width; oldCol++) {
        final oldIndex = oldRow * _width + oldCol;
        final newRow = oldRow + rowOffset;
        final newCol = oldCol + colOffset;

        if (newRow >= 0 && newRow < newHeight && newCol >= 0 && newCol < newWidth) {
          final newIndex = newRow * newWidth + newCol;
          if (oldIndex < _maskData.length && newIndex < newMaskData.length) {
            newMaskData[newIndex] = _maskData[oldIndex];
          }
        }
      }
    }

    // Update mask properties
    _maskData = newMaskData;
    _minLon = newMinLon;
    _maxLon = newMaxLon;
    _minLat = newMinLat;
    _maxLat = newMaxLat;
    _width = newWidth;
    _height = newHeight;
    _hasUnsavedChanges = true;

    // Update metadata
    _metadata['bbox']['min_lon'] = newMinLon;
    _metadata['bbox']['max_lon'] = newMaxLon;
    _metadata['bbox']['min_lat'] = newMinLat;
    _metadata['bbox']['max_lat'] = newMaxLat;
    _metadata['grid']['width'] = newWidth;
    _metadata['grid']['height'] = newHeight;
  }

  /// Save modifications to local storage
  Future<bool> saveChanges() async {
    if (!_hasUnsavedChanges) return true;
    final success = await _storageService.saveUserMask(
      _maskData,
      width: _width,
      height: _height,
      minLon: _minLon,
      maxLon: _maxLon,
      minLat: _minLat,
      maxLat: _maxLat,
      resolution: _resolution,
    );
    if (success) {
      _hasUnsavedChanges = false;
      _isUserModified = true;
    }
    return success;
  }

  /// Reset to original asset mask
  Future<bool> resetToOriginal() async {
    final success = await _storageService.resetToAssetMask();
    if (success) {
      // Reload original metadata from asset
      final metadataJson = await rootBundle.loadString('assets/navigation/mask_metadata.json');
      _metadata = json.decode(metadataJson);

      // Restore original dimensions
      _minLon = _metadata['bbox']['min_lon'].toDouble();
      _minLat = _metadata['bbox']['min_lat'].toDouble();
      _maxLon = _metadata['bbox']['max_lon'].toDouble();
      _maxLat = _metadata['bbox']['max_lat'].toDouble();
      _width = _metadata['grid']['width'];
      _height = _metadata['grid']['height'];
      _resolution = _metadata['grid']['resolution_degrees'].toDouble();

      // Reload from asset
      final ByteData byteData = await rootBundle.load('assets/navigation/bahrain_navigation_mask.bin');
      _maskData = Uint8List.fromList(byteData.buffer.asUint8List());
      _hasUnsavedChanges = false;
      _isUserModified = false;
    }
    return success;
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
