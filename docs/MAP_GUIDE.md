# Map Refactoring Guide

## Overview

The integrated map screen has been completely refactored to provide:
1. **Better depth visualization** with colored bathymetric maps
2. **Organized code structure** with separation of concerns
3. **Enhanced layer management** with centralized state
4. **Improved maintainability** and extensibility

---

## New Architecture

### File Structure

```
lib/
├── services/
│   ├── navigation_mask.dart           # Navigation validation (unchanged)
│   └── map_layer_manager.dart         # NEW: Centralized layer state management
│
├── widgets/map/
│   ├── enhanced_depth_layer.dart      # NEW: Multi-type depth visualization
│   ├── geojson_layers.dart            # NEW: GeoJSON parsing and rendering
│   ├── layer_control_panel.dart       # NEW: Reusable layer control UI
│   └── depth_layer.dart               # OLD: Simple OpenSeaMap overlay
│
├── screens/
│   ├── integrated_map_refactored.dart # NEW: Clean refactored version
│   └── integrated_map.dart            # OLD: Original 700+ line version
│
└── utilities/
    └── map_constants.dart              # Configuration constants (unchanged)
```

---

## Key Improvements

### 1. Depth Visualization Types

The new `EnhancedDepthLayer` supports **three visualization modes**:

#### **Bathymetric (Colored Depth Map)**
- Shows depth in color gradient
- Light blue = shallow water (0-10m)
- Medium blue = medium depth (50-200m)
- Dark blue/purple = deep water (3000m+)
- Uses EMODnet Bathymetry tiles
- Best for understanding water depth at a glance

#### **Nautical Chart**
- Traditional OpenSeaMap navigation symbols
- Depth contours and soundings
- Buoys and navigation markers
- Harbor facilities and hazards
- Best for detailed navigation

#### **Combined View**
- Both bathymetric colors AND nautical symbols
- Depth colors at 60% opacity
- Nautical overlay at full opacity
- Best comprehensive view

### 2. Organized Code Structure

#### **Before (integrated_map.dart)**
```
❌ 700+ lines in a single file
❌ All layer building logic mixed with UI
❌ State management scattered throughout
❌ Difficult to test or modify
```

#### **After (New Architecture)**
```
✅ Separated into focused modules:
   - MapLayerManager: State management (~150 lines)
   - EnhancedDepthLayer: Depth visualization (~170 lines)
   - GeoJsonLayerBuilder: Data parsing (~180 lines)
   - LayerControlPanel: UI controls (~250 lines)
   - IntegratedMapRefactored: Main screen (~430 lines)

✅ Each component has single responsibility
✅ Easy to test, modify, and extend
✅ Reusable widgets
```

### 3. Centralized Layer Management

The `MapLayerManager` service provides:

```dart
// Single source of truth for all layer states
final layerManager = MapLayerManager();

// Simple property access
layerManager.showDepthLayer = true;
layerManager.depthLayerOpacity = 0.7;
layerManager.depthVisualizationType = DepthVisualizationType.bathymetric;

// Automatic notification to all listeners
// No need to manually call setState()
```

**Benefits:**
- Centralized state management
- ChangeNotifier pattern for reactive updates
- No prop drilling through widget tree
- Easy to persist/restore layer preferences

---

## How to Use

### Option 1: Use the New Refactored Map

Replace your current map screen with the refactored version:

```dart
// In your navigation/routing
MaterialPageRoute(
  builder: (context) => const IntegratedMapRefactored(),
)
```

### Option 2: Keep Both Versions

You can keep both versions during transition:

```dart
// Old version
MaterialPageRoute(
  builder: (context) => const IntegratedMap(),
)

// New version
MaterialPageRoute(
  builder: (context) => const IntegratedMapRefactored(),
)
```

---

## Component Usage Examples

### 1. Using EnhancedDepthLayer Standalone

```dart
// In any FlutterMap widget
FlutterMap(
  children: [
    TileLayer(/* base map */),

    // Add enhanced depth layer
    EnhancedDepthLayer(
      isVisible: true,
      opacity: 0.7,
      visualizationType: DepthVisualizationType.bathymetric,
    ),
  ],
)
```

### 2. Using GeoJsonLayerBuilder

```dart
// Load and parse GeoJSON
final jsonData = json.decode(await rootBundle.loadString('path/to/file.geojson'));
final builder = GeoJsonLayerBuilder(jsonData);

// Build specific layers
final fishingSpots = builder.buildFishingSpotMarkers();
final shippingLanes = builder.buildShippingLanes();
final zones = builder.buildAllZones();

// Or use the widget
GeoJsonMapLayers(
  builder: builder,
  showFishingSpots: true,
  showShippingLanes: true,
  showProtectedZones: true,
  showFishingZones: true,
)
```

### 3. Using MapLayerManager

```dart
class MyMapScreen extends StatefulWidget {
  @override
  State<MyMapScreen> createState() => _MyMapScreenState();
}

class _MyMapScreenState extends State<MyMapScreen> {
  late final MapLayerManager _layerManager;

  @override
  void initState() {
    super.initState();
    _layerManager = MapLayerManager();
  }

  @override
  void dispose() {
    _layerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          children: [
            // React to layer manager changes
            ListenableBuilder(
              listenable: _layerManager,
              builder: (context, _) {
                return EnhancedDepthLayer(
                  isVisible: _layerManager.showDepthLayer,
                  opacity: _layerManager.depthLayerOpacity,
                  visualizationType: _layerManager.depthVisualizationType,
                );
              },
            ),
          ],
        ),

        // Layer controls
        LayerControlPanel(
          layerManager: _layerManager,
          maskInitialized: true,
          onClose: () {},
        ),
      ],
    );
  }
}
```

---

## Depth Visualization Details

### Bathymetric Tile Source

**Provider:** EMODnet Bathymetry (European Marine Observation and Data Network)

**URL:** `https://tiles.emodnet-bathymetry.eu/2020/baselayer/web_mercator/{z}/{x}/{y}.png`

**Coverage:**
- Comprehensive global coverage
- High resolution in European waters
- Good coverage for Gulf region (Bahrain)

**Color Scale:**
| Depth Range | Color | Description |
|-------------|-------|-------------|
| 0-10m | Very light blue (#E6F3FF) | Very shallow, coastal |
| 10-50m | Light blue (#99CCFF) | Shallow, navigable |
| 50-200m | Medium blue (#4DA6FF) | Medium depth |
| 200-1000m | Deep blue (#0066CC) | Deep water |
| 1000-3000m | Navy blue (#003D7A) | Very deep |
| 3000m+ | Dark navy (#001F3F) | Abyssal depths |

**Alternative Tile Sources (if needed):**
```dart
// GEBCO (General Bathymetric Chart of the Oceans)
'https://tiles.arcgis.com/tiles/C8EMgrsFcRFL6LrL/arcgis/rest/services/GEBCO_basemap_NCEI/MapServer/tile/{z}/{y}/{x}'

// NOAA (US coverage)
'https://gis.ngdc.noaa.gov/arcgis/rest/services/web_mercator/gebco08_hillshade/MapServer/tile/{z}/{y}/{x}'
```

### Recommended Zoom Levels

| Zoom Level | Best Use Case | Visibility |
|------------|---------------|------------|
| 3-9 | Regional overview | Limited depth detail |
| 10-12 | Navigation planning | Good depth visibility |
| 13-15 | Detailed navigation | Excellent depth detail |
| 16-18 | Harbor/coastal detail | Maximum detail |

---

## Migration Guide

### If You Want to Replace the Old Map:

1. **Update your route:**
   ```dart
   // Change from:
   import 'package:Bahaar/screens/integrated_map.dart';

   // To:
   import 'package:Bahaar/screens/integrated_map_refactored.dart';
   ```

2. **Update the widget:**
   ```dart
   // Change from:
   const IntegratedMap()

   // To:
   const IntegratedMapRefactored()
   ```

3. **(Optional) Delete old files:**
   - `lib/screens/integrated_map.dart` - if you don't need it anymore
   - `lib/widgets/map/depth_layer.dart` - replaced by enhanced version

### If You Want to Keep Both:

No changes needed! Both versions work independently.

---

## Testing the New Features

### Test Depth Visualization

1. Open the refactored map
2. Click the layers button (top left)
3. Toggle "Show Depth Layer" on
4. Try each visualization type:
   - **Bathymetric Colors** - should see blue color gradient
   - **Nautical Chart** - should see black symbols and contours
   - **Combined View** - should see both colors and symbols
5. Adjust opacity slider - layer should fade in/out
6. Click the info button (below layers) to see depth legend

### Test GeoJSON Layers

1. In layer controls, toggle GeoJSON layers
2. Verify each sub-layer toggles correctly:
   - Fishing Spots (blue markers)
   - Shipping Lanes (red/orange lines)
   - Protected Zones (red/brown polygons)
   - Fishing Zones (green polygons)
3. Feature counts should display correctly

### Test Navigation Mask

1. Wait for "Navigation Ready" indicator (green, top right)
2. Tap on water - should work normally
3. Tap on land - should show warning with "Find Water" button
4. Click "Find Water" - should move to nearest water location
5. Toggle "Show Mask Boundary" in layers - should show purple outline

---

## Performance Considerations

### Tile Loading

- Bathymetric tiles are loaded from external server
- Network connection required
- Tiles are cached by flutter_map
- `keepBuffer: 2` maintains smooth panning

### Layer Rendering Order

Optimized bottom-to-top:
1. Base map (OpenStreetMap)
2. Depth layer (bathymetric/nautical)
3. GeoJSON polygons (zones)
4. GeoJSON polylines (shipping lanes)
5. GeoJSON markers (fishing spots)
6. Navigation mask overlay
7. User location marker

### State Management

- `MapLayerManager` uses ChangeNotifier pattern
- Only affected widgets rebuild on layer changes
- ListenableBuilder ensures efficient updates
- No unnecessary full-screen rebuilds

---

## Troubleshooting

### Bathymetric tiles not loading

**Symptoms:** Depth colors don't appear, only base map shows

**Possible causes:**
1. No internet connection
2. EMODnet server down
3. Tile URL changed

**Solutions:**
1. Check internet connection
2. Try alternative tile source (see "Alternative Tile Sources" above)
3. Check browser console for tile request errors

### Depth colors too faint

**Solutions:**
1. Increase opacity slider to 0.8-1.0
2. Use "Bathymetric Colors" mode (not Combined)
3. Zoom in to level 12+ for better detail

### Layer controls not responding

**Check:**
1. MapLayerManager properly initialized in initState
2. MapLayerManager disposed in dispose method
3. ListenableBuilder wrapping layers correctly

---

## Future Enhancements

### Potential additions:

1. **Custom depth color schemes**
   - Allow user to choose color gradient
   - Light/dark mode support
   - Color-blind friendly palettes

2. **Offline tile caching**
   - Pre-download tiles for regions
   - Store bathymetric data locally
   - Reduce network dependency

3. **3D depth visualization**
   - Extrude polygons based on depth
   - Side-view depth profiles
   - Interactive 3D exploration

4. **Depth contour lines**
   - Generate custom contours from data
   - Adjustable contour intervals
   - Label depth values

5. **Integration with sonar data**
   - Real-time depth readings
   - Personal depth measurements
   - Custom depth overlays

---

## Support

For questions or issues:
1. Check this guide first
2. Review the code comments in each file
3. Test with the refactored version
4. Compare behavior with old version

---

## Summary

The refactored map architecture provides:

✅ **Colored depth visualization** - See depth in intuitive color gradients
✅ **Better code organization** - Modular, maintainable, testable
✅ **Flexible layer system** - Easy to add/remove/modify layers
✅ **Improved performance** - Efficient state management
✅ **Enhanced UX** - Intuitive layer controls and depth legend

**Recommendation:** Start using `IntegratedMapRefactored` for new development. The old version can be kept as a backup during transition.
