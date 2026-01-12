import 'package:flutter/foundation.dart';

/// Manages the state and configuration of all map layers
/// Provides a centralized way to control layer visibility, opacity, and settings
class MapLayerManager extends ChangeNotifier {
  // Base map layer
  bool _showBaseMap = true;

  // Depth layer configuration
  bool _showDepthLayer = true;
  double _depthLayerOpacity = 0.7;
  DepthVisualizationType _depthVisualizationType = DepthVisualizationType.bathymetric;

  // GeoJSON layers
  bool _showGeoJsonLayers = true;
  bool _showFishingSpots = true;
  bool _showShippingLanes = true;
  bool _showProtectedZones = true;
  bool _showFishingZones = true;

  // Navigation mask
  bool _showMaskOverlay = false;

  // UI control
  bool _showLayerControls = false;

  // Getters
  bool get showBaseMap => _showBaseMap;
  bool get showDepthLayer => _showDepthLayer;
  double get depthLayerOpacity => _depthLayerOpacity;
  DepthVisualizationType get depthVisualizationType => _depthVisualizationType;
  bool get showGeoJsonLayers => _showGeoJsonLayers;
  bool get showFishingSpots => _showFishingSpots;
  bool get showShippingLanes => _showShippingLanes;
  bool get showProtectedZones => _showProtectedZones;
  bool get showFishingZones => _showFishingZones;
  bool get showMaskOverlay => _showMaskOverlay;
  bool get showLayerControls => _showLayerControls;

  // Setters with notification
  set showBaseMap(bool value) {
    if (_showBaseMap != value) {
      _showBaseMap = value;
      notifyListeners();
    }
  }

  set showDepthLayer(bool value) {
    if (_showDepthLayer != value) {
      _showDepthLayer = value;
      notifyListeners();
    }
  }

  set depthLayerOpacity(double value) {
    if (_depthLayerOpacity != value) {
      _depthLayerOpacity = value.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  set depthVisualizationType(DepthVisualizationType value) {
    if (_depthVisualizationType != value) {
      _depthVisualizationType = value;
      notifyListeners();
    }
  }

  set showGeoJsonLayers(bool value) {
    if (_showGeoJsonLayers != value) {
      _showGeoJsonLayers = value;
      notifyListeners();
    }
  }

  set showFishingSpots(bool value) {
    if (_showFishingSpots != value) {
      _showFishingSpots = value;
      notifyListeners();
    }
  }

  set showShippingLanes(bool value) {
    if (_showShippingLanes != value) {
      _showShippingLanes = value;
      notifyListeners();
    }
  }

  set showProtectedZones(bool value) {
    if (_showProtectedZones != value) {
      _showProtectedZones = value;
      notifyListeners();
    }
  }

  set showFishingZones(bool value) {
    if (_showFishingZones != value) {
      _showFishingZones = value;
      notifyListeners();
    }
  }

  set showMaskOverlay(bool value) {
    if (_showMaskOverlay != value) {
      _showMaskOverlay = value;
      notifyListeners();
    }
  }

  set showLayerControls(bool value) {
    if (_showLayerControls != value) {
      _showLayerControls = value;
      notifyListeners();
    }
  }

  /// Toggle all GeoJSON sub-layers on/off
  void toggleAllGeoJsonLayers(bool value) {
    _showFishingSpots = value;
    _showShippingLanes = value;
    _showProtectedZones = value;
    _showFishingZones = value;
    notifyListeners();
  }

  /// Reset all layers to default state
  void resetToDefaults() {
    _showBaseMap = true;
    _showDepthLayer = true;
    _depthLayerOpacity = 0.7;
    _depthVisualizationType = DepthVisualizationType.bathymetric;
    _showGeoJsonLayers = true;
    _showFishingSpots = true;
    _showShippingLanes = true;
    _showProtectedZones = true;
    _showFishingZones = true;
    _showMaskOverlay = false;
    _showLayerControls = false;
    notifyListeners();
  }
}

/// Types of depth visualization available
enum DepthVisualizationType {
  /// Colored bathymetric depth map (blue gradient showing depth)
  bathymetric,

  /// OpenSeaMap nautical chart (navigation symbols, buoys, contours)
  nautical,

  /// Combined: bathymetric colors + nautical symbols overlay
  combined,
}

extension DepthVisualizationTypeExtension on DepthVisualizationType {
  String get displayName {
    switch (this) {
      case DepthVisualizationType.bathymetric:
        return 'Bathymetric Colors';
      case DepthVisualizationType.nautical:
        return 'Nautical Chart';
      case DepthVisualizationType.combined:
        return 'Combined View';
    }
  }

  String get description {
    switch (this) {
      case DepthVisualizationType.bathymetric:
        return 'Colored depth visualization (shallow to deep)';
      case DepthVisualizationType.nautical:
        return 'Navigation symbols and depth contours';
      case DepthVisualizationType.combined:
        return 'Depth colors with nautical overlay';
    }
  }
}
