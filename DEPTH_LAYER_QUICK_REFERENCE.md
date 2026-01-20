# Depth Layer - Quick Reference Card

## ⚡ At a Glance

**What:** OpenSeaMap nautical charts overlaid on your map
**Where:** Integrated into [integrated_map.dart](lib/screens/integrated_map.dart)
**Status:** ✅ Production ready
**Zoom:** Best visibility at level 12+

## 🎯 Quick Facts

| Property | Value |
|----------|-------|
| **Data Source** | OpenSeaMap tiles |
| **URL** | `https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png` |
| **Default Opacity** | 80% |
| **Min Zoom** | 9 |
| **Max Zoom** | 18 |
| **Optimal Zoom** | 13-15 |
| **Layer Position** | Layer 2 (between base map and overlays) |
| **File Size** | ~10-50 KB per tile |
| **API Key Required** | No |
| **Cost** | Free |

## 📍 Key Files

```
lib/
├── screens/
│   ├── integrated_map.dart    ⭐ PRODUCTION (all 5 layers)
│   └── map.dart                🔧 TESTING (depth layer focus)
├── widgets/map/
│   └── depth_layer.dart        📦 Depth layer widget
├── utilities/
│   └── map_constants.dart      ⚙️ Configuration
└── examples/
    └── depth_layer_demo.dart   🎮 Standalone demo
```

## 🎨 What It Shows

| Feature | Color | Symbol |
|---------|-------|--------|
| Depth contours | Blue lines | Curved lines |
| Depth soundings | Blue/Black | Numbers (meters) |
| Port buoys | Red | 🔴 |
| Starboard buoys | Green | 🟢 |
| Harbors | Various | 🏖️ |
| Hazards | Orange/Yellow | ⚠️ |
| Anchorages | Purple | ⚓ |

## 🎮 Controls

### In Simple Map (map.dart)
- **Location:** Top-left panel (always visible)
- **Toggle:** On/Off switch
- **Opacity:** Slider 0-100%
- **Info:** Feature legend

### In Integrated Map (integrated_map.dart) ⭐
- **Location:** Layer control panel (top-left)
- **Access:** Tap layers icon to open
- **Toggle:** "OpenSeaMap Nautical" switch
- **Opacity:** Slider in expandable section
- **Info:** Shows features + zoom hint

## 💻 Code Snippets

### Using Depth Layer Widget
```dart
DepthLayer(
  isVisible: true,      // Toggle visibility
  opacity: 0.8,         // 80% opacity
  maxZoom: 18,          // Maximum detail
  minZoom: 9,           // Start showing
)
```

### State Management
```dart
// In your State class
bool _showDepthLayer = true;
double _depthLayerOpacity = 0.8;

// In your UI
DepthLayer(
  isVisible: _showDepthLayer,
  opacity: _depthLayerOpacity,
)
```

### Toggle Control
```dart
Switch(
  value: _showDepthLayer,
  onChanged: (val) => setState(() => _showDepthLayer = val),
)
```

### Opacity Slider
```dart
Slider(
  value: _depthLayerOpacity,
  min: 0.0,
  max: 1.0,
  onChanged: (val) => setState(() => _depthLayerOpacity = val),
)
```

## 🔧 Configuration

### Change Default Opacity
```dart
// lib/utilities/map_constants.dart
static const double depthLayerOpacity = 0.6;  // Default to 60%
```

### Change Minimum Zoom
```dart
// lib/utilities/map_constants.dart
static const int openSeaMapMinZoom = 11;  // Show from zoom 11
```

### Hide by Default
```dart
// In your map screen
bool _showDepthLayer = false;  // Start hidden
```

## 🗺️ Layer Stack Order

```
5. User Location ← Top (always visible)
4. Navigation Mask
3. GeoJSON Overlays (fishing spots, lanes, zones)
2. Depth Layer ← HERE!
1. Base Map ← Bottom
```

**Why Layer 2?**
- Shows through base map
- Under GeoJSON for context
- Transparent tiles blend well

## 🎯 Best Practices

### DO ✅
- Enable depth layer for navigation
- Zoom to 13+ for best visibility
- Adjust opacity for readability
- Combine with fishing spots
- Use with navigation mask

### DON'T ❌
- Rely on depth at zoom < 12
- Set opacity too high (loses base map)
- Ignore depth contours when navigating
- Navigate without checking depth
- Forget to attribute OpenSeaMap

## 📊 Zoom Level Guide

| Zoom | Visibility | Use Case |
|------|-----------|----------|
| 1-8  | ❌ Hidden | Not useful |
| 9-11 | ⚠️ Basic | Major features only |
| 12-13 | ✅ Good | Navigation ⭐ |
| 14-15 | ✅✅ Great | Detailed navigation |
| 16-18 | ✅✅✅ Excellent | Harbor approach |

## 🚀 Quick Start Commands

```bash
# Run your app
flutter run

# Analyze depth layer files
flutter analyze lib/widgets/map/depth_layer.dart

# Check integrated map
flutter analyze lib/screens/integrated_map.dart
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Tiles not loading | Check internet connection |
| Layer not visible | Zoom to 12+ |
| Too transparent | Increase opacity |
| Too opaque | Decrease opacity |
| Wrong position | Check layer order in children |

## 📱 Testing Checklist

- [ ] Depth layer loads at zoom 12+
- [ ] Toggle switch works
- [ ] Opacity slider responds
- [ ] Tiles load without errors
- [ ] Layer aligns with base map
- [ ] No performance lag
- [ ] Depth contours visible
- [ ] Buoys appear at zoom 13+

## 🔗 Navigation

**Documentation:**
- [QUICK_START_DEPTH_LAYER.md](QUICK_START_DEPTH_LAYER.md) - Get started fast
- [DEPTH_LAYER_GUIDE.md](DEPTH_LAYER_GUIDE.md) - Complete guide
- [DEPTH_INTEGRATION_SUMMARY.md](DEPTH_INTEGRATION_SUMMARY.md) - Integration details
- [MAP_ARCHITECTURE.md](MAP_ARCHITECTURE.md) - Architecture overview
- [MAP_SCREENS_COMPARISON.md](MAP_SCREENS_COMPARISON.md) - Compare map screens

**Code:**
- [integrated_map.dart](lib/screens/integrated_map.dart) - Production map
- [depth_layer.dart](lib/widgets/map/depth_layer.dart) - Depth widget
- [map_constants.dart](lib/utilities/map_constants.dart) - Configuration

## 💡 Pro Tips

1. **Combine layers** - Use depth + fishing spots together
2. **Adjust opacity** - 70-80% works best
3. **Zoom 13** - Optimal for navigation
4. **Red-Right-Returning** - Red buoys on right when entering harbor
5. **Depth in meters** - Multiply by 3.28 for feet
6. **Pre-zoom** - Depth data loads faster when pre-zoomed

## 📄 Attribution Required

Add to your app:
```
Map data © OpenStreetMap contributors, OpenSeaMap
```

## 🎉 You're Ready!

Your map now has professional nautical charts for safe marine navigation.

**For questions:** See [DEPTH_LAYER_GUIDE.md](DEPTH_LAYER_GUIDE.md)
**For integration:** See [DEPTH_INTEGRATION_SUMMARY.md](DEPTH_INTEGRATION_SUMMARY.md)
**For comparison:** See [MAP_SCREENS_COMPARISON.md](MAP_SCREENS_COMPARISON.md)

---

**Happy navigating! ⚓🌊🗺️**
