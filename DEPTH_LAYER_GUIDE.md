# Depth Layer Implementation Guide

## Overview

The depth layer adds bathymetric (water depth) data to your AquaNav map using **OpenSeaMap** tiles. This layer is essential for safe marine navigation, providing depth contours, navigation marks, buoys, harbors, and maritime hazards.

## Architecture

### Layered Map Structure

Your map follows a bottom-to-top layer architecture:

```
┌─────────────────────────────────────┐
│  4. Marker Layer (User Location)    │  ← Top (visible on top)
├─────────────────────────────────────┤
│  3. Depth Layer (OpenSeaMap)        │  ← NEW: Bathymetric data
├─────────────────────────────────────┤
│  2. Base Layer (OpenStreetMap)      │  ← Streets, land features
├─────────────────────────────────────┤
│  1. Navigation Mask (Binary data)   │  ← Bottom (background validation)
└─────────────────────────────────────┘
```

### File Structure

```
lib/
├── screens/
│   └── map.dart                    # Main map screen with integrated depth layer
├── widgets/
│   └── map/
│       ├── depth_layer.dart        # Depth layer widget + control panel
│       └── geojson_overlay_test_page.dart  # GeoJSON overlays (fishing spots, etc.)
├── utilities/
│   └── map_constants.dart          # Map configuration constants
├── services/
│   └── navigation_mask.dart        # Land/water validation
└── examples/
    └── depth_layer_demo.dart       # Standalone depth layer demo
```

## Components

### 1. MapConstants (`lib/utilities/map_constants.dart`)

Centralized configuration for all map layers:

```dart
class MapConstants {
  // OpenSeaMap depth layer
  static const String openSeaMapUrl = 'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png';
  static const int openSeaMapMaxZoom = 18;
  static const int openSeaMapMinZoom = 9;  // Best visibility starts at zoom 9
  static const double depthLayerOpacity = 0.8;

  // Recommended zoom levels
  static const double navigationZoom = 13.0;  // Optimal for navigation
  static const double harborZoom = 15.0;      // Detailed harbor view
}
```

### 2. DepthLayer Widget (`lib/widgets/map/depth_layer.dart`)

Main widget for rendering the depth layer:

```dart
DepthLayer(
  isVisible: true,           // Toggle visibility
  opacity: 0.8,              // Transparency (0.0 - 1.0)
  maxZoom: 18,               // Maximum zoom level
  minZoom: 9,                // Minimum zoom level
)
```

**Features:**
- Transparent tile overlay (blends with base map)
- Configurable opacity
- Performance optimized with tile buffering
- Smooth fade-in animations

### 3. DepthLayerControl Widget

Interactive UI control panel:

```dart
DepthLayerControl(
  isVisible: _showDepthLayer,
  opacity: _depthLayerOpacity,
  onVisibilityChanged: (value) {
    setState(() => _showDepthLayer = value);
  },
  onOpacityChanged: (value) {
    setState(() => _depthLayerOpacity = value);
  },
)
```

**Features:**
- Toggle switch for layer visibility
- Opacity slider (0-100%)
- Feature legend (depth contours, buoys, etc.)
- Compact, draggable UI

## Integration

### Adding Depth Layer to Your Map

In your map screen ([lib/screens/map.dart](lib/screens/map.dart)):

```dart
// 1. Add imports
import 'package:Bahaar/widgets/map/depth_layer.dart';
import 'package:Bahaar/utilities/map_constants.dart';

// 2. Add state variables
bool _showDepthLayer = true;
double _depthLayerOpacity = MapConstants.depthLayerOpacity;

// 3. Add layer to FlutterMap children (after base layer, before markers)
FlutterMap(
  children: [
    // Base layer
    TileLayer(
      urlTemplate: MapConstants.osmBaseUrl,
      ...
    ),

    // Depth layer (NEW)
    DepthLayer(
      isVisible: _showDepthLayer,
      opacity: _depthLayerOpacity,
    ),

    // Markers, overlays, etc.
    MarkerLayer(...),
  ],
)

// 4. Add control panel
Positioned(
  top: 50,
  left: 10,
  child: DepthLayerControl(
    isVisible: _showDepthLayer,
    opacity: _depthLayerOpacity,
    onVisibilityChanged: (value) => setState(() => _showDepthLayer = value),
    onOpacityChanged: (value) => setState(() => _depthLayerOpacity = value),
  ),
)
```

## OpenSeaMap Features

### What's Displayed at Different Zoom Levels

| Zoom Level | Visible Features |
|------------|-----------------|
| 9-11 | Major shipping lanes, large harbors |
| 12-13 | Depth contours, navigation channels, buoys |
| 14-15 | Detailed depth soundings, harbor facilities, anchorages |
| 16-18 | All nautical details, precise depth markers, small buoys |

### Nautical Symbols

OpenSeaMap uses international maritime symbols:

- **Blue contour lines**: Depth contours (isobaths)
- **Numbers**: Depth soundings in meters
- **Buoys**:
  - 🔴 Red: Port side (left when entering harbor)
  - 🟢 Green: Starboard side (right when entering harbor)
- **⚓ Anchors**: Anchorage areas
- **⚠️ Hazards**: Rocks, wrecks, obstructions
- **Purple areas**: Restricted/prohibited zones

## Why OpenSeaMap for Navigation?

### Pros ✅

1. **Nautical-Specific**: Designed for maritime navigation
2. **Depth Data**: Critical bathymetric information
3. **Free & Open**: No API keys or costs
4. **International Standards**: Uses IENC (International Electronic Navigational Chart) symbols
5. **Active Community**: Regularly updated by OpenSeaMap contributors
6. **Compatible**: Works seamlessly with OpenStreetMap base layer
7. **Transparent Tiles**: Overlays perfectly without hiding base map

### Perfect for AquaNav Because:

- **Fishing Navigation**: Shows safe depths for boat navigation
- **Harbor Information**: Displays ports, marinas, and facilities
- **Safety**: Marks hazards, restricted zones, and shallow areas
- **Route Planning**: Depth contours help plan safe routes
- **Integration**: Complements your existing navigation mask system

### Alternatives Considered

| Alternative | Pros | Cons |
|------------|------|------|
| **NOAA Charts** | Very accurate (US waters) | Limited to US, requires API |
| **Navionics** | Professional grade | Expensive, licensing required |
| **Custom Data** | Full control | Requires data collection, maintenance |
| **Google Maps** | Familiar | No depth data, not nautical-focused |

## Usage Examples

### Example 1: Basic Integration (Current Implementation)

See [lib/screens/map.dart](lib/screens/map.dart#L157-L171)

### Example 2: Standalone Demo

Run the depth layer demo:

```dart
import 'package:Bahaar/examples/depth_layer_demo.dart';

// Navigate to demo
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DepthLayerDemo()),
);
```

### Example 3: Custom Opacity for Day/Night Mode

```dart
// Adjust opacity based on time of day
double _getDepthLayerOpacity() {
  final hour = DateTime.now().hour;
  if (hour >= 6 && hour < 18) {
    return 0.8;  // Day: more transparent
  } else {
    return 0.6;  // Night: less transparent (easier to see)
  }
}
```

### Example 4: Zoom-Based Visibility

```dart
// Only show depth layer when zoomed in enough
DepthLayer(
  isVisible: _showDepthLayer && _mapController.camera.zoom >= 12.0,
  opacity: _depthLayerOpacity,
)
```

## Navigation Integration

### Combining with Navigation Mask

Your navigation mask validates land vs. water. The depth layer adds:

1. **Depth information**: How deep is the water?
2. **Navigation aids**: Where are the safe channels?
3. **Hazards**: What should be avoided?

```dart
// Check if location is navigable (from navigation_mask.dart)
if (_navigationMask.isPointNavigable(point)) {
  // Valid water location
  // Now use depth layer to check:
  // - Is there sufficient depth?
  // - Are there hazards nearby?
  // - What's the safest route?
}
```

### Future Enhancements

1. **Depth-Based Route Planning**
   - Parse OpenSeaMap depth data
   - Calculate routes that maintain minimum depth
   - Avoid shallow areas for larger vessels

2. **Depth Queries**
   - Tap on map to get depth at that location
   - Show depth profile along a route
   - Alert when approaching shallow water

3. **Custom Overlays**
   - Combine with fishing spot data
   - Overlay catch reports on depth contours
   - Mark safe anchorages

## Performance Considerations

### Tile Caching

OpenSeaMap tiles are cached automatically:

```dart
TileLayer(
  urlTemplate: MapConstants.openSeaMapUrl,
  keepBuffer: 2,  // Keep 2 extra tile levels in memory
)
```

### Network Optimization

- Tiles are loaded on-demand
- Transparent tiles are lightweight (~10-50 KB each)
- Use `minZoom: 9` to prevent loading at low zooms

### Memory Management

- Flutter Map automatically manages tile lifecycle
- Old tiles are evicted when memory is low
- Use `maxZoom: 18` to prevent excessive detail

## Testing

### Test Locations (Bahrain Region)

Try these coordinates to see depth layer features:

```dart
// Harbor area with depth markers
LatLng(26.2361, 50.5831), zoom: 14

// Shipping channel with buoys
LatLng(26.2000, 50.6000), zoom: 13

// Shallow coastal waters
LatLng(26.1500, 50.4500), zoom: 13
```

### Verification Checklist

- [ ] Depth contours visible at zoom 12+
- [ ] Navigation buoys appear at zoom 13+
- [ ] Opacity control works smoothly
- [ ] Toggle switch hides/shows layer
- [ ] No performance lag when panning
- [ ] Tiles load without errors
- [ ] Layer aligns with base map

## Troubleshooting

### Issue: Tiles Not Loading

**Cause**: Network issue or incorrect URL
**Solution**: Check console for 404 errors, verify `openSeaMapUrl`

### Issue: Layer Not Visible

**Cause**: Zoom level too low
**Solution**: Zoom in to level 12+ or adjust `minZoom`

### Issue: Poor Performance

**Cause**: Too many tiles loaded
**Solution**: Reduce `keepBuffer` or increase `minZoom`

### Issue: Wrong Layer Order

**Cause**: Depth layer added after markers
**Solution**: Ensure depth layer comes before MarkerLayer in children

## License & Attribution

- **OpenSeaMap**: [OpenSeaMap License](https://www.openseamap.org/)
- **Data**: OpenStreetMap contributors + OpenSeaMap contributors
- **Usage**: Free for all purposes, attribution required

Add this attribution to your app:

```dart
// In your about screen or map footer
Text('Map data © OpenStreetMap contributors, OpenSeaMap')
```

## Next Steps for Navigation

1. **Route Planning**: Use depth data to plan safe routes
2. **Waypoint Validation**: Check waypoints against depth minimums
3. **Real-Time Alerts**: Warn when approaching shallow water
4. **Offline Maps**: Cache OpenSeaMap tiles for offline use
5. **Custom Depth Layers**: Add region-specific depth data

## Questions?

- OpenSeaMap Docs: https://wiki.openstreetmap.org/wiki/OpenSeaMap
- Flutter Map: https://docs.fleaflet.dev/
- Issue Tracker: [Your GitHub repo]

---

**Ready for Navigation!** 🚤⚓🌊

Your map now has professional-grade nautical charts. The depth layer provides the essential bathymetric data needed for safe marine navigation.
