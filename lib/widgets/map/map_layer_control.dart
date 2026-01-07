import 'package:flutter/material.dart';
import '../../utilities/map_constants.dart';

class MapLayerControl extends StatelessWidget {
  final Set<String> visibleLayers;
  final Function(String) onToggleLayer;

  const MapLayerControl({
    super.key,
    required this.visibleLayers,
    required this.onToggleLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayerItem(
            context,
            'Bathymetry',
            MapConstants.bathymetryLayerId,
            Icons.water,
            Colors.blue,
          ),
          const Divider(height: 1),
          _buildLayerItem(
            context,
            'Fishing Activity',
            MapConstants.fishingActivityLayerId,
            Icons.directions_boat,
            Colors.orange,
          ),
          const Divider(height: 1),
          _buildLayerItem(
            context,
            'Fish Probability',
            MapConstants.fishProbabilityLayerId,
            Icons.analytics,
            Colors.green,
          ),
          const Divider(height: 1),
          _buildLayerItem(
            context,
            'Restricted Areas',
            MapConstants.restrictedAreasLayerId,
            Icons.block,
            Colors.red,
          ),
          const Divider(height: 1),
          _buildLayerItem(
            context,
            'Weather',
            MapConstants.weatherLayerId,
            Icons.cloud,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem(
    BuildContext context,
    String label,
    String layerId,
    IconData icon,
    Color color,
  ) {
    final isVisible = visibleLayers.contains(layerId);

    return InkWell(
      onTap: () => onToggleLayer(layerId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isVisible ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isVisible ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 18,
              color: isVisible ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}