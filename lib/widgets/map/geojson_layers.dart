import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Service for parsing and managing GeoJSON data on the map
class GeoJsonLayerBuilder {
  final Map<String, dynamic> geoJsonData;

  GeoJsonLayerBuilder(this.geoJsonData);

  /// Extract features by type from GeoJSON
  List<Map<String, dynamic>> getFeaturesByType(String type) {
    final features = geoJsonData['features'] as List;
    return features
        .where((f) => f['properties']['type'] == type)
        .map((f) => f as Map<String, dynamic>)
        .toList();
  }

  /// Build fishing spot markers from GeoJSON
  List<Marker> buildFishingSpotMarkers({bool isVisible = true}) {
    if (!isVisible) return [];

    final spots = getFeaturesByType('fishing_spot');
    return spots.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final name = feature['properties']['name'] as String?;

      return Marker(
        point: LatLng(coords[1], coords[0]), // GeoJSON is [lng, lat]
        width: 30,
        height: 30,
        child: Tooltip(
          message: name ?? 'Fishing Spot',
          child: Icon(
            Icons.location_on,
            color: Colors.blue.withValues(alpha: 0.8),
            size: 25,
          ),
        ),
      );
    }).toList();
  }

  /// Build shipping lanes polylines from GeoJSON
  List<Polyline> buildShippingLanes({bool isVisible = true}) {
    if (!isVisible) return [];

    final lanes = getFeaturesByType('shipping_lane');
    final routes = getFeaturesByType('patrol_route');
    final allLines = [...lanes, ...routes];

    return allLines.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final type = feature['properties']['type'] as String;

      return Polyline(
        points: coords.map((coord) {
          return LatLng(coord[1], coord[0]); // GeoJSON is [lng, lat]
        }).toList(),
        strokeWidth: type == 'shipping_lane' ? 3.0 : 2.0,
        color: type == 'shipping_lane'
            ? Colors.red.withValues(alpha: 0.6)
            : Colors.orange.withValues(alpha: 0.6),
      );
    }).toList();
  }

  /// Build protected zone polygons from GeoJSON
  List<Polygon> buildProtectedZones({bool isVisible = true}) {
    if (!isVisible) return [];

    final polygons = <Polygon>[];
    final protected = getFeaturesByType('protected_zone');
    final reefs = getFeaturesByType('reef');

    for (final feature in [...protected, ...reefs]) {
      final coords = feature['geometry']['coordinates'][0] as List;
      final type = feature['properties']['type'] as String;

      polygons.add(Polygon(
        points: coords.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList(),
        color: type == 'protected_zone'
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.brown.withValues(alpha: 0.15),
        borderStrokeWidth: 2.0,
        borderColor: type == 'protected_zone'
            ? Colors.red.withValues(alpha: 0.6)
            : Colors.brown.withValues(alpha: 0.6),
      ));
    }

    return polygons;
  }

  /// Build fishing zone polygons from GeoJSON
  List<Polygon> buildFishingZones({bool isVisible = true}) {
    if (!isVisible) return [];

    final zones = getFeaturesByType('fishing_zone');
    final polygons = <Polygon>[];

    for (final feature in zones) {
      final coords = feature['geometry']['coordinates'][0] as List;

      polygons.add(Polygon(
        points: coords.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList(),
        color: Colors.green.withValues(alpha: 0.15),
        borderStrokeWidth: 2.0,
        borderColor: Colors.green.withValues(alpha: 0.6),
      ));
    }

    return polygons;
  }

  /// Build all zone polygons (protected + fishing zones)
  List<Polygon> buildAllZones({
    bool showProtected = true,
    bool showFishing = true,
  }) {
    return [
      ...buildProtectedZones(isVisible: showProtected),
      ...buildFishingZones(isVisible: showFishing),
    ];
  }

  /// Get feature count by type
  int getFeatureCount(String type) {
    return getFeaturesByType(type).length;
  }

  /// Get all feature types in the GeoJSON
  Set<String> getAllFeatureTypes() {
    final features = geoJsonData['features'] as List;
    return features
        .map((f) => f['properties']['type'] as String)
        .toSet();
  }
}

/// Widget for displaying GeoJSON features on the map
class GeoJsonMapLayers extends StatelessWidget {
  final GeoJsonLayerBuilder builder;
  final bool showFishingSpots;
  final bool showShippingLanes;
  final bool showProtectedZones;
  final bool showFishingZones;

  const GeoJsonMapLayers({
    super.key,
    required this.builder,
    this.showFishingSpots = true,
    this.showShippingLanes = true,
    this.showProtectedZones = true,
    this.showFishingZones = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Polygons (bottom layer)
        PolygonLayer(
          polygons: builder.buildAllZones(
            showProtected: showProtectedZones,
            showFishing: showFishingZones,
          ),
        ),
        // Polylines (middle layer)
        PolylineLayer(
          polylines: builder.buildShippingLanes(isVisible: showShippingLanes),
        ),
        // Markers (top layer)
        MarkerLayer(
          markers: builder.buildFishingSpotMarkers(isVisible: showFishingSpots),
        ),
      ],
    );
  }
}
