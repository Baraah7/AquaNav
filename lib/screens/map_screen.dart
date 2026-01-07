import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/map_provider.dart';
import '../widgets/map/map_layer_control.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/fishing_activity_marker.dart';
import '../widgets/map/restricted_area_overlay.dart';
import '../../core/constants/map_constants.dart';
import 'package:latlong2/latlong.dart' as latlong;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolygonAnnotationManager? polygonAnnotationManager;
  CircleAnnotationManager? circleAnnotationManager;
  
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final location = latlong.LatLng(position.latitude, position.longitude);
      ref.read(mapControllerProvider.notifier).setCurrentLocation(location);
      
      // Move camera to current location
      mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: MapConstants.defaultZoom,
        ),
      );

      // Load all map layers
      ref.read(mapControllerProvider.notifier).loadAllLayers();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    _setupMapLayers();
  }

  Future<void> _setupMapLayers() async {
    // Initialize annotation managers
    pointAnnotationManager = await mapboxMap?.annotations.createPointAnnotationManager();
    polygonAnnotationManager = await mapboxMap?.annotations.createPolygonAnnotationManager();
    circleAnnotationManager = await mapboxMap?.annotations.createCircleAnnotationManager();

    // Add bathymetry layer (Mapbox built-in)
    await _addBathymetryLayer();
    
    // Listen to state changes to update markers
    ref.listen(mapControllerProvider, (previous, next) {
      _updateMapLayers(next);
    });
  }

  Future<void> _addBathymetryLayer() async {
    // Mapbox has built-in bathymetry data
    // Add hillshade layer for bathymetry visualization
    await mapboxMap?.style.addLayer(
      HillshadeLayer(
        id: MapConstants.bathymetryLayerId,
        sourceId: 'mapbox-terrain',
        hillshadeExaggeration: 0.5,
        hillshadeIlluminationDirection: 315,
      ),
    );
  }

  void _updateMapLayers(MapState state) {
    if (state.visibleLayers.contains(MapConstants.fishingActivityLayerId)) {
      _updateFishingActivityMarkers(state.fishingActivities);
    } else {
      _clearFishingActivityMarkers();
    }

    if (state.visibleLayers.contains(MapConstants.fishProbabilityLayerId)) {
      _updateFishProbabilityHeatmap(state.fishProbabilities);
    } else {
      _clearFishProbabilityHeatmap();
    }

    if (state.visibleLayers.contains(MapConstants.restrictedAreasLayerId)) {
      _updateRestrictedAreas(state.restrictedAreas);
    } else {
      _clearRestrictedAreas();
    }

    if (state.visibleLayers.contains(MapConstants.weatherLayerId)) {
      _updateWeatherOverlay(state.weatherData);
    } else {
      _clearWeatherOverlay();
    }
  }

  void _updateFishingActivityMarkers(fishingActivities) {
    pointAnnotationManager?.deleteAll();
    
    for (var activity in fishingActivities) {
      pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              activity.position.longitude,
              activity.position.latitude,
            ),
          ),
          iconImage: 'boat-icon',
          iconSize: 1.5,
          iconColor: Colors.blue.value,
        ),
      );
    }
  }

  void _clearFishingActivityMarkers() {
    pointAnnotationManager?.deleteAll();
  }

  void _updateFishProbabilityHeatmap(fishProbabilities) {
    circleAnnotationManager?.deleteAll();
    
    for (var probability in fishProbabilities) {
      // Create heatmap circles
      final color = _getHeatmapColor(probability.probability);
      
      circleAnnotationManager?.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              probability.position.longitude,
              probability.position.latitude,
            ),
          ),
          circleRadius: 20.0,
          circleColor: color.value,
          circleOpacity: 0.6,
          circleBlur: 1.0,
        ),
      );
    }
  }

  Color _getHeatmapColor(double probability) {
    if (probability < 0.3) {
      return Colors.green;
    } else if (probability < 0.7) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  void _clearFishProbabilityHeatmap() {
    circleAnnotationManager?.deleteAll();
  }

  void _updateRestrictedAreas(restrictedAreas) {
    polygonAnnotationManager?.deleteAll();
    
    for (var area in restrictedAreas) {
      if (!area.isActive()) continue;
      
      final coordinates = area.polygon.map((point) {
        return Position(point.longitude, point.latitude);
      }).toList();

      final color = _getRestrictedAreaColor(area.type);
      
      polygonAnnotationManager?.create(
        PolygonAnnotationOptions(
          geometry: Polygon(
            coordinates: [coordinates],
          ),
          fillColor: color.value,
          fillOpacity: 0.3,
          fillOutlineColor: color.value,
        ),
      );
    }
  }

  Color _getRestrictedAreaColor(String type) {
    switch (type) {
      case 'protected':
        return Colors.green;
      case 'military':
        return Colors.red;
      case 'fishing_restricted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _clearRestrictedAreas() {
    polygonAnnotationManager?.deleteAll();
  }

  void _updateWeatherOverlay(weatherData) {
    // Weather overlay can be implemented using custom tiles or overlays
    // This is a placeholder for weather visualization
  }

  void _clearWeatherOverlay() {
    // Clear weather overlay
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(0, 0)),
              zoom: MapConstants.defaultZoom,
            ),
            styleUri: MapConstants.mapboxStyleUrl,
            textureView: true,
            onMapCreated: _onMapCreated,
          ),

          // Layer Controls
          Positioned(
            top: 60,
            right: 16,
            child: MapLayerControl(
              visibleLayers: mapState.visibleLayers,
              onToggleLayer: (layerId) {
                ref.read(mapControllerProvider.notifier).toggleLayer(layerId);
              },
            ),
          ),

          // Map Legend
          Positioned(
            bottom: 100,
            left: 16,
            child: MapLegend(
              visibleLayers: mapState.visibleLayers,
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Refresh Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'refresh',
              onPressed: () {
                ref.read(mapControllerProvider.notifier).loadAllLayers();
              },
              child: const Icon(Icons.refresh),
            ),
          ),

          // Loading Indicator
          if (mapState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error Message
          if (mapState.error != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    mapState.error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapboxMap?.dispose();
    super.dispose();
  }
}