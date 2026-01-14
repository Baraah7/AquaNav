import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';
import 'package:Bahaar/services/navigation_mask.dart';

/// Service for loading, validating, and querying marina/launch point data
class MarinaDataService {
  List<Marina>? _marinas;
  NavigationMask? _navigationMask;
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get all loaded marinas
  List<Marina> get marinas => _marinas ?? [];

  /// Initialize the marina data service
  /// Loads marinas from GeoJSON, validates water connectivity, and filters restricted areas
  Future<void> initialize(NavigationMask navigationMask) async {
    _navigationMask = navigationMask;

    // 1. Load manual GeoJSON data
    final manualMarinas = await _loadManualMarinas();

    // 2. Validate water connectivity
    final validatedMarinas = _validateMarinas(manualMarinas, navigationMask);

    // 3. Filter by restricted areas (for now, just store all)
    // TODO: Implement restricted area filtering when GeoJsonLayerBuilder is available
    _marinas = validatedMarinas;

    _isInitialized = true;
  }

  /// Load marinas from the manual GeoJSON file
  Future<List<Marina>> _loadManualMarinas() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/marinas.geojson');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final features = data['features'] as List;

      return features
          .map((feature) => Marina.fromJson(feature as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load marinas.geojson: $e');
    }
  }

  /// Validate marinas for water connectivity
  List<Marina> _validateMarinas(List<Marina> marinas, NavigationMask mask) {
    return marinas.where((marina) {
      // Check if marina location is on water
      return mask.isPointNavigable(marina.location);
    }).toList();
  }

  /// Find the nearest marina to a given point
  /// Returns null if no marina is found within maxDistance
  Marina? findNearestMarina(LatLng point, {double maxDistance = 5000}) {
    if (!_isInitialized || _marinas == null || _marinas!.isEmpty) {
      return null;
    }

    Marina? nearest;
    double minDistance = maxDistance;

    for (final marina in _marinas!) {
      final distance = _navigationMask!.calculateDistance(point, marina.location);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = marina;
      }
    }

    return nearest;
  }

  /// Find all marinas within a given radius from a center point
  List<Marina> findMarinasInRadius(LatLng center, double radiusMeters) {
    if (!_isInitialized || _marinas == null) return [];

    return _marinas!.where((marina) {
      final distance = _navigationMask!.calculateDistance(center, marina.location);
      return distance <= radiusMeters;
    }).toList();
  }

  /// Get all marinas of a specific type
  List<Marina> getMarinasByType(MarinaType type) {
    if (!_isInitialized || _marinas == null) return [];
    return _marinas!.where((marina) => marina.type == type).toList();
  }

  /// Get all public access marinas
  List<Marina> getPublicMarinas() {
    if (!_isInitialized || _marinas == null) return [];
    return _marinas!.where((marina) =>
      marina.accessType == MarinaAccessType.public ||
      marina.accessType == MarinaAccessType.permissive
    ).toList();
  }

  /// Get marina by ID
  Marina? getMarinaById(String id) {
    if (!_isInitialized || _marinas == null) return null;
    try {
      return _marinas!.firstWhere((marina) => marina.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all marinas
  List<Marina> getAllMarinas() {
    return _marinas ?? [];
  }

  /// Get count of loaded marinas
  int get marinaCount => _marinas?.length ?? 0;

  /// Filter marinas that are inside restricted areas
  /// This will be implemented when integrated with GeoJsonLayerBuilder
  Future<List<Marina>> filterRestrictedMarinas(
    List<Marina> marinas,
    List<Polygon> restrictedAreas,
  ) async {
    // TODO: Implement point-in-polygon check for each marina
    // For now, return all marinas
    return marinas;
  }

  /// Check if a marina is accessible (public or permissive)
  bool isMarinaAccessible(Marina marina) {
    return marina.accessType == MarinaAccessType.public ||
        marina.accessType == MarinaAccessType.permissive;
  }

  /// Get marinas sorted by distance from a point
  List<Marina> getMarinasNearby(LatLng point, {int limit = 5}) {
    if (!_isInitialized || _marinas == null) return [];

    final marinasWithDistance = _marinas!.map((marina) {
      final distance = _navigationMask!.calculateDistance(point, marina.location);
      return {'marina': marina, 'distance': distance};
    }).toList();

    // Sort by distance
    marinasWithDistance.sort((a, b) =>
      (a['distance'] as double).compareTo(b['distance'] as double)
    );

    // Take top N and extract marinas
    return marinasWithDistance
        .take(limit)
        .map((item) => item['marina'] as Marina)
        .toList();
  }

  /// Clear all loaded data
  void dispose() {
    _marinas = null;
    _navigationMask = null;
    _isInitialized = false;
  }
}
