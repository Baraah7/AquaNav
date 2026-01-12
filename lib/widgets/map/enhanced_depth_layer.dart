import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/utilities/map_constants.dart';
import 'package:Bahaar/services/map_layer_manager.dart';
import 'package:Bahaar/services/navigation_mask.dart';

/// Enhanced depth layer widget with multiple visualization options:
/// 1. Bathymetric (colored depth map)
/// 2. Nautical (OpenSeaMap navigation chart)
/// 3. Combined (both layers)
class EnhancedDepthLayer extends StatelessWidget {
  final bool isVisible;
  final double opacity;
  final DepthVisualizationType visualizationType;
  final NavigationMask? navigationMask;

  const EnhancedDepthLayer({
    super.key,
    required this.isVisible,
    required this.opacity,
    required this.visualizationType,
    this.navigationMask,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    // Return the appropriate layer(s) based on visualization type
    switch (visualizationType) {
      case DepthVisualizationType.bathymetric:
        return _BathymetricDepthLayer(
          opacity: opacity,
          navigationMask: navigationMask,
        );
      case DepthVisualizationType.nautical:
        return _NauticalChartLayer(
          opacity: opacity,
          navigationMask: navigationMask,
        );
      case DepthVisualizationType.combined:
        return Stack(
          children: [
            _BathymetricDepthLayer(
              opacity: opacity * 0.6,
              navigationMask: navigationMask,
            ),
            _NauticalChartLayer(
              opacity: opacity,
              navigationMask: navigationMask,
            ),
          ],
        );
    }
  }
}

/// Bathymetric depth visualization layer (colored depth map)
/// Uses General Bathymetric Chart of the Oceans (GEBCO) or similar tiles
class _BathymetricDepthLayer extends StatelessWidget {
  final double opacity;
  final NavigationMask? navigationMask;

  const _BathymetricDepthLayer({
    required this.opacity,
    this.navigationMask,
  });

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
        final maskedTile = _WaterMaskedTile(
          tile: tile,
          navigationMask: navigationMask,
          opacity: opacity,
          child: tileWidget,
        );

        return maskedTile;
      },
    );
  }
}

/// Nautical chart layer with navigation symbols (OpenSeaMap)
class _NauticalChartLayer extends StatelessWidget {
  final double opacity;
  final NavigationMask? navigationMask;

  const _NauticalChartLayer({
    required this.opacity,
    this.navigationMask,
  });

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
        final maskedTile = _WaterMaskedTile(
          tile: tile,
          navigationMask: navigationMask,
          opacity: opacity,
          child: tileWidget,
        );

        return maskedTile;
      },
    );
  }
}

/// Widget that masks tile content to only show over water areas
class _WaterMaskedTile extends StatelessWidget {
  final TileImage tile;
  final NavigationMask? navigationMask;
  final double opacity;
  final Widget child;

  const _WaterMaskedTile({
    required this.tile,
    required this.navigationMask,
    required this.opacity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // If no navigation mask is available, just apply opacity
    if (navigationMask == null || !navigationMask!.isInitialized) {
      return Opacity(
        opacity: opacity,
        child: child,
      );
    }

    // Apply water mask: clip the tile to only show over water areas
    return ClipPath(
      clipper: _WaterOnlyClipper(
        tile: tile,
        navigationMask: navigationMask!,
      ),
      child: Opacity(
        opacity: opacity,
        child: child,
      ),
    );
  }
}

/// Custom clipper that only shows the tile over water areas
class _WaterOnlyClipper extends CustomClipper<Path> {
  final TileImage tile;
  final NavigationMask navigationMask;

  _WaterOnlyClipper({
    required this.tile,
    required this.navigationMask,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate the geographic bounds of this tile
    final coords = tile.coordinates;
    final bounds = _tileToBounds(coords.x, coords.y, coords.z);

    // Sample points across the tile to create water regions
    const samples = 32; // Higher resolution for smoother edges
    final stepX = size.width / samples;
    final stepY = size.height / samples;

    // Build path for water areas
    for (int y = 0; y < samples; y++) {
      for (int x = 0; x < samples; x++) {
        // Convert tile pixel to geographic coordinates (center of cell)
        final lon = bounds.west + ((x + 0.5) / samples) * (bounds.east - bounds.west);
        final lat = bounds.north - ((y + 0.5) / samples) * (bounds.north - bounds.south);

        // Check if this point is on water
        if (navigationMask.isNavigable(lon, lat)) {
          // Add this cell to the path
          path.addRect(Rect.fromLTWH(
            x * stepX,
            y * stepY,
            stepX + 0.5, // Small overlap to avoid gaps
            stepY + 0.5,
          ));
        }
      }
    }

    return path;
  }

  @override
  bool shouldReclip(_WaterOnlyClipper oldClipper) {
    final coords = tile.coordinates;
    final oldCoords = oldClipper.tile.coordinates;
    return coords.x != oldCoords.x ||
        coords.y != oldCoords.y ||
        coords.z != oldCoords.z;
  }

  /// Convert tile coordinates to geographic bounds
  _TileBounds _tileToBounds(int x, int y, int z) {
    final n = 1 << z; // 2^z
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;

    final north = _tile2lat(y, z);
    final south = _tile2lat(y + 1, z);

    return _TileBounds(north: north, south: south, east: east, west: west);
  }

  /// Convert tile Y coordinate to latitude
  double _tile2lat(int y, int z) {
    final n = 1 << z;
    final value = pi * (1 - 2 * y / n);
    final sinhValue = (exp(value) - exp(-value)) / 2;
    final latRad = atan(sinhValue);
    return latRad * 180.0 / pi;
  }
}

/// Helper class for tile geographic bounds
class _TileBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  _TileBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
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
