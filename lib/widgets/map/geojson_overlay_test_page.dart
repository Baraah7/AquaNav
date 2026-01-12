import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Test page for validating GeoJSON overlay support in Bahaar
/// 
/// Features tested:
/// - Point, LineString, and Polygon rendering
/// - Geographic alignment verification
/// - Tap/click interactions
/// - Layer toggle controls
/// - Performance at multiple zoom levels
class GeoJsonOverlayTestPage extends StatefulWidget {
  const GeoJsonOverlayTestPage({super.key});

  @override
  State<GeoJsonOverlayTestPage> createState() => _GeoJsonOverlayTestPageState();
}

class _GeoJsonOverlayTestPageState extends State<GeoJsonOverlayTestPage> {
  final MapController _mapController = MapController();
  
  // Layer visibility toggles
  bool _showFishingSpots = true;
  bool _showShippingLanes = true;
  bool _showProtectedZones = true;
  bool _showFishingZones = true;
  
  // GeoJSON data
  Map<String, dynamic>? _geoJsonData;
  
  // Selected feature for interaction testing
  Map<String, dynamic>? _selectedFeature;

  // Performance metrics
  int _renderCount = 0;
  DateTime? _lastRenderTime;

  // Map ready flag
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });
  }
  
  /// Load GeoJSON from assets
  Future<void> _loadGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/gulf_test_features.geojson'
      );
      setState(() {
        _geoJsonData = json.decode(jsonString);
        _renderCount++;
        _lastRenderTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading GeoJSON: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load GeoJSON: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Extract features by type
  List<Map<String, dynamic>> _getFeaturesByType(String type) {
    if (_geoJsonData == null) return [];
    
    final features = _geoJsonData!['features'] as List;
    return features
        .where((f) => f['properties']['type'] == type)
        .map((f) => f as Map<String, dynamic>)
        .toList();
  }
  
  /// Build marker layers for Points (fishing spots)
  List<Marker> _buildFishingSpotMarkers() {
    if (!_showFishingSpots) return [];
    
    final spots = _getFeaturesByType('fishing_spot');
    return spots.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final props = feature['properties'] as Map<String, dynamic>;
      
      return Marker(
        point: LatLng(coords[1], coords[0]), // GeoJSON is [lng, lat]
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _onFeatureTapped(feature),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// Build polyline layers for LineStrings (shipping lanes, routes)
  List<Polyline> _buildShippingLanes() {
    if (!_showShippingLanes) return [];
    
    final lanes = _getFeaturesByType('shipping_lane');
    final routes = _getFeaturesByType('patrol_route');
    final allLines = [...lanes, ...routes];
    
    return allLines.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;
      final props = feature['properties'] as Map<String, dynamic>;
      final type = props['type'] as String;
      
      return Polyline(
        points: coords.map((coord) {
          return LatLng(coord[1], coord[0]); // GeoJSON is [lng, lat]
        }).toList(),
        strokeWidth: type == 'shipping_lane' ? 4.0 : 2.0,
        color: type == 'shipping_lane' 
            ? Colors.red.withOpacity(0.7)
            : Colors.orange.withOpacity(0.7),
        borderStrokeWidth: 1.0,
        borderColor: Colors.white.withOpacity(0.5),
      );
    }).toList();
  }
  
  /// Build polygon layers for Polygons (zones, areas)
  List<Polygon> _buildZonePolygons() {
    final polygons = <Polygon>[];
    
    // Protected zones (red)
    if (_showProtectedZones) {
      final protected = _getFeaturesByType('protected_zone');
      final reefs = _getFeaturesByType('reef');
      
      for (final feature in [...protected, ...reefs]) {
        final coords = feature['geometry']['coordinates'][0] as List;
        final type = feature['properties']['type'] as String;
        
        polygons.add(Polygon(
          points: coords.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList(),
          color: type == 'protected_zone'
              ? Colors.red.withOpacity(0.2)
              : Colors.brown.withOpacity(0.2),
          borderStrokeWidth: 2.0,
          borderColor: type == 'protected_zone'
              ? Colors.red.withOpacity(0.7)
              : Colors.brown.withOpacity(0.7),
        ));
      }
    }
    
    // Fishing zones (green)
    if (_showFishingZones) {
      final zones = _getFeaturesByType('fishing_zone');
      
      for (final feature in zones) {
        final coords = feature['geometry']['coordinates'][0] as List;
        
        polygons.add(Polygon(
          points: coords.map((coord) {
            return LatLng(coord[1], coord[0]);
          }).toList(),
          color: Colors.green.withOpacity(0.2),
          borderStrokeWidth: 2.0,
          borderColor: Colors.green.withOpacity(0.7),
        ));
      }
    }
    
    return polygons;
  }
  
  /// Handle feature tap for interaction testing
  void _onFeatureTapped(Map<String, dynamic> feature) {
    setState(() {
      _selectedFeature = feature;
    });
    
    // Show bottom sheet with feature details
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFeatureDetails(feature),
    );
  }
  
  /// Build feature details panel
  Widget _buildFeatureDetails(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>;
    final geomType = feature['geometry']['type'] as String;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getGeometryIcon(geomType), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  props['name'] ?? 'Unnamed Feature',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Geometry: $geomType',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (props['description'] != null) ...[
            Text(
              props['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: props.entries
                .where((e) => e.key != 'name' && e.key != 'description' && e.key != 'type')
                .map((e) => Chip(
                  label: Text('${e.key}: ${e.value}'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ))
                .toList(),
          ),
        ],
      ),
    );
  }
  
  /// Get icon for geometry type
  IconData _getGeometryIcon(String type) {
    switch (type) {
      case 'Point':
        return Icons.location_on;
      case 'LineString':
        return Icons.route;
      case 'Polygon':
        return Icons.crop_square;
      default:
        return Icons.map;
    }
  }
  
  /// Build layer control panel
  Widget _buildLayerControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'Layer Controls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Fishing Spots'),
            subtitle: Text('${_getFeaturesByType('fishing_spot').length} points'),
            value: _showFishingSpots,
            onChanged: (val) {
              setState(() {
                _showFishingSpots = val;
                _renderCount++;
              });
            },
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Shipping Lanes'),
            subtitle: Text('${_getFeaturesByType('shipping_lane').length + _getFeaturesByType('patrol_route').length} routes'),
            value: _showShippingLanes,
            onChanged: (val) {
              setState(() {
                _showShippingLanes = val;
                _renderCount++;
              });
            },
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Protected Zones'),
            subtitle: Text('${_getFeaturesByType('protected_zone').length + _getFeaturesByType('reef').length} areas'),
            value: _showProtectedZones,
            onChanged: (val) {
              setState(() {
                _showProtectedZones = val;
                _renderCount++;
              });
            },
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Fishing Zones'),
            subtitle: Text('${_getFeaturesByType('fishing_zone').length} areas'),
            value: _showFishingZones,
            onChanged: (val) {
              setState(() {
                _showFishingZones = val;
                _renderCount++;
              });
            },
            dense: true,
          ),
        ],
        ),
      ),
    );
  }
  
  /// Build performance metrics panel
  Widget _buildPerformanceMetrics() {
    final zoom = _mapReady ? _mapController.camera.zoom : 10.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zoom Level: ${zoom.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Render Count: $_renderCount',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (_lastRenderTime != null)
            Text(
              'Last Render: ${_lastRenderTime!.toIso8601String()}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoJSON Overlay Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGeoJson,
            tooltip: 'Reload GeoJSON',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showTestInfo(),
            tooltip: 'Test Information',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map with GeoJSON overlays
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Center on Bahrain (Gulf region)
              initialCenter: const LatLng(26.0667, 50.5577),
              initialZoom: 10.0,
              minZoom: 8.0,
              maxZoom: 18.0,
              onMapReady: _onMapReady,
              onMapEvent: (event) {
                // Track zoom changes for performance testing
                if (event is MapEventMove || event is MapEventRotate) {
                  setState(() {
                    _renderCount++;
                  });
                }
              },
            ),
            children: [
              // Base tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahaar.app',
              ),
              
              // Polygon layers (zones - rendered first, below other features)
              PolygonLayer(
                polygons: _buildZonePolygons(),
              ),
              
              // Polyline layers (shipping lanes, routes)
              PolylineLayer(
                polylines: _buildShippingLanes(),
              ),
              
              // Marker layers (fishing spots - rendered last, on top)
              MarkerLayer(
                markers: _buildFishingSpotMarkers(),
              ),
            ],
          ),
          
          // Layer controls (top left)
          Positioned(
            top: 0,
            left: 0,
            child: _buildLayerControls(),
          ),
          
          // Performance metrics (bottom left)
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildPerformanceMetrics(),
          ),
          
          // Zoom controls (bottom right)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _mapReady ? () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom + 1,
                    );
                  } : null,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _mapReady ? () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom - 1,
                    );
                  } : null,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'reset',
                  onPressed: _mapReady ? () {
                    _mapController.move(
                      const LatLng(26.0667, 50.5577),
                      10.0,
                    );
                  } : null,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show test information dialog
  void _showTestInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GeoJSON Overlay Test'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Test Objectives:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('✓ Load GeoJSON with Point, LineString, Polygon'),
              const Text('✓ Verify geographic alignment'),
              const Text('✓ Test tap/click interactions'),
              const Text('✓ Layer enable/disable toggle'),
              const Text('✓ Performance at multiple zoom levels'),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${_getFeaturesByType('fishing_spot').length} Fishing Spots (Points)'),
              Text('• ${_getFeaturesByType('shipping_lane').length} Shipping Lanes (Lines)'),
              Text('• ${_getFeaturesByType('patrol_route').length} Patrol Routes (Lines)'),
              Text('• ${_getFeaturesByType('protected_zone').length} Protected Zones (Polygons)'),
              Text('• ${_getFeaturesByType('fishing_zone').length} Fishing Zones (Polygons)'),
              Text('• ${_getFeaturesByType('reef').length} Reef Areas (Polygons)'),
              const SizedBox(height: 16),
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Use zoom controls to test performance'),
              const Text('2. Tap markers for feature details'),
              const Text('3. Toggle layers to test visibility'),
              const Text('4. Verify features align with map'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
