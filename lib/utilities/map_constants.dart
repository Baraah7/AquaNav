/// Map layer configuration constants for AquaNav
/// Manages tile layer URLs and settings for different map overlays
library;

class MapConstants {
  // Prevent instantiation
  MapConstants._();

  /// OpenStreetMap base layer
  static const String osmBaseUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> osmSubdomains = ['a', 'b', 'c'];
  static const int osmMaxZoom = 19;
  static const int osmMinZoom = 1;

  /// OpenSeaMap nautical overlay (depth contours, buoys, navigation aids)
  /// Provides bathymetric data and maritime navigation features
  static const String openSeaMapUrl = 'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png';
  static const int openSeaMapMaxZoom = 18;
  static const int openSeaMapMinZoom = 9; // Best visibility starts at zoom 9

  /// Recommended zoom levels for different use cases
  static const double navigationZoom = 13.0; // Optimal for navigation
  static const double harborZoom = 15.0; // Detailed harbor view
  static const double overviewZoom = 10.0; // Regional overview
  static const double detailZoom = 16.0; // Maximum detail

  /// Depth visualization settings
  static const double depthLayerOpacity = 0.8; // OpenSeaMap overlay opacity

  /// User agent for tile requests
  static const String userAgent = 'com.bahaar.bahaarapp';

  /// Default map center (Bahrain)
  static const double defaultLatitude = 26.0667;
  static const double defaultLongitude = 50.5577;
  static const double defaultZoom = 10.0;
}
