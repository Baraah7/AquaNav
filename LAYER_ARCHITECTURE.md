# Bahaar Map - Layer Architecture

## Visual Layer Stack

```
                          ┌─────────────────────────────────┐
                          │    USER LOCATION MARKER         │
                          │  (Blue=Water, Orange=Land)      │
                          └─────────────────────────────────┘
                                        ▲
                                        │ Always on top
                          ═══════════════════════════════════
                                        │
                          ┌─────────────────────────────────┐
        LAYER 3           │   NAVIGATION MASK OVERLAY       │
     (Optional)           │   - Coverage boundary (purple)  │
                          │   - Land/Water validation       │
                          └─────────────────────────────────┘
                                        ▲
                                        │
                          ═══════════════════════════════════
                                        │
                          ┌─────────────────────────────────┐
        LAYER 2c          │   GEOJSON - MARKERS             │
      (Top GeoJSON)       │   - Fishing spots (blue pins)   │
                          └─────────────────────────────────┘
                                        ▲
                          ┌─────────────────────────────────┐
        LAYER 2b          │   GEOJSON - POLYLINES           │
     (Middle GeoJSON)     │   - Shipping lanes (red)        │
                          │   - Patrol routes (orange)      │
                          └─────────────────────────────────┘
                                        ▲
                          ┌─────────────────────────────────┐
        LAYER 2a          │   GEOJSON - POLYGONS            │
    (Bottom GeoJSON)      │   - Protected zones (red fill)  │
                          │   - Fishing zones (green fill)  │
                          │   - Reefs (brown fill)          │
                          └─────────────────────────────────┘
                                        ▲
                                        │
                          ═══════════════════════════════════
                                        │
                          ┌─────────────────────────────────┐
        LAYER 1           │   BASE MAP TILES                │
      (Foundation)        │   - OpenStreetMap               │
                          │   - Streets, coastlines, labels │
                          └─────────────────────────────────┘
```

## Layer Responsibilities

### Layer 1: Base Map Tiles
- **Purpose**: Foundation cartography
- **Source**: OpenStreetMap
- **Technology**: TileLayer widget
- **URL**: `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Always Visible**: Yes (unless disabled)

### Layer 2: GeoJSON Overlays
Three sub-layers render maritime features:

#### 2a. Polygon Layer (Bottom)
```dart
PolygonLayer(polygons: _buildZonePolygons())
```
- **Features**: Protected zones, fishing zones, reefs
- **Rendering**: Semi-transparent fills with colored borders
- **Interaction**: Visual-only (no tap events on polygons)

#### 2b. Polyline Layer (Middle)
```dart
PolylineLayer(polylines: _buildShippingLanes())
```
- **Features**: Shipping lanes, patrol routes
- **Rendering**: Colored lines with varying widths
- **Interaction**: Visual-only

#### 2c. Marker Layer (Top)
```dart
MarkerLayer(markers: _buildFishingSpotMarkers())
```
- **Features**: Fishing spot locations
- **Rendering**: Icon-based markers
- **Interaction**: Tappable (future feature)

### Layer 3: Navigation Mask
- **Purpose**: Coastline awareness and validation
- **Technology**: Custom Polygon overlay + backend validation
- **Data**: 500x500 binary grid (245KB)
- **Coverage**: 50.35°-50.85°E, 25.85°-26.35°N
- **Visualization**: Optional purple boundary outline

### Top Layer: User Location
- **Purpose**: Show user's current position
- **Rendering**: Icon marker with color coding
- **Validation**: Real-time check against navigation mask
- **Always on Top**: Yes

## Data Flow

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ├─────────────────────────────────┐
         │                                 │
         ▼                                 ▼
┌─────────────────┐              ┌─────────────────┐
│ Load Navigation │              │  Load GeoJSON   │
│      Mask       │              │     Features    │
│                 │              │                 │
│ • Binary data   │              │ • Parse JSON    │
│ • Metadata      │              │ • Extract by    │
│ • Initialize    │              │   feature type  │
└────────┬────────┘              └────────┬────────┘
         │                                 │
         │        ┌─────────────────┐      │
         │        │ Get User Location│     │
         │        └────────┬────────┘      │
         │                 │               │
         └────────┬────────┴───────┬───────┘
                  │                │
                  ▼                ▼
         ┌───────────────────────────────┐
         │   Build Map Layers            │
         │                               │
         │  1. Base tiles                │
         │  2. GeoJSON layers (2a→2b→2c) │
         │  3. Mask overlay              │
         │  4. User marker               │
         └───────────────────────────────┘
                  │
                  ▼
         ┌───────────────────────────────┐
         │      Render Map               │
         │                               │
         │  FlutterMap widget displays   │
         │  all layers in correct order  │
         └───────────────────────────────┘
                  │
                  ▼
         ┌───────────────────────────────┐
         │   User Interaction            │
         │                               │
         │  • Tap → Validate location    │
         │  • Pan → Update view          │
         │  • Zoom → Re-render           │
         │  • Toggle → Show/hide layers  │
         └───────────────────────────────┘
```

