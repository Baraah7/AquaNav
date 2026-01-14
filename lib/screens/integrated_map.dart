import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/navigation_mask.dart';
import 'package:Bahaar/services/map_layer_manager.dart';
import 'package:Bahaar/services/marina_data_service.dart';
import 'package:Bahaar/services/osrm_routing_service.dart';
import 'package:Bahaar/services/marine_pathfinding_service.dart';
import 'package:Bahaar/services/hybrid_route_coordinator.dart';
import 'package:Bahaar/services/navigation_session_manager.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/widgets/map/enhanced_depth_layer.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';
import 'package:Bahaar/widgets/map/layer_control_panel.dart';
import 'package:Bahaar/widgets/navigation/marina_marker_layer.dart';
import 'package:Bahaar/widgets/navigation/route_polyline_layer.dart';
import 'package:Bahaar/widgets/navigation/active_navigation_overlay.dart';
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
  final MarinaDataService _marinaService = MarinaDataService();
  late final MapLayerManager _layerManager;

  // Routing services
  late final OsrmRoutingService _osrmService;
  late final MarinePathfindingService _marineService;
  late final HybridRouteCoordinator _routeCoordinator;
  NavigationSessionManager? _navigationManager;

  // State
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  bool _maskInitialized = false;
  bool _showDepthLegend = false;

  // GeoJSON data
  GeoJsonLayerBuilder? _geoJsonBuilder;

  // Marina data
  Marina? _selectedMarina;
  bool _showMarinas = true;

  // Navigation state
  NavigationRoute? _currentRoute;
  LatLng? _destinationPoint;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _layerManager = MapLayerManager();
    _initLocation();
    _initNavigationMask();
    _loadGeoJson();
    _initMarinas();
    _initRoutingServices();
  }

  Future<void> _initRoutingServices() async {
    try {
      // Wait for dependencies to initialize
      while (!_maskInitialized || !_marinaService.isInitialized || _geoJsonBuilder == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _osrmService = OsrmRoutingService();
      _marineService = MarinePathfindingService(_navigationMask);
      _routeCoordinator = HybridRouteCoordinator(
        osrmService: _osrmService,
        marineService: _marineService,
        marinaService: _marinaService,
        navigationMask: _navigationMask,
        geoJsonBuilder: _geoJsonBuilder!,
      );

      // Initialize navigation session manager
      _navigationManager = NavigationSessionManager(
        location: _location,
        routeCoordinator: _routeCoordinator,
      );

      // Listen to navigation state changes
      _navigationManager!.addListener(_onNavigationUpdate);

      log('Routing services initialized successfully');
    } catch (e) {
      log('Error initializing routing services: $e');
    }
  }

  void _onNavigationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _navigationManager?.removeListener(_onNavigationUpdate);
    _navigationManager?.dispose();
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

  Future<void> _initMarinas() async {
    try {
      // Wait for navigation mask to initialize first
      while (!_maskInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _marinaService.initialize(_navigationMask);
      if (mounted) {
        setState(() {});
        log('Marina service initialized: ${_marinaService.marinaCount} marinas loaded');
      }
    } catch (e) {
      log('Error initializing marina service: $e');
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

    // If there's already a route, tapping doesn't do anything
    // User must clear the route first using the navigation button
    if (_currentRoute != null) return;

    final isNavigable = _navigationMask.isPointNavigable(point);
    log('Tapped location (${point.latitude}, ${point.longitude}): ${isNavigable ? "Water" : "Land"}');

    // Calculate route to tapped location
    if (_locationData != null) {
      _calculateRoute(point);
    } else {
      _showMessage('Location not available', Colors.orange);
    }
  }

  void _handleMarinaTapped(Marina marina) {
    setState(() {
      _selectedMarina = marina;
    });
    log('Marina tapped: ${marina.name}');

    // Center map on marina
    _mapController.move(marina.location, 15.0);
  }

  // ============================================================
  // Route Calculation Methods
  // ============================================================

  Future<void> _calculateRoute(LatLng destination) async {
    if (_locationData == null) {
      _showMessage('Location not available', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _destinationPoint = destination;
      _currentRoute = null;
    });

    try {
      final origin = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );

      log('Calculating route from $origin to $destination');

      final route = await _routeCoordinator.calculateRoute(
        origin: origin,
        destination: destination,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _isCalculatingRoute = false;
        });

        _showMessage('Route calculated: ${_formatDistance(route.totalDistance)}', Colors.green);

        // Fit route bounds
        _fitRouteBounds(route);
      } else {
        setState(() {
          _isCalculatingRoute = false;
        });
        _showMessage('Could not find a route', Colors.red);
      }
    } catch (e) {
      log('Error calculating route: $e');
      setState(() {
        _isCalculatingRoute = false;
      });
      _showMessage('Error calculating route: $e', Colors.red);
    }
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _destinationPoint = null;
      _selectedMarina = null;
    });
  }

  void _fitRouteBounds(NavigationRoute route) {
    final points = route.geometry;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLon),
          LatLng(maxLat, maxLon),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // ============================================================
  // Navigation Session Methods
  // ============================================================

  Future<void> _startNavigation() async {
    if (_currentRoute == null || _navigationManager == null) return;

    try {
      log('Starting navigation session');
      await _navigationManager!.startNavigation(_currentRoute!);
      _showMessage('Navigation started', Colors.green);

      // Center on current location
      if (_locationData != null) {
        _mapController.move(
          LatLng(
            _locationData!.latitude ?? MapConstants.defaultLatitude,
            _locationData!.longitude ?? MapConstants.defaultLongitude,
          ),
          16,
        );
      }
    } catch (e) {
      log('Error starting navigation: $e');
      _showMessage('Failed to start navigation: $e', Colors.red);
    }
  }

  void _endNavigation() {
    if (_navigationManager == null) return;

    log('Ending navigation session');
    _navigationManager!.cancelNavigation();
    _clearRoute();
  }

  void _recenterOnLocation() {
    if (_navigationManager?.session?.currentLocation != null) {
      _mapController.move(
        _navigationManager!.session!.currentLocation!,
        16,
      );
    } else if (_locationData != null) {
      _mapController.move(
        LatLng(
          _locationData!.latitude ?? MapConstants.defaultLatitude,
          _locationData!.longitude ?? MapConstants.defaultLongitude,
        ),
        16,
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
                showRestrictedAreas: _layerManager.showRestrictedAreas,
              );
            },
          ),

        // Navigation mask overlay
        if (_maskInitialized && _layerManager.showMaskOverlay)
          PolygonLayer(
            polygons: _buildMaskOverlay(),
          ),

        // Marina markers
        if (_marinaService.isInitialized && _showMarinas)
          MarinaMarkerLayer(
            marinas: _marinaService.getAllMarinas(),
            highlightedMarinaId: _selectedMarina?.id,
            onMarinaTapped: _handleMarinaTapped,
          ),

        // Route visualization (show active segment if navigating)
        if (_currentRoute != null)
          RoutePolylineLayer(
            route: _currentRoute!,
            activeSegmentIndex: _navigationManager?.session?.currentSegmentIndex,
            showMarkers: true,
          ),

        // Breadcrumb trail (during active navigation)
        if (_navigationManager?.session != null &&
            _navigationManager!.session!.breadcrumbs.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _navigationManager!.session!.breadcrumbs,
                strokeWidth: 3.0,
                color: Colors.purple.withValues(alpha: 0.6),
              ),
            ],
          ),

        // Destination marker
        if (_destinationPoint != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _destinationPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
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

          // Marina info card (when marina is selected)
          if (_selectedMarina != null && _currentRoute == null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: MarinaInfoCard(
                marina: _selectedMarina!,
                onClose: () => setState(() => _selectedMarina = null),
                onNavigate: () {
                  _calculateRoute(_selectedMarina!.location);
                },
              ),
            ),

          // Route stats card (when route is calculated but not navigating)
          if (_currentRoute != null && !(_navigationManager?.isNavigating ?? false))
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: RouteStatsCard(
                route: _currentRoute!,
                onCancel: _clearRoute,
                onStartNavigation: _startNavigation,
              ),
            ),

          // Active navigation overlay (when navigating)
          if (_navigationManager?.session != null)
            ActiveNavigationOverlay(
              session: _navigationManager!.session!,
              onEndNavigation: _endNavigation,
              onRecenter: _recenterOnLocation,
              isRecalculating: _navigationManager!.isRecalculating,
            ),

          // Navigation FAB button (top left, below depth legend)
          Positioned(
            top: 130,
            left: 10,
            child: FloatingActionButton.small(
              heroTag: 'navigation',
              onPressed: _maskInitialized && _locationData != null
                  ? () {
                      if (_currentRoute != null) {
                        _clearRoute();
                      } else {
                        _showMessage('Tap on the map to set destination', Colors.blue);
                      }
                    }
                  : null,
              backgroundColor: _currentRoute != null ? Colors.orange : Colors.blue,
              child: Icon(
                _currentRoute != null ? Icons.close : Icons.navigation,
                color: Colors.white,
              ),
            ),
          ),

          // Route calculation loading indicator
          if (_isCalculatingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Calculating route...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
