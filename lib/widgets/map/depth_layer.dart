import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/utilities/map_constants.dart';

/// Depth layer widget for displaying bathymetric (depth) data
///
/// Uses OpenSeaMap tiles to display:
/// - Depth contours and soundings
/// - Navigation marks and buoys
/// - Harbor facilities
/// - Maritime hazards
/// - Shipping channels
///
/// This layer is essential for safe marine navigation
class DepthLayer extends StatelessWidget {
  /// Controls the visibility of the depth layer
  final bool isVisible;

  /// Opacity of the depth overlay (0.0 to 1.0)
  final double opacity;

  /// Maximum zoom level for the depth tiles
  final int maxZoom;

  /// Minimum zoom level for the depth tiles
  final int minZoom;

  const DepthLayer({
    super.key,
    this.isVisible = true,
    this.opacity = MapConstants.depthLayerOpacity,
    this.maxZoom = MapConstants.openSeaMapMaxZoom,
    this.minZoom = MapConstants.openSeaMapMinZoom,
  });

  @override
  Widget build(BuildContext context) {
    // Return empty widget if layer is hidden
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return TileLayer(
      urlTemplate: MapConstants.openSeaMapUrl,
      userAgentPackageName: MapConstants.userAgent,
      maxZoom: maxZoom.toDouble(),
      minZoom: minZoom.toDouble(),
      // OpenSeaMap uses transparent tiles, so it overlays nicely
      tileProvider: NetworkTileProvider(),

      // Performance optimization: keep tiles in memory
      keepBuffer: 2,

      // Fade in animation for smooth loading
      tileBuilder: (context, tileWidget, tile) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: opacity),
            BlendMode.modulate,
          ),
          child: tileWidget,
        );
      },
    );
  }
}

/// Control panel widget for managing depth layer visibility and settings
class DepthLayerControl extends StatelessWidget {
  final bool isVisible;
  final double opacity;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<double>? onOpacityChanged;

  const DepthLayerControl({
    super.key,
    required this.isVisible,
    required this.opacity,
    required this.onVisibilityChanged,
    this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.waves,
                color: isVisible ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                'Depth Layer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: isVisible,
                onChanged: onVisibilityChanged,
                activeTrackColor: Colors.blue,
              ),
            ],
          ),
          if (isVisible && onOpacityChanged != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Opacity',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Slider(
              value: opacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(opacity * 100).round()}%',
              onChanged: onOpacityChanged,
            ),
          ],
          if (isVisible) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nautical Features:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Depth contours & soundings',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    '• Navigation buoys & marks',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    '• Harbor facilities',
                    style: TextStyle(fontSize: 10),
                  ),
                  Text(
                    '• Maritime hazards',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
