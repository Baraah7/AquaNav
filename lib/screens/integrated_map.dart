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
import 'package:Bahaar/widgets/navigation/weather_alert_overlay.dart';
import 'package:Bahaar/services/marine_weather_service.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';
import 'package:Bahaar/utilities/map_constants.dart';
import 'package:Bahaar/widgets/map/admin_edit_toolbar.dart';

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
  late final MarineWeatherService _weatherService;
  NavigationSessionManager? _navigationManager;

  // Weather state
  List<WeatherSafetyAssessment> _activeWeatherWarnings = [];
  bool _weatherAlertDismissed = false;

  // State
  bool _mapReady = false;
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  bool _maskInitialized = false;
  bool _showDepthLegend = false;

  // Admin edit state - track painted cells with their brush type for visualization
  final Map<({int row, int col}), AdminBrushType> _paintedCells = {};

  // GeoJSON data
  GeoJsonLayerBuilder? _geoJsonBuilder;

  // Marina data
  Marina? _selectedMarina;
  final bool _showMarinas = true;

  // Navigation state
  NavigationRoute? _currentRoute;
  LatLng? _originPoint;
  LatLng? _destinationPoint;
  bool _isCalculatingRoute = false;

  // Predefined ports for starting marine navigation
  final List<PortPoint> _availablePorts = [
    PortPoint(
      id: 'port_1',
      name: 'Mina Salman Port',
      location: LatLng(26.2100, 50.6200),
      description: 'Main commercial port',
      facilities: ['fuel', 'parking', 'restroom'],
    ),
    PortPoint(
      id: 'port_2',
      name: 'Manama Marina',
      location: LatLng(26.2285, 50.6050),
      description: 'Recreational marina',
      facilities: ['fuel', 'parking', 'restaurant'],
    ),
    PortPoint(
      id: 'port_3',
      name: 'Muharraq Harbor',
      location: LatLng(26.2572, 50.6300),
      description: 'Northern harbor access',
      facilities: ['parking', 'restroom'],
    ),
  ];

  // Selected port and destination
  PortPoint? _selectedPort;
  LatLng? _seaDestination;
  bool _showPortSelection = false;

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

      // Initialize weather service
      _weatherService = MarineWeatherService();
      await _weatherService.initialize();
      log('Weather service initialized');

      // Update weather warnings
      _updateWeatherWarnings();

      _osrmService = OsrmRoutingService();
      _marineService = MarinePathfindingService(
        _navigationMask,
        weatherService: _weatherService,
      );
      _routeCoordinator = HybridRouteCoordinator(
        osrmService: _osrmService,
        marineService: _marineService,
        marinaService: _marinaService,
        navigationMask: _navigationMask,
        geoJsonBuilder: _geoJsonBuilder!,
        weatherService: _weatherService,
      );

      // Initialize navigation session manager
      _navigationManager = NavigationSessionManager(
        location: _location,
        routeCoordinator: _routeCoordinator,
        weatherService: _weatherService,
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

    // Handle admin edit mode
    if (_layerManager.isAdminEditMode) {
      _handleAdminPaint(point);
      return;
    }

    // If there's already a route, tapping doesn't do anything
    if (_currentRoute != null) return;

    final isNavigable = _navigationMask.isPointNavigable(point);
    log('Tapped location (${point.latitude}, ${point.longitude}): ${isNavigable ? "Water" : "Land"}');

    // If port selection is open, only accept water points as destinations
    if (_showPortSelection) {
      if (!isNavigable) {
        _showMessage('Please select a water destination', Colors.red);
        return;
      }

      setState(() {
        _seaDestination = point;
      });
      _showMessage('Sea destination set. Select a port to start from.', Colors.blue);
      return;
    }
  }

  void _handleAdminPaint(LatLng point) {
    // Water = 1, Land/Eraser = 0
    final brushType = _layerManager.brushType;
    final value = brushType == AdminBrushType.water ? 1 : 0;
    final painted = _navigationMask.paintBrush(
      point.longitude,
      point.latitude,
      _layerManager.brushRadius,
      value,
    );

    if (painted.isNotEmpty) {
      setState(() {
        // Store each cell with its brush type
        for (final cell in painted) {
          _paintedCells[cell] = brushType;
        }
      });
    }
  }

  /// Convert screen position to LatLng for drag painting
  LatLng? _screenToLatLng(Offset screenPosition) {
    if (!_mapReady) return null;
    try {
      // Use flutter_map's offset to latlng conversion
      return _mapController.camera.offsetToCrs(screenPosition);
    } catch (e) {
      return null;
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
        log('Route details: ${route.segments.length} segments, ${route.geometry.length} points');
        for (int i = 0; i < route.segments.length; i++) {
          final seg = route.segments[i];
          log('  Segment $i: ${seg.type.name} - ${seg.geometry.length} points, ${seg.distance}m');
        }

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

  Future<void> _calculatePortToSeaRoute() async {
    if (_selectedPort == null || _seaDestination == null) {
      _showMessage('Please select both port and sea destination', Colors.orange);
      return;
    }

    if (_locationData == null) {
      _showMessage('Current location not available', Colors.orange);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _currentRoute = null;
    });

    try {
      final currentLocation = LatLng(
        _locationData!.latitude ?? MapConstants.defaultLatitude,
        _locationData!.longitude ?? MapConstants.defaultLongitude,
      );

      log('Calculating land-to-port-to-sea route');
      log('  Current location: $currentLocation');
      log('  Selected port: ${_selectedPort!.name} at ${_selectedPort!.location}');
      log('  Sea destination: $_seaDestination');

      // Calculate land route to port using OSRM
      final landSegment = await _osrmService.getRoute(
        origin: currentLocation,
        destination: _selectedPort!.location,
      );

      if (landSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find land route to port', Colors.red);
        return;
      }

      // Calculate marine route from port to sea destination
      final marineSegment = await _marineService.findMarineRoute(
        origin: _selectedPort!.location,
        destination: _seaDestination!,
        restrictedAreas: [], // TODO: Add restricted areas support
      );

      if (marineSegment == null) {
        setState(() => _isCalculatingRoute = false);
        _showMessage('Could not find marine route from port', Colors.red);
        return;
      }

      // Combine routes
      final combinedGeometry = [...landSegment.geometry, ...marineSegment.geometry];
      final segments = [landSegment, marineSegment];

      final totalDistance = segments.fold<double>(
        0,
        (sum, segment) => sum + segment.distance,
      );

      final totalDuration = segments.fold<int>(
        0,
        (sum, segment) => sum + segment.duration,
      );

      final combinedRoute = NavigationRoute(
        id: 'route_${DateTime.now().millisecondsSinceEpoch}',
        origin: currentLocation,
        destination: _seaDestination!,
        geometry: combinedGeometry,
        segments: segments,
        waypoints: [],
        totalDistance: totalDistance,
        estimatedDuration: totalDuration,
        validation: RouteValidation(
          isValid: true,
          totalPoints: combinedGeometry.length,
          waterPoints: marineSegment.geometry.length,
          landPoints: landSegment.geometry.length,
          landPointIndices: [],
        ),
        createdAt: DateTime.now(),
        metrics: RouteMetrics(
          landDistance: landSegment.distance,
          marineDistance: marineSegment.distance,
          landDuration: landSegment.duration,
          marineDuration: marineSegment.duration,
        ),
      );

      log('Route calculated successfully');
      log('  Land segment: ${landSegment.geometry.length} points, ${landSegment.distance}m');
      log('  Marine segment: ${marineSegment.geometry.length} points, ${marineSegment.distance}m');
      log('  Total distance: ${totalDistance}m');

      // Refresh weather warnings after route calculation
      _updateWeatherWarnings();

      setState(() {
        _currentRoute = combinedRoute;
        _isCalculatingRoute = false;
        _showPortSelection = false;
      });

      _showMessage('Route calculated: ${_formatDistance(totalDistance)}', Colors.green);
      _fitRouteBounds(combinedRoute);

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
      _selectedMarina = null;
      _selectedPort = null;
      _seaDestination = null;
      _showPortSelection = false;
    });
  }

  void _openPortSelection() {
    setState(() {
      _showPortSelection = true;
      _currentRoute = null;
      _selectedPort = null;
      _seaDestination = null;
    });
  }

  void _handlePortSelected(PortPoint port) {
    setState(() {
      _selectedPort = port;
    });
    _showMessage('Port selected: ${port.name}', Colors.blue);

    // If both port and destination are selected, calculate route
    if (_seaDestination != null) {
      _calculatePortToSeaRoute();
    }
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

  void _updateWeatherWarnings() {
    final warnings = _weatherService.getActiveWarnings();
    if (mounted) {
      setState(() {
        _activeWeatherWarnings = warnings;
        _weatherAlertDismissed = false;
      });
    }
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
  // Admin Edit Methods
  // ============================================================

  void _enterAdminEditMode() {
    setState(() {
      _layerManager.isAdminEditMode = true;
      _layerManager.showMaskOverlay = true;
      _paintedCells.clear();
    });
  }

  Future<void> _handleSaveMask() async {
    final success = await _navigationMask.saveChanges();
    if (success) {
      _showMessage('Mask saved successfully', Colors.green);
      setState(() {});
    } else {
      _showMessage('Failed to save mask', Colors.red);
    }
  }

  Future<void> _handleResetMask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Mask?'),
        content: const Text(
          'This will discard all your changes and restore the original mask.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _navigationMask.resetToOriginal();
      if (success) {
        setState(() {
          _paintedCells.clear();
        });
        _showMessage('Mask reset to original', Colors.green);
      } else {
        _showMessage('Failed to reset mask', Colors.red);
      }
    }
  }

  void _exitAdminEditMode() {
    setState(() {
      _layerManager.isAdminEditMode = false;
      _paintedCells.clear();
    });
  }

  // ============================================================
  // UI Builder Methods
  // ============================================================

  Widget _buildMap() {
    final isAdminMode = _layerManager.isAdminEditMode;

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
        // Disable map gestures in admin edit mode to allow painting
        interactionOptions: InteractionOptions(
          flags: isAdminMode
              ? InteractiveFlag.none
              : InteractiveFlag.all,
        ),
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

        // Painted cells visualization (admin edit mode)
        if (_layerManager.isAdminEditMode && _paintedCells.isNotEmpty)
          PolygonLayer(
            polygons: _buildPaintedCellsOverlay(),
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

        // Custom origin marker (when using destination picker)
        if (_originPoint != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _originPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.radio_button_checked,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
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

        // Port markers (always visible when port selection is active)
        if (_showPortSelection || _selectedPort != null)
          MarkerLayer(
            markers: _availablePorts.map((port) {
              final isSelected = _selectedPort?.id == port.id;
              return Marker(
                point: port.location,
                width: 60,
                height: 80,
                child: GestureDetector(
                  onTap: () => _handlePortSelected(port),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.anchor,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          port.name.split(' ').first, // Show first word
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        // Sea destination marker (when set)
        if (_seaDestination != null && _currentRoute == null)
          MarkerLayer(
            markers: [
              Marker(
                point: _seaDestination!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
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
    final polygons = <Polygon>[];
    final resolution = _navigationMask.resolution;
    final halfRes = resolution / 2;

    // Get boundary water cells and draw them as small squares
    final boundaryCells = _navigationMask.getBoundaryWaterCells();

    for (final center in boundaryCells) {
      polygons.add(
        Polygon(
          points: [
            LatLng(center.latitude - halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude + halfRes),
            LatLng(center.latitude - halfRes, center.longitude + halfRes),
          ],
          color: Colors.purple.withValues(alpha: 0.15),
          borderStrokeWidth: 1.0,
          borderColor: Colors.purple.withValues(alpha: 0.6),
        ),
      );
    }

    return polygons;
  }

  List<Polygon> _buildPaintedCellsOverlay() {
    final polygons = <Polygon>[];
    final resolution = _navigationMask.resolution;
    final halfRes = resolution / 2;

    for (final entry in _paintedCells.entries) {
      final cell = entry.key;
      final brushType = entry.value;

      // Determine color based on the brush type used when painting this cell
      Color fillColor;
      Color borderColor;
      switch (brushType) {
        case AdminBrushType.water:
          fillColor = Colors.blue.withValues(alpha: 0.5);
          borderColor = Colors.blue.withValues(alpha: 0.8);
          break;
        case AdminBrushType.land:
          fillColor = Colors.brown.withValues(alpha: 0.5);
          borderColor = Colors.brown.withValues(alpha: 0.8);
          break;
        case AdminBrushType.eraser:
          fillColor = Colors.grey.withValues(alpha: 0.5);
          borderColor = Colors.grey.withValues(alpha: 0.8);
          break;
      }

      final center = _navigationMask.gridToCoords(cell.row, cell.col);
      polygons.add(
        Polygon(
          points: [
            LatLng(center.latitude - halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude - halfRes),
            LatLng(center.latitude + halfRes, center.longitude + halfRes),
            LatLng(center.latitude - halfRes, center.longitude + halfRes),
          ],
          color: fillColor,
          borderStrokeWidth: 1.0,
          borderColor: borderColor,
        ),
      );
    }
    return polygons;
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
          // Main map with gesture detector for admin painting
          GestureDetector(
            behavior: _layerManager.isAdminEditMode
                ? HitTestBehavior.opaque
                : HitTestBehavior.translucent,
            onTapDown: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) {
                      _handleAdminPaint(latLng);
                    }
                  }
                : null,
            onPanStart: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) {
                      _handleAdminPaint(latLng);
                    }
                  }
                : null,
            onPanUpdate: _layerManager.isAdminEditMode
                ? (details) {
                    final latLng = _screenToLatLng(details.localPosition);
                    if (latLng != null) {
                      _handleAdminPaint(latLng);
                    }
                  }
                : null,
            child: _buildMap(),
          ),

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
                    onEnterAdminEdit: _enterAdminEditMode,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Admin edit toolbar (when in edit mode)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (_layerManager.isAdminEditMode && _maskInitialized) {
                return Positioned(
                  top: 50,
                  left: 10,
                  child: AdminEditToolbar(
                    layerManager: _layerManager,
                    navigationMask: _navigationMask,
                    onSave: _handleSaveMask,
                    onReset: _handleResetMask,
                    onClose: _exitAdminEditMode,
                    onZoomIn: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    onZoomOut: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Layer control toggle button (top left, when panel hidden and not in admin mode)
          ListenableBuilder(
            listenable: _layerManager,
            builder: (context, _) {
              if (!_layerManager.showLayerControls && !_layerManager.isAdminEditMode) {
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
              onPressed: _maskInitialized
                  ? () {
                      if (_currentRoute != null) {
                        _clearRoute();
                      } else if (_showPortSelection) {
                        setState(() => _showPortSelection = false);
                      } else {
                        _openPortSelection();
                      }
                    }
                  : null,
              backgroundColor: _currentRoute != null || _showPortSelection ? Colors.orange : Colors.blue,
              child: Icon(
                _currentRoute != null || _showPortSelection ? Icons.close : Icons.directions_boat,
                color: Colors.white,
              ),
            ),
          ),

          // Port selection instructions (when active)
          if (_showPortSelection && _currentRoute == null)
            Positioned(
              top: 180,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'Port Navigation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPort == null
                          ? '1. Select a port (anchor icon)\n2. Tap sea destination on map'
                          : _seaDestination == null
                              ? '2. Tap sea destination on map'
                              : 'Calculating route...',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (_selectedPort != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Port: ${_selectedPort!.name}',
                              style: const TextStyle(fontSize: 11, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),


          // Weather alert overlay
          if (_activeWeatherWarnings.isNotEmpty && !_weatherAlertDismissed)
            WeatherAlertOverlay(
              warnings: _activeWeatherWarnings,
              onDismiss: () {
                setState(() {
                  _weatherAlertDismissed = true;
                });
              },
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

/// Port point for marine navigation
class PortPoint {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  final List<String> facilities;

  const PortPoint({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    this.facilities = const [],
  });
}
