import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_provider.dart';
import '../widgets/map/map_layer_control.dart';
import '../widgets/map/map_legend.dart';

class map extends ConsumerStatefulWidget {
  const map({super.key});

  @override
  ConsumerState<map> createState() => _mapScreen();
}
class _mapScreen extends ConsumerState<map> {
  final MapController _mapController = MapController();

  @override
  void initState(){
    superh.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await ref.read(mapProvider.notifier).loadCurrentLocation();
    final location = ref.read(mapProvider).currentLocation;
    
    if (location != null) {
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        MapConsrants.defaultZoom,
      );

      ref.read(mapProvider.notifier).loadAllLayers();
    }
  }

  List<Marker> _buildFishingActivityMarkers() {
    final state = ref.watch(mapProvider);
    if (!state.visibleLayers.contains(MapConstants.fishingActivityLayerId)) {
      return [];
    }

    return state.fishingActivities.map((activity) {
      return Marker(
        point: LatLng(activity.position.latitude, activity.position.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FishingActivityBottomSheet(activity: activity),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.directions_boat, color: Colors.white, size: 20),
          ),
        ),
      );
    }).toList();
  }

  List<CircleMarker> _buildFishProbabilityHeatmap() {
    final state = ref.watch(mapProvider);
    if (!state.visibleLayers.contains(MapConstants.fishProbabilityLayerId)) {
      return [];
    }

    return state.fishProbabilities.map((probability) {
      return CircleMarker(
        point: LatLng(probability.position.latitude, probability.position.longitude),
        radius: 1000,
        useRadiusInMeter: true,
        color: _getHeatmapColor(probability.probability).withOpacity(0.5),
        borderColor: _getHeatmapColor(probability.probability),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  Color _getHeatmapColor(double probability) {
    if (probability < 0.3) return const Color(MapConstants.lowProbabilityColor);
    if (probability < 0.7) return const Color(MapConstants.mediumProbabilityColor);
    return const Color(MapConstants.highProbabilityColor);
  }

  List<Polygon> _buildRestrictedAreas() {
    final state = ref.watch(mapProvider);
    if (!state.visibleLayers.contains(MapConstants.restrictedAreasLayerId)) {
      return [];
    }

    return state.restrictedAreas.where((area) => area.isActive()).map((area) {
      return Polygon(
        points: area.polygon.map((pos) => LatLng(pos.latitude, pos.longitude)).toList(),
        color: _getRestrictedAreaColor(area.type).withOpacity(0.3),
        borderColor: _getRestrictedAreaColor(area.type),
        borderStrokeWidth: 2,
        isFilled: true,
      );
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                mapState.currentLocation?.latitude ?? MapConstants.defaultLatitude,
                mapState.currentLocation?.longitude ?? MapConstants.defaultLongitude,
              ),
              initialZoom: MapConstants.defaultZoom,
              minZoom: MapConstants.minZoom,
              maxZoom: MapConstants.maxZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              if (mapState.visibleLayers.contains(MapConstants.osmLayerId))
                TileLayer(
                  urlTemplate: MapConstants.osmTileUrl,
                  userAgentPackageName: 'com.bahaar.app',
                  maxZoom: 19,
                ),
              if (mapState.visibleLayers.contains(MapConstants.seaMarksLayerId))
                TileLayer(
                  urlTemplate: MapConstants.seaMarkTileUrl,
                  userAgentPackageName: 'com.bahaar.app',
                  maxZoom: 18,
                  backgroundColor: Colors.transparent,
                ),
              CircleLayer(circles: _buildFishProbabilityHeatmap()),
              PolygonLayer(polygons: _buildRestrictedAreas()),
              MarkerLayer(markers: _buildFishingActivityMarkers()),
              if (mapState.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        mapState.currentLocation!.latitude,
                        mapState.currentLocation!.longitude,
                      ),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 60,
            right: 16,
            child: MapLayerControl(
              visibleLayers: mapState.visibleLayers,
              onToggleLayer: (layerId) {
                ref.read(mapProvider.notifier).toggleLayer(layerId);
              },
            ),
          ),
          Positioned(
            bottom: 100,
            left: 16,
            child: MapLegend(visibleLayers: mapState.visibleLayers),
          ),
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location',
              onPressed: _initializeLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'refresh',
              onPressed: () => ref.read(mapProvider.notifier).loadAllLayers(),
              child: const Icon(Icons.refresh),
            ),
          ),
          Positioned(
            bottom: 260,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          if (mapState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
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
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(mapState.error!, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
