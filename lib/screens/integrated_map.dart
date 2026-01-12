import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/navigation_mask.dart';

/// Integrated map combining three layers:
/// 1. Base map (OpenStreetMap tiles)
/// 2. GeoJSON overlay (fishing zones, shipping lanes, etc.)
/// 3. Navigation mask (land/water validation visualization)
class IntegratedMap extends StatefulWidget {
  const IntegratedMap({super.key});

  @override
  State<IntegratedMap> createState() => _IntegratedMapState();
}

class _IntegratedMapState extends State<IntegratedMap> {
  // Map controller
  final MapController _mapController = MapController();

  // Location services
  final Location _location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  bool _mapReady = false;

  // Navigation mask
  final NavigationMask _navigationMask = NavigationMask();
  bool _maskInitialized = false;

  // GeoJSON data
  Map<String, dynamic>? _geoJsonData;

  // Layer visibility toggles
  final bool _showBaseMap = true;
  bool _showGeoJsonLayers = true;
  bool _showMaskOverlay = false;
  bool _showFishingSpots = true;
  bool _showShippingLanes = true;
  bool _showProtectedZones = true;
  bool _showFishingZones = true;
  bool _showLayerControls = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initNavigationMask();
    _loadGeoJson();
  }

  Future<void> _initNavigationMask() async {
    try {
      await _navigationMask.initialize();
      if (mounted) {
        setState(() {
          _maskInitialized = true;
        });
        log('Navigation mask initialized successfully');
      }
    } catch (e) {
      log('Error initializing navigation mask: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        log('Location service not enabled');
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          log('User denied location service');
          if (mounted) setState(() {});
          return;
        }
      }

      _permissionStatus = await _location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        log('Location permission denied');
        _permissionStatus = await _location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          log('User denied location permission');
          if (mounted) setState(() {});
          return;
        }
      }

      _locationData = await _location.getLocation();
      log('Location fetched: ${_locationData.toString()}');
      if (mounted) {
        setState(() {});
        _moveToLocationIfReady();
      }
    } catch (e) {
      log('Error getting location: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/gulf_test_features.geojson'
      );
      setState(() {
        _geoJsonData = json.decode(jsonString);
      });
      log('GeoJSON loaded successfully');
    } catch (e) {
      log('Error loading GeoJSON: $e');
    }
  }

  void _moveToLocationIfReady() {
    if (_mapReady && _locationData != null) {
      final targetLocation = LatLng(
        _locationData!.latitude ?? 26.1,
        _locationData!.longitude ?? 50.6,
      );

      // Validate location against navigation mask if initialized
      if (_maskInitialized) {
        final isNavigable = _navigationMask.isPointNavigable(targetLocation);
        if (!isNavigable) {
          log('Warning: Current location appears to be on land');
          final nearestWater = _navigationMask.findNearestWaterPoint(targetLocation);
          if (nearestWater != null) {
            log('Nearest water location: ${nearestWater.latitude}, ${nearestWater.longitude}');
          }
        } else {
          log('Location validated: on navigable water');
        }
      }

      _mapController.move(targetLocation, 12);
    }
  }

  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });
    _moveToLocationIfReady();
  }

  // Extract features by type from GeoJSON
  List<Map<String, dynamic>> _getFeaturesByType(String type) {
    if (_geoJsonData == null) return [];

    final features = _geoJsonData!['features'] as List;
    return features
        .where((f) => f['properties']['type'] == type)
        .map((f) => f as Map<String, dynamic>)
        .toList();
  }

  // Build fishing spot markers from GeoJSON
  List<Marker> _buildFishingSpotMarkers() {
    if (!_showFishingSpots || !_showGeoJsonLayers) return [];

    final spots = _getFeaturesByType('fishing_spot');
    return spots.map((feature) {
      final coords = feature['geometry']['coordinates'] as List;

      return Marker(
        point: LatLng(coords[1], coords[0]), // GeoJSON is [lng, lat]
        width: 30,
        height: 30,
        child: Icon(
          Icons.location_on,
          color: Colors.blue.withValues(alpha: 0.8),
          size: 25,
        ),
      );
    }).toList();
  }

  // Build shipping lanes from GeoJSON
  List<Polyline> _buildShippingLanes() {
    if (!_showShippingLanes || !_showGeoJsonLayers) return [];

    final lanes = _getFeaturesByType('shipping_lane');
    final routes = _getFeaturesByType('patrol_route');
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

  // Build zone polygons from GeoJSON
  List<Polygon> _buildZonePolygons() {
    if (!_showGeoJsonLayers) return [];

    final polygons = <Polygon>[];

    // Protected zones
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
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.brown.withValues(alpha: 0.15),
          borderStrokeWidth: 2.0,
          borderColor: type == 'protected_zone'
              ? Colors.red.withValues(alpha: 0.6)
              : Colors.brown.withValues(alpha: 0.6),
        ));
      }
    }

    // Fishing zones
    if (_showFishingZones) {
      final zones = _getFeaturesByType('fishing_zone');

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
    }

    return polygons;
  }

  // Build mask overlay visualization
  List<Polygon> _buildMaskOverlay() {
    if (!_showMaskOverlay || !_maskInitialized) return [];

    // This would render the mask as a grid overlay
    // For now, we'll just show the bounding box
    final metadata = _navigationMask.getMetadata();
    final bbox = metadata['bbox'];

    return [
      Polygon(
        points: [
          LatLng(bbox['min_lat'], bbox['min_lon']),
          LatLng(bbox['max_lat'], bbox['min_lon']),
          LatLng(bbox['max_lat'], bbox['max_lon']),
          LatLng(bbox['min_lat'], bbox['max_lon']),
        ],
        color: Colors.transparent,
        borderStrokeWidth: 2.0,
        borderColor: Colors.purple.withValues(alpha: 0.8),
      ),
    ];
  }

  // Build layer control panel
  Widget _buildLayerControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        maxWidth: 280,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Map Layers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _showLayerControls = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),

          // GeoJSON Layers Section
          const Text(
            'GeoJSON Overlays',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('All GeoJSON Layers', style: TextStyle(fontSize: 13)),
            value: _showGeoJsonLayers,
            onChanged: (val) => setState(() => _showGeoJsonLayers = val),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          if (_showGeoJsonLayers) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Fishing Spots', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_getFeaturesByType('fishing_spot').length} locations',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showFishingSpots,
                    onChanged: (val) => setState(() => _showFishingSpots = val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Shipping Lanes', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_getFeaturesByType('shipping_lane').length + _getFeaturesByType('patrol_route').length} routes',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showShippingLanes,
                    onChanged: (val) => setState(() => _showShippingLanes = val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Protected Zones', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_getFeaturesByType('protected_zone').length + _getFeaturesByType('reef').length} areas',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showProtectedZones,
                    onChanged: (val) => setState(() => _showProtectedZones = val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Fishing Zones', style: TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${_getFeaturesByType('fishing_zone').length} areas',
                      style: const TextStyle(fontSize: 10),
                    ),
                    value: _showFishingZones,
                    onChanged: (val) => setState(() => _showFishingZones = val),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],

          const Divider(),

          // Navigation Mask Section
          const Text(
            'Navigation Mask',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            title: const Text('Show Mask Boundary', style: TextStyle(fontSize: 13)),
            subtitle: Text(
              _maskInitialized ? 'Coverage area outline' : 'Loading...',
              style: const TextStyle(fontSize: 10),
            ),
            value: _showMaskOverlay,
            onChanged: _maskInitialized ? (val) => setState(() => _showMaskOverlay = val) : null,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main map with all layers
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(26.1, 50.6), // Bahrain center
              initialZoom: 10,
              onMapReady: _onMapReady,
              onTap: (tapPosition, point) {
                // Validate tapped location if mask is initialized
                if (_maskInitialized) {
                  final isNavigable = _navigationMask.isPointNavigable(point);
                  log('Tapped location (${point.latitude}, ${point.longitude}): ${isNavigable ? "Water" : "Land"}');

                  if (!isNavigable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('This location is on land. Tap on water for navigation.'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'Find Water',
                          textColor: Colors.white,
                          onPressed: () {
                            final nearestWater = _navigationMask.findNearestWaterPoint(point);
                            if (nearestWater != null) {
                              _mapController.move(nearestWater, _mapController.camera.zoom);
                              log('Moved to nearest water: ${nearestWater.latitude}, ${nearestWater.longitude}');
                            }
                          },
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            children: [
              // Layer 1: Base map tiles
              if (_showBaseMap)
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bahaar.bahaarapp',
                  maxZoom: 19,
                  subdomains: const ['a', 'b', 'c'],
                ),

              // Layer 2: GeoJSON overlays (bottom to top: polygons → polylines → markers)
              // 2a. Zone polygons
              PolygonLayer(
                polygons: _buildZonePolygons(),
              ),

              // 2b. Shipping lanes
              PolylineLayer(
                polylines: _buildShippingLanes(),
              ),

              // 2c. Fishing spots
              MarkerLayer(
                markers: _buildFishingSpotMarkers(),
              ),

              // Layer 3: Navigation mask overlay (optional visualization)
              PolygonLayer(
                polygons: _buildMaskOverlay(),
              ),

              // User location marker (always on top)
              if (_locationData != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _locationData!.latitude ?? 26.1,
                        _locationData!.longitude ?? 50.6,
                      ),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.my_location,
                        color: _maskInitialized && _navigationMask.isNavigable(
                          _locationData!.longitude ?? 50.6,
                          _locationData!.latitude ?? 26.1,
                        ) ? Colors.blue : Colors.orange,
                        size: 30,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Navigation mask status indicator (top right)
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _maskInitialized ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _maskInitialized ? Icons.check_circle : Icons.hourglass_empty,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _maskInitialized ? 'Navigation Ready' : 'Loading...',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Layer controls panel (top left, when visible)
          if (_showLayerControls)
            Positioned(
              top: 10,
              left: 10,
              child: _buildLayerControls(),
            ),

          // Layer control toggle button (top left, when panel hidden)
          if (!_showLayerControls)
            Positioned(
              top: 10,
              left: 10,
              child: FloatingActionButton.small(
                heroTag: 'layer_controls',
                onPressed: () => setState(() => _showLayerControls = true),
                backgroundColor: Colors.white,
                child: const Icon(Icons.layers, color: Colors.blue),
              ),
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
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.blue),
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
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: _mapReady && _locationData != null ? () {
                    _mapController.move(
                      LatLng(
                        _locationData!.latitude ?? 26.1,
                        _locationData!.longitude ?? 50.6,
                      ),
                      14,
                    );
                  } : null,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
