import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/widgets/map/depth_layer.dart';
import 'package:Bahaar/utilities/map_constants.dart';

/// Demo page showcasing the depth layer functionality
///
/// Features demonstrated:
/// - OpenSeaMap bathymetric overlay
/// - Depth layer toggle controls
/// - Opacity adjustment
/// - Layer stacking order
/// - Integration with base map
class DepthLayerDemo extends StatefulWidget {
  const DepthLayerDemo({super.key});

  @override
  State<DepthLayerDemo> createState() => _DepthLayerDemoState();
}

class _DepthLayerDemoState extends State<DepthLayerDemo> {
  final MapController _mapController = MapController();
  bool _showDepthLayer = true;
  double _depthLayerOpacity = MapConstants.depthLayerOpacity;
  bool _mapReady = false;

  // Test locations with interesting depth features
  final List<({String name, LatLng location, double zoom})> _testLocations = [
    (
      name: 'Bahrain Harbor',
      location: const LatLng(26.2361, 50.5831),
      zoom: 14.0,
    ),
    (
      name: 'Gulf of Bahrain',
      location: const LatLng(26.0667, 50.5577),
      zoom: 11.0,
    ),
    (
      name: 'Shallow Waters',
      location: const LatLng(26.1500, 50.4500),
      zoom: 13.0,
    ),
    (
      name: 'Shipping Channel',
      location: const LatLng(26.2000, 50.6000),
      zoom: 12.0,
    ),
  ];

  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });
  }

  void _goToLocation(int index) {
    if (!_mapReady) return;
    final loc = _testLocations[index];
    _mapController.move(loc.location, loc.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depth Layer Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map with depth layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                MapConstants.defaultLatitude,
                MapConstants.defaultLongitude,
              ),
              initialZoom: MapConstants.defaultZoom,
              minZoom: MapConstants.osmMinZoom.toDouble(),
              maxZoom: MapConstants.osmMaxZoom.toDouble(),
              onMapReady: _onMapReady,
            ),
            children: [
              // Base layer - OpenStreetMap
              TileLayer(
                urlTemplate: MapConstants.osmBaseUrl,
                userAgentPackageName: MapConstants.userAgent,
                maxZoom: MapConstants.osmMaxZoom.toDouble(),
                subdomains: MapConstants.osmSubdomains,
              ),

              // Depth layer - OpenSeaMap
              DepthLayer(
                isVisible: _showDepthLayer,
                opacity: _depthLayerOpacity,
              ),
            ],
          ),

          // Depth layer controls (top left)
          Positioned(
            top: 16,
            left: 16,
            child: DepthLayerControl(
              isVisible: _showDepthLayer,
              opacity: _depthLayerOpacity,
              onVisibilityChanged: (value) {
                setState(() {
                  _showDepthLayer = value;
                });
              },
              onOpacityChanged: (value) {
                setState(() {
                  _depthLayerOpacity = value;
                });
              },
            ),
          ),

          // Test location buttons (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.explore, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Test Locations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _testLocations.length,
                    itemBuilder: (context, index) {
                      final loc = _testLocations[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 18),
                        title: Text(
                          loc.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => _goToLocation(index),
                        enabled: _mapReady,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Info panel (bottom)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'About Depth Layer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The depth layer uses OpenSeaMap to display nautical charts with bathymetric (depth) data. '
                    'Zoom in (level 12+) to see detailed depth contours, navigation buoys, and harbor facilities. '
                    'This layer is essential for safe marine navigation.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildLegendItem('Blue lines', 'Depth contours'),
                      _buildLegendItem('Buoys', 'Navigation marks'),
                      _buildLegendItem('Numbers', 'Depth soundings (m)'),
                      _buildLegendItem('Red/Green', 'Port/Starboard marks'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
