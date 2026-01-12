import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/utilities/map_constants.dart';
import 'package:Bahaar/services/map_layer_manager.dart';

/// Enhanced depth layer widget with multiple visualization options:
/// 1. Bathymetric (colored depth map)
/// 2. Nautical (OpenSeaMap navigation chart)
/// 3. Combined (both layers)
class EnhancedDepthLayer extends StatelessWidget {
  final bool isVisible;
  final double opacity;
  final DepthVisualizationType visualizationType;

  const EnhancedDepthLayer({
    super.key,
    required this.isVisible,
    required this.opacity,
    required this.visualizationType,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    // Return the appropriate layer(s) based on visualization type
    switch (visualizationType) {
      case DepthVisualizationType.bathymetric:
        return _BathymetricDepthLayer(opacity: opacity);
      case DepthVisualizationType.nautical:
        return _NauticalChartLayer(opacity: opacity);
      case DepthVisualizationType.combined:
        return Stack(
          children: [
            _BathymetricDepthLayer(opacity: opacity * 0.6),
            _NauticalChartLayer(opacity: opacity),
          ],
        );
    }
  }
}

/// Bathymetric depth visualization layer (colored depth map)
/// Uses General Bathymetric Chart of the Oceans (GEBCO) or similar tiles
class _BathymetricDepthLayer extends StatelessWidget {
  final double opacity;

  const _BathymetricDepthLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    // GEBCO bathymetric tiles - shows depth in colors
    // Alternative sources:
    // 1. GEBCO: https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/GEBCO_basemap_NCEI/MapServer/tile/{z}/{y}/{x}
    // 2. NOAA: https://gis.ngdc.noaa.gov/arcgis/rest/services/web_mercator/gebco08_hillshade/MapServer/tile/{z}/{y}/{x}
    // 3. EMODnet: https://tiles.emodnet-bathymetry.eu/2020/baselayer/web_mercator/{z}/{x}/{y}.png

    return TileLayer(
      // Using EMODnet Bathymetry - European Marine Observation and Data Network
      // This shows actual depth colors: light blue (shallow) to dark blue/purple (deep)
      urlTemplate: 'https://tiles.emodnet-bathymetry.eu/2020/baselayer/web_mercator/{z}/{x}/{y}.png',
      userAgentPackageName: MapConstants.userAgent,
      maxZoom: 18,
      minZoom: 3,
      tileProvider: NetworkTileProvider(),
      keepBuffer: 2,
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

/// Nautical chart layer with navigation symbols (OpenSeaMap)
class _NauticalChartLayer extends StatelessWidget {
  final double opacity;

  const _NauticalChartLayer({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: MapConstants.openSeaMapUrl,
      userAgentPackageName: MapConstants.userAgent,
      maxZoom: MapConstants.openSeaMapMaxZoom.toDouble(),
      minZoom: MapConstants.openSeaMapMinZoom.toDouble(),
      tileProvider: NetworkTileProvider(),
      keepBuffer: 2,
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

/// Legend widget showing depth color scale
class DepthLegend extends StatelessWidget {
  const DepthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Depth Legend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(const Color(0xFFE6F3FF), '0-10m', 'Very Shallow'),
          _buildLegendItem(const Color(0xFF99CCFF), '10-50m', 'Shallow'),
          _buildLegendItem(const Color(0xFF4DA6FF), '50-200m', 'Medium'),
          _buildLegendItem(const Color(0xFF0066CC), '200-1000m', 'Deep'),
          _buildLegendItem(const Color(0xFF003D7A), '1000-3000m', 'Very Deep'),
          _buildLegendItem(const Color(0xFF001F3F), '3000m+', 'Abyssal'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String depth, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            depth,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