## Interaction Flow

### Tap on Map
```
User Taps Map
     │
     ▼
Get Tap Coordinates (LatLng)
     │
     ▼
Is Navigation Mask Initialized? ─── No ──→ No action
     │
    Yes
     │
     ▼
Check if Navigable
(navigationMask.isPointNavigable)
     │
     ├─── Is Water ──→ Silent success
     │                 (valid location)
     │
     └─── Is Land ──→ Show SnackBar
                      "Location is on land"
                           │
                           ▼
                      User taps "Find Water"
                           │
                           ▼
                  Find Nearest Water Location
                      (breadth-first search)
                           │
                           ▼
                      Move Map to Water Location
```

### Layer Toggle
```
User Opens Layer Panel
     │
     ▼
User Toggles Layer Switch
     │
     ▼
Update State Variable
(_showFishingSpots = true/false)
     │
     ▼
Rebuild Map Widget
     │
     ▼
Layer Builder Method Checks Toggle
if (!_showFishingSpots) return [];
     │
     ├─── Disabled ──→ Return empty list
     │                 (layer not rendered)
     │
     └─── Enabled ──→ Build and return features
                      (layer rendered)
```

## Performance Optimization

### Rendering Strategy

1. **Conditional Layer Building**
   - Check visibility flags before processing
   - Return empty arrays for disabled layers
   - Avoid unnecessary computations

2. **Widget Tree Optimization**
   - Layer controls in separate widget
   - Minimize rebuild scope with setState
   - Use const constructors where possible

3. **Data Loading**
   - Load assets once in initState
   - Cache parsed GeoJSON in memory
   - Binary mask for O(1) lookups

### Memory Management

```
Component                Size        Lifecycle
─────────────────────────────────────────────────
Base map tiles          Streaming   Cached by flutter_map
GeoJSON data            ~500KB      Loaded once, kept in RAM
Navigation mask         245KB       Loaded once, kept in RAM
Map controller          <10KB       Widget lifecycle
Layer state             <1KB        Widget lifecycle
─────────────────────────────────────────────────
Total (approx)          ~750KB      Active during map view
```

## Code Organization

### File: integrated_map.dart

```dart
class IntegratedMap extends StatefulWidget {
  // Widget entry point
}

class _IntegratedMapState extends State<IntegratedMap> {

  // === State Variables ===
  MapController _mapController;
  NavigationMask _navigationMask;
  Map<String, dynamic>? _geoJsonData;
  bool _showXXX; // Layer toggles

  // === Initialization ===
  @override
  void initState() {
    _initLocation();
    _initNavigationMask();
    _loadGeoJson();
  }

  // === Data Loading ===
  Future<void> _initNavigationMask() { ... }
  Future<void> _loadGeoJson() { ... }

  // === Layer Builders ===
  List<Marker> _buildFishingSpotMarkers() { ... }
  List<Polyline> _buildShippingLanes() { ... }
  List<Polygon> _buildZonePolygons() { ... }
  List<Polygon> _buildMaskOverlay() { ... }

  // === UI Components ===
  Widget _buildLayerControls() { ... }

  // === Main Build ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack([
        FlutterMap(
          children: [
            // Layer stack in correct order
          ]
        ),
        // Overlay UI (controls, buttons)
      ])
    );
  }
}
```

## Integration Points

### Where Layers Connect

1. **Base Map ↔ GeoJSON**
   - GeoJSON coordinates align with map projection (EPSG:4326)
   - Same coordinate reference system

2. **GeoJSON ↔ Navigation Mask**
   - Mask validates GeoJSON feature locations
   - Both use WGS84 lat/lng coordinates

3. **Navigation Mask ↔ User Location**
   - Real-time validation of user position
   - Color-coded marker based on mask result

4. **All Layers ↔ Map Controller**
   - Single MapController manages view state
   - Zoom/pan affects all layers simultaneously

## Testing Each Layer

### Test Base Map
```dart
// Disable all other layers
_showGeoJsonLayers = false;
_showMaskOverlay = false;
// Should see only OSM tiles
```

### Test GeoJSON Layers
```dart
// Enable GeoJSON, disable mask
_showGeoJsonLayers = true;
_showMaskOverlay = false;
// Should see fishing spots, lanes, zones on map
```

### Test Navigation Mask
```dart
// Enable mask overlay
_showMaskOverlay = true;
// Should see purple boundary
// Tap on land → warning
// Tap on water → no warning
```

### Test Full Integration
```dart
// Enable all layers
_showGeoJsonLayers = true;
_showMaskOverlay = true;
// Verify layers don't conflict
// Verify correct rendering order
// Verify interactions work
```

---

**This architecture ensures**:
- ✅ Correct layer ordering (no z-fighting)
- ✅ Independent layer toggling
- ✅ Performance optimization
- ✅ Clean separation of concerns
- ✅ Easy maintenance and extension
