import 'package:flutter/material.dart';
import 'package:Bahaar/services/map_layer_manager.dart';
import 'package:Bahaar/widgets/map/geojson_layers.dart';

/// Control panel widget for managing all map layers
class LayerControlPanel extends StatelessWidget {
  final MapLayerManager layerManager;
  final GeoJsonLayerBuilder? geoJsonBuilder;
  final bool maskInitialized;
  final VoidCallback onClose;
  final VoidCallback? onEnterAdminEdit;

  const LayerControlPanel({
    super.key,
    required this.layerManager,
    this.geoJsonBuilder,
    required this.maskInitialized,
    required this.onClose,
    this.onEnterAdminEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 600,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            _buildDepthLayerSection(),
            const Divider(),
            _buildGeoJsonSection(),
            const Divider(),
            _buildFishingActivitySection(),
            const Divider(),
            _buildNavigationMaskSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.layers, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Map Layers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDepthLayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Depth Visualization',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Depth layer toggle
        SwitchListTile(
          title: const Text('Show Depth Layer', style: TextStyle(fontSize: 13)),
          value: layerManager.showDepthLayer,
          onChanged: (val) => layerManager.showDepthLayer = val,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),

        if (layerManager.showDepthLayer) ...[
          // Visualization type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visualization Type',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ...DepthVisualizationType.values.map((type) {
                  return RadioListTile<DepthVisualizationType>(
                    title: Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      type.description,
                      style: const TextStyle(fontSize: 9),
                    ),
                    value: type,
                    groupValue: layerManager.depthVisualizationType,
                    onChanged: (val) {
                      if (val != null) {
                        layerManager.depthVisualizationType = val;
                      }
                    },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 8),

                // Opacity slider
                const Text(
                  'Layer Opacity',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Slider(
                  value: layerManager.depthLayerOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(layerManager.depthLayerOpacity * 100).round()}%',
                  onChanged: (val) => layerManager.depthLayerOpacity = val,
                ),

                // Info box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bathymetric: Colored depth map',
                        style: TextStyle(fontSize: 9),
                      ),
                      Text(
                        'Nautical: Navigation symbols',
                        style: TextStyle(fontSize: 9),
                      ),
                      Text(
                        'Combined: Both layers together',
                        style: TextStyle(fontSize: 9),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Best visibility: Zoom 10+',
                        style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeoJsonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GeoJSON Overlays',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Master toggle
        SwitchListTile(
          title: const Text('All GeoJSON Layers', style: TextStyle(fontSize: 13)),
          value: layerManager.showGeoJsonLayers,
          onChanged: (val) {
            layerManager.showGeoJsonLayers = val;
            if (val) {
              layerManager.toggleAllGeoJsonLayers(true);
            }
          },
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),

        if (layerManager.showGeoJsonLayers && geoJsonBuilder != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildGeoJsonLayerToggle(
                  'Fishing Spots',
                  Icons.location_on,
                  Colors.blue,
                  layerManager.showFishingSpots,
                  (val) => layerManager.showFishingSpots = val,
                  geoJsonBuilder!.getFeatureCount('fishing_spot'),
                ),
                _buildGeoJsonLayerToggle(
                  'Shipping Lanes',
                  Icons.route,
                  Colors.red,
                  layerManager.showShippingLanes,
                  (val) => layerManager.showShippingLanes = val,
                  geoJsonBuilder!.getFeatureCount('shipping_lane') +
                      geoJsonBuilder!.getFeatureCount('patrol_route'),
                ),
                _buildGeoJsonLayerToggle(
                  'Protected Zones',
                  Icons.shield,
                  Colors.red,
                  layerManager.showProtectedZones,
                  (val) => layerManager.showProtectedZones = val,
                  geoJsonBuilder!.getFeatureCount('protected_zone') +
                      geoJsonBuilder!.getFeatureCount('reef'),
                ),
                _buildGeoJsonLayerToggle(
                  'Fishing Zones',
                  Icons.agriculture,
                  Colors.green,
                  layerManager.showFishingZones,
                  (val) => layerManager.showFishingZones = val,
                  geoJsonBuilder!.getFeatureCount('fishing_zone'),
                ),
                _buildGeoJsonLayerToggle(
                  'Restricted Areas',
                  Icons.block,
                  Colors.red,
                  layerManager.showRestrictedAreas,
                  (val) => layerManager.showRestrictedAreas = val,
                  geoJsonBuilder!.getFeatureCount('restricted_area'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeoJsonLayerToggle(
    String title,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
    int count,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
      subtitle: Text(
        '$count feature${count != 1 ? 's' : ''}',
        style: const TextStyle(fontSize: 10),
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFishingActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fishing Activity',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Master toggle
        SwitchListTile(
          title:
              const Text('Show Fishing Activity', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            layerManager.showFishingActivity
                ? 'GFW vessel tracks & events'
                : 'Disabled',
            style: const TextStyle(fontSize: 10),
          ),
          value: layerManager.showFishingActivity,
          onChanged: (val) => layerManager.showFishingActivity = val,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),

        if (layerManager.showFishingActivity) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                _buildFishingSubToggle(
                  'Vessel Tracks',
                  Icons.route,
                  Colors.orange,
                  layerManager.showFishingActivityTracks,
                  (val) => layerManager.showFishingActivityTracks = val,
                ),
                _buildFishingSubToggle(
                  'Fishing Events',
                  Icons.phishing,
                  Colors.deepOrange,
                  layerManager.showFishingActivityEvents,
                  (val) => layerManager.showFishingActivityEvents = val,
                ),
                _buildFishingSubToggle(
                  'Intensity Heatmap',
                  Icons.thermostat,
                  Colors.red,
                  layerManager.showFishingActivityHeatmap,
                  (val) => layerManager.showFishingActivityHeatmap = val,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFishingSubToggle(
    String title,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildNavigationMaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Navigation Mask',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Show Mask Boundary', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            maskInitialized ? 'Coverage area outline' : 'Loading...',
            style: const TextStyle(fontSize: 10),
          ),
          value: layerManager.showMaskOverlay,
          onChanged: maskInitialized
              ? (val) => layerManager.showMaskOverlay = val
              : null,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        const Divider(),
        _buildAdminSection(),
      ],
    );
  }

  Widget _buildAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 16, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'Admin Tools',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit, size: 18, color: Colors.orange),
          title: const Text('Edit Mask', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            maskInitialized
                ? 'Paint water/land cells'
                : 'Loading...',
            style: const TextStyle(fontSize: 10),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: maskInitialized && onEnterAdminEdit != null
              ? () {
                  onEnterAdminEdit!();
                  onClose();
                }
              : null,
          enabled: maskInitialized,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }
}
