import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/navigation_mask.dart';
import 'package:Bahaar/services/map_layer_manager.dart';
import 'package:Bahaar/widgets/map/enhanced_depth_layer.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';
import 'package:Bahaar/widgets/map/layer_control_panel.dart';
import 'package:Bahaar/utilities/map_constants.dart';

/// Integrated map with clean architecture and enhanced depth visualization
///
/// Features:
/// - Multi-layer depth visualization (bathymetric colors, nautical charts, combined)
/// - GeoJSON overlays (fishing zones, shipping lanes, protected areas)
/// - Navigation mask validation
/// - Organized layer management
/// - Clean separation of concerns
class IntegratedMap extends StatefulWidget {
  const IntegratedMap({super.key});

  @override
  State<IntegratedMap> createState() => _IntegratedMapState();
}

class _IntegratedMapState extends State<IntegratedMap> {
  // Controllers and services
  final MapController _mapController = MapController();
  final Location _location = Location();
  final NavigationMask _navigationMask = NavigationMask();
  late final MapLayerManager _layerManager;

  // State
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  bool _maskInitialized = false;
  bool _showDepthLegend = false;

  // GeoJSON data
  GeoJsonLayerBuilder? _geoJsonBuilder;

  @override
  void initState() {
    super.initState();
    _layerManager = MapLayerManager();
    _initLocation();
    _initNavigationMask();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _layerManager.dispose();
    super.dispose();
  }

  // ============================================================
  // Initialization Methods
  // ============================================================

  Future<void> _initNavigationMask() async {
    try {
      await _navigationMask.initialize();
      if (mounted) {
        setState(() => _maskInitialized = true);
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
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          log('User denied location service');
          if (mounted) setState(() {});
          return;
        }
      }

      _permissionStatus = await _location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
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
      final data = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _geoJsonBuilder = GeoJsonLayerBuilder(data);
      });
      log('GeoJSON loaded successfully');
    } catch (e) {
      log('Error loading GeoJSON: $e');
    }
  }

  // ============================================================
  // Map Interaction Methods
  // ============================================================

  void _moveToLocationIfReady() {
    if (_mapReady && _locationData != null) {
      final targetLocation = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );

      if (_maskInitialized) {
        final isNavigable = _navigationMask.isPointNavigable(targetLocation);
        if (!isNavigable) {
          log('Warning: Current location appears to be on land');
        } else {
          log('Location validated: on navigable water');
        }
      }

      _mapController.move(targetLocation, 12);
    }
  }

  void _onMapReady() {
    setState(() => _mapReady = true);
    _moveToLocationIfReady();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (!_maskInitialized) return;

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

  // ============================================================
  // UI Builder Methods
  // ============================================================

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(
          MapConstants.defaultLatitude,
          MapConstants.defaultLongitude,
        ),
        initialZoom: MapConstants.defaultZoom,
        onMapReady: _onMapReady,
        onTap: _handleMapTap,
      ),
      children: [
        // Base map layer
        if (_layerManager.showBaseMap)
          TileLayer(
            urlTemplate: MapConstants.osmBaseUrl,
            userAgentPackageName: MapConstants.userAgent,
            maxZoom: MapConstants.osmMaxZoom.toDouble(),
            subdomains: MapConstants.osmSubdomains,
          ),

        // Enhanced depth layer with multiple visualization types
        ListenableBuilder(
          listenable: _layerManager,
          builder: (context, _) {
            return EnhancedDepthLayer(
              isVisible: _layerManager.showDepthLayer,
              opacity: _layerManager.depthLayerOpacity,
              visualizationType: _layerManager.depthVisualizationType,
              navigationMask: _maskInitialized ? _navigationMask : null,
            );
          },
        ),

        // GeoJSON layers
        if (_geoJsonBuilder != null)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showGeoJsonLayers) {
                return const SizedBox.shrink();
              }
              return GeoJsonMapLayers(
                builder: _geoJsonBuilder!,
                showFishingSpots: _layerManager.showFishingSpots,
                showShippingLanes: _layerManager.showShippingLanes,
                showProtectedZones: _layerManager.showProtectedZones,
                showFishingZones: _layerManager.showFishingZones,
              );
            },
          ),

        // Navigation mask overlay
        if (_maskInitialized && _layerManager.showMaskOverlay)
          PolygonLayer(
            polygons: _buildMaskOverlay(),
          ),

        // User location marker
        if (_locationData != null)
          MarkerLayer(
            markers: [_buildUserLocationMarker()],
          ),
      ],
    );
  }

  List<Polygon> _buildMaskOverlay() {
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

  Marker _buildUserLocationMarker() {
    final lat = _locationData!.latitude ?? MapConstants.defaultLatitude;
    final lon = _locationData!.longitude ?? MapConstants.defaultLongitude;
    final isOnWater = _maskInitialized && _navigationMask.isNavigable(lon, lat);

    return Marker(
      point: LatLng(lat, lon),
      width: 40,
      height: 40,
      child: Icon(
        Icons.my_location,
        color: isOnWater ? Colors.blue : Colors.orange,
        size: 30,
        shadows: const [
          Shadow(
            color: Colors.black54,
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationStatusIndicator() {
    return Container(
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
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        FloatingActionButton.small(
          heroTag: 'zoom_in',
          onPressed: _mapReady ? () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
          } : null,
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'zoom_out',
          onPressed: _mapReady ? () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
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
                _locationData!.latitude ?? MapConstants.defaultLatitude,
                _locationData!.longitude ?? MapConstants.defaultLongitude,
              ),
              14,
            );
          } : null,
          backgroundColor: Colors.white,
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
      ],
    );
  }

  // ============================================================
  // Main Build Method
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main map
          _buildMap(),

          // Navigation status indicator (top right)
          Positioned(
            top: 50,
            right: 10,
            child: _buildNavigationStatusIndicator(),
          ),

          // Layer controls panel (top left, when visible)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.showLayerControls) {
                return Positioned(
                  top: 10,
                  left: 10,
                  child: LayerControlPanel(
                    layerManager: _layerManager,
                    geoJsonBuilder: _geoJsonBuilder,
                    maskInitialized: _maskInitialized,
                    onClose: () => _layerManager.showLayerControls = false,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Layer control toggle button (top left, when panel hidden)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showLayerControls) {
                return Positioned(
                  top: 30,
                  left: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'layer_controls',
                    onPressed: () => _layerManager.showLayerControls = true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.layers, color: Colors.blue),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Depth legend toggle button (top left, below layer control)
          Positioned(
            top: 80,
            left: 10,
            child: FloatingActionButton.small(
              heroTag: 'depth_legend',
              onPressed: () => setState(() => _showDepthLegend = !_showDepthLegend),
              backgroundColor: Colors.white,
              child: Icon(
                _showDepthLegend ? Icons.info : Icons.info_outline,
                color: Colors.blue,
              ),
            ),
          ),

          // Depth legend (when visible)
          if (_showDepthLegend && _layerManager.showDepthLayer)
            Positioned(
              top: 110,
              left: 10,
              child: DepthLegend(),
            ),

          // Zoom controls (bottom right)
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildZoomControls(),
          ),
        ],
      ),
    );
  }
}
