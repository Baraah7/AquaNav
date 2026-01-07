import 'package:flutter/material.dart';
import '../../utilities/map_constants.dart';

class MapLegend extends StatelessWidget {
  final Set<String> visibleLayers;

  const MapLegend({
    super.key,
    required this.visibleLayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (visibleLayers.contains(MapConstants.fishProbabilityLayerId)) ...[
            _buildLegendItem('High Probability', Colors.red),
            _buildLegendItem('Medium Probability', Colors.yellow),
            _buildLegendItem('Low Probability', Colors.green),
            const SizedBox(height: 8),
          ],
          if (visibleLayers.contains(MapConstants.restrictedAreasLayerId)) ...[
            _buildLegendItem('Protected Area', Colors.green),
            _buildLegendItem('Military Zone', Colors.red),
            _buildLegendItem('Fishing Restricted', Colors.orange),
            const SizedBox(height: 8),
          ],
          if (visibleLayers.contains(MapConstants.fishingActivityLayerId)) ...[
            _buildIconLegendItem('Fishing Vessel', Icons.directions_boat, Colors.blue),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLegendItem(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}