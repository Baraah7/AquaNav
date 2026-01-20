# Quick Start Guide: Fixing Bahrain's Territorial Water Mask

This guide will help you generate and integrate the correct 12 nautical mile territorial water mask for Bahrain.

## What's Wrong with the Current Mask?

Your current mask ([bahrain_navigation_mask.bin](bahrain_navigation_mask.bin)) only extracts the coastline from OpenStreetMap but **does not**:

1. ❌ Extend 12 nautical miles (22.2 km) from the coastline
2. ❌ Respect maritime boundaries with Qatar and Saudi Arabia
3. ❌ Use geodesic (great circle) distance calculations

The new mask will fix all of these issues.

---

## Step 1: Install Dependencies

Open a terminal in this directory (`lib/widgets/map/mask/`) and run:

```bash
pip install -r requirements.txt
```

This will install:
- `shapely` - Geometry operations
- `rasterio` - Raster processing
- `geopandas` - Geospatial data handling
- `pyproj` - Geodesic calculations (critical!)
- `numpy` - Array operations
- `requests` - OpenStreetMap API

---

## Step 2: Generate the New Mask

Run the territorial water processor:

```bash
python territorial_water_processor.py
```

### What This Does:

1. **Fetches Bahrain's coastline** from OpenStreetMap (includes all islands)
2. **Creates a 12nm geodesic buffer** around the coastline using WGS84 ellipsoid
3. **Clips against maritime boundaries** with Qatar (east) and Saudi Arabia (west)
4. **Rasterizes to a 500x500 grid** at ~111m resolution
5. **Saves 6 output files**:
   - `bahrain_territorial_waters.bin` - Binary mask for Flutter
   - `bahrain_territorial_waters.npz` - Compressed NumPy format
   - `bahrain_territorial_waters.tif` - GeoTIFF for QGIS
   - `bahrain_territorial_waters_water.geojson` - Water polygon
   - `bahrain_territorial_waters_land.geojson` - Land polygon
   - `bahrain_territorial_waters_metadata.json` - Grid metadata

### Expected Output:

```
======================================================================
🌊 BAHRAIN TERRITORIAL WATER MASK GENERATOR
======================================================================
Bounding Box: (50.3, 25.8, 50.9, 26.4)
Resolution: 0.001° (~111m)
Territorial Waters: 12 nautical miles
======================================================================

🚀 Starting pipeline...

STEP 1: Extract Bahrain Coastline
----------------------------------------------------------------------
🌊 Fetching Bahrain coastline data for bbox: (50.3, 25.8, 50.9, 26.4)
✓ Retrieved XXX elements from OSM
✓ Created XX coastline segments
🔧 Validating and closing polygons...
✓ Validated XX polygons
✓ Land mask created with X polygon(s)

STEP 2: Generate 12nm Territorial Waters
----------------------------------------------------------------------
🌊 Generating 12 nautical mile territorial waters...
📏 Creating geodesic buffer: 12.0 nautical miles (22224 meters)
✓ Geodesic buffer created
✓ Territorial waters area: X.XXXXXX square degrees

STEP 3: Clip Against International Boundaries
----------------------------------------------------------------------
🌍 Clipping territorial waters against international boundaries...
🇶🇦 Creating Qatar maritime boundary...
✓ Qatar boundary created with 3 points
🇸🇦 Creating Saudi Arabia maritime boundary...
✓ Saudi boundary created with 3 points
✂️  Creating boundary clip polygon...
✓ Clip polygon created with XX vertices
✓ Clipped territorial waters area: X.XXXXXX square degrees

STEP 4: Rasterize and Save Mask
----------------------------------------------------------------------
📐 Grid dimensions: 500x500 (250,000 cells)
🎨 Rasterizing water mask...
✓ Rasterization complete: XX.XX% navigable water
💾 Saving mask files with prefix: bahrain_territorial_waters
✓ Saved bahrain_territorial_waters.bin
✓ Saved bahrain_territorial_waters.npz
✓ Saved bahrain_territorial_waters.tif
✓ Saved bahrain_territorial_waters_water.geojson
✓ Saved bahrain_territorial_waters_land.geojson
✓ Saved bahrain_territorial_waters_metadata.json
✓ All mask files saved successfully!

======================================================================
✅ PIPELINE COMPLETE!
======================================================================
```

---

## Step 3: Validate the Mask

Run the validation script to verify the mask is correct:

```bash
python validate_territorial_waters.py
```

This will:
1. Load and analyze the mask data
2. Check coverage statistics
3. Validate geometry integrity
4. Verify boundaries
5. Generate a visualization (`territorial_waters_validation.png`)

### What to Look For:

✅ **Good signs:**
- Water coverage: 40-70% (reasonable for Bahrain + 12nm waters)
- No overlap between water and land
- Water bounds within bounding box
- Valid geometry (no errors)

⚠️ **Warning signs:**
- Water coverage >80% (boundaries too wide)
- Water coverage <20% (boundaries too narrow)
- Geometry validation errors
- Water extends beyond bounding box

---

## Step 4: Visual Verification (Optional but Recommended)

### Using QGIS:

1. **Install QGIS** (free): https://qgis.org/download/
2. **Open QGIS** and create a new project
3. **Add layers**:
   - Layer → Add Layer → Add Raster Layer → Select `bahrain_territorial_waters.tif`
   - Layer → Add Layer → Add Vector Layer → Select `bahrain_territorial_waters_water.geojson`
   - Layer → Add Layer → Add Vector Layer → Select `bahrain_territorial_waters_land.geojson`
4. **Add a base map** (optional):
   - Browser panel → XYZ Tiles → OpenStreetMap
   - Drag to layers panel
5. **Verify**:
   - ✅ 12nm distance from coastline (use measuring tool)
   - ✅ No overlap with Qatar waters (eastern boundary)
   - ✅ No overlap with Saudi waters (western boundary)
   - ✅ All islands included (Muharraq, Hawar, etc.)

### Measuring 12nm in QGIS:

1. View → Toolbars → Enable "Attributes Toolbar"
2. Click the **Measure Line** tool
3. Draw a line from the coast to the territorial water boundary
4. Verify distance ≈ 22.2 km (12 nautical miles)

---

## Step 5: Backup Old Mask

Before replacing, backup your current mask:

```bash
# In the lib/widgets/map/mask/ directory
copy bahrain_navigation_mask.bin bahrain_navigation_mask.bin.backup
copy bahrain_navigation_mask_metadata.json bahrain_navigation_mask_metadata.json.backup
copy bahrain_navigation_mask_water.geojson bahrain_navigation_mask_water.geojson.backup
```

Or on macOS/Linux:
```bash
cp bahrain_navigation_mask.bin bahrain_navigation_mask.bin.backup
cp bahrain_navigation_mask_metadata.json bahrain_navigation_mask_metadata.json.backup
cp bahrain_navigation_mask_water.geojson bahrain_navigation_mask_water.geojson.backup
```

---

## Step 6: Replace the Mask Files

### Option A: Rename and Replace (Recommended)

This keeps your existing Flutter code unchanged:

```bash
# Rename the new files to match the old names
move bahrain_territorial_waters.bin bahrain_navigation_mask.bin
move bahrain_territorial_waters_metadata.json bahrain_navigation_mask_metadata.json
move bahrain_territorial_waters_water.geojson bahrain_navigation_mask_water.geojson
move bahrain_territorial_waters_land.geojson bahrain_navigation_mask_land.geojson

# Optional: keep the .tif and .npz for QGIS use
```

Or on macOS/Linux:
```bash
mv bahrain_territorial_waters.bin bahrain_navigation_mask.bin
mv bahrain_territorial_waters_metadata.json bahrain_navigation_mask_metadata.json
mv bahrain_territorial_waters_water.geojson bahrain_navigation_mask_water.geojson
mv bahrain_territorial_waters_land.geojson bahrain_navigation_mask_land.geojson
```

### Option B: Copy to Assets

If you want to keep both versions:

```bash
# Copy to Flutter assets (adjust path if needed)
copy bahrain_territorial_waters.bin ..\..\..\assets\navigation\bahrain_territorial_waters.bin
copy bahrain_territorial_waters_metadata.json ..\..\..\assets\navigation\bahrain_territorial_waters_metadata.json
copy bahrain_territorial_waters_water.geojson ..\..\..\assets\data\bahrain_territorial_waters_water.geojson
```

Then update the Flutter code to load `bahrain_territorial_waters.bin` instead of `bahrain_navigation_mask.bin`.

---

## Step 7: Test in Flutter

### 7.1 Hot Restart

In your IDE or terminal:
```bash
# Hot restart (R key in terminal, or button in IDE)
# This reloads assets
```

### 7.2 Verify Navigation Mask Service

The mask should automatically load in [NavigationMask](../../services/navigation_mask.dart):

```dart
// This already exists in your code
class NavigationMask {
  Future<void> loadMask() async {
    final byteData = await rootBundle.load('assets/navigation/bahrain_navigation_mask.bin');
    // ...
  }
}
```

### 7.3 Test Points

Test these locations to verify the mask:

#### Should be WATER (navigable):
1. **Off Bahrain coast** (50.60, 26.25) - Within territorial waters
2. **Between islands** (50.55, 26.20) - Inter-island waters
3. **South of Muharraq** (50.65, 26.22) - Territorial waters

#### Should be LAND (non-navigable):
1. **Manama** (50.586, 26.228) - Capital city
2. **Muharraq Island** (50.618, 26.257) - Airport area
3. **Hawar Islands** (50.77, 25.65) - Southern islands

#### Test in Code:

You can use the existing demo screen:

```dart
// lib/examples/navigation_mask_demo.dart already exists
// Run it to test interactively
```

Or test programmatically:

```dart
final mask = NavigationMask();
await mask.loadMask();

// Test water point
final isWater = mask.isNavigable(50.60, 26.25);
print('Point is navigable: $isWater'); // Should be true

// Test land point
final isLand = mask.isNavigable(50.586, 26.228);
print('Point is navigable: $isLand'); // Should be false
```

### 7.4 Check Depth Layer Masking

The depth layer should now properly mask to territorial waters:

1. Open the map in your app
2. Enable depth layer
3. Zoom out to see the full extent
4. Verify:
   - ✅ Depth colors show within 12nm of coast
   - ✅ Depth colors DO NOT show beyond territorial boundary
   - ✅ No depth colors over land
   - ✅ Depth colors stop at Qatar/Saudi boundaries

---

## Troubleshooting

### Problem: "No coastline data found"

**Cause:** OpenStreetMap API timeout or network issue

**Solution:**
```python
# Edit territorial_water_processor.py
# Increase timeout on line 33:
osm_data = self.fetch_coastline_osm(timeout=600)  # Increase from 300 to 600
```

### Problem: Mask looks wrong in QGIS

**Cause:** Incorrect bounding box or resolution

**Solution:**
```python
# Edit territorial_water_processor.py
# Adjust bounding box (lines 491-496):
BAHRAIN_BBOX = (
    50.25,   # Expand westward if needed
    25.75,   # Expand southward if needed
    50.95,   # Expand eastward if needed
    26.45    # Expand northward if needed
)
```

### Problem: Boundaries extend into Qatar or Saudi Arabia

**Cause:** Maritime boundary coordinates are approximate

**Solution:**
1. Find official maritime boundary data (GeoJSON or shapefile)
2. Edit `create_qatar_boundary()` and `create_saudi_boundary()` in [territorial_water_processor.py](territorial_water_processor.py)
3. Replace the coordinate lists with official data

### Problem: Flutter can't load the new mask

**Cause:** File path or format mismatch

**Solution:**
1. Verify file exists: `ls assets/navigation/bahrain_navigation_mask.bin`
2. Check file size: Should be 250,000 bytes (500x500 grid)
3. Verify metadata matches mask dimensions
4. Clear Flutter cache and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Problem: Validation script fails

**Cause:** Missing dependencies or files

**Solution:**
```bash
# Reinstall dependencies
pip install --upgrade -r requirements.txt

# Verify files exist
ls bahrain_territorial_waters*

# Run validation with verbose output
python validate_territorial_waters.py
```

---

## Important Notes

### ⚠️ Maritime Boundary Accuracy

The current implementation uses **simplified maritime boundaries** with Qatar and Saudi Arabia. For production use:

1. Obtain official maritime boundary coordinates from:
   - Bahrain Ministry of Foreign Affairs
   - UN Division for Ocean Affairs and the Law of the Sea (DOALOS)
   - International Hydrographic Organization (IHO)

2. Update the boundary coordinates in [territorial_water_processor.py](territorial_water_processor.py):
   - `create_qatar_boundary()` - Lines 371-388
   - `create_saudi_boundary()` - Lines 390-407

### 📐 Resolution Trade-offs

Current resolution: **0.001° (~111 meters)**

- **Higher resolution** (0.0005° = ~55m):
  - ✅ More accurate coastline
  - ✅ Better for small harbors
  - ❌ Larger file sizes (4x bigger)
  - ❌ Slower processing

- **Lower resolution** (0.002° = ~222m):
  - ✅ Smaller file sizes
  - ✅ Faster processing
  - ❌ Less accurate coastline
  - ❌ May miss small features

To change resolution, edit line 502 in [territorial_water_processor.py](territorial_water_processor.py):
```python
resolution=0.001  # Change to 0.0005 or 0.002
```

### 🌊 Territorial Water Distance

Current: **12 nautical miles** (territorial waters)

You can also generate:
- **24 nautical miles** (contiguous zone)
- **200 nautical miles** (Exclusive Economic Zone / EEZ)

To change, edit line 503:
```python
territorial_distance_nm=12  # Change to 24 or 200
```

⚠️ **Note:** For larger distances, you'll need to expand the bounding box accordingly.

---

## Next Steps

After successfully integrating the mask:

1. ✅ Verify route validation works correctly
2. ✅ Test depth layer masking in the app
3. ✅ Validate marina locations are within territorial waters
4. ✅ Update any hardcoded coordinates or boundaries
5. 📝 Consider adding:
   - Contiguous zone (24nm) layer
   - EEZ boundary (200nm) layer
   - Restricted/prohibited zones
   - Military areas
   - Protected marine areas

---

## Support

If you encounter issues:

1. Check the [README_TERRITORIAL_WATERS.md](README_TERRITORIAL_WATERS.md) for detailed documentation
2. Review the validation output from `validate_territorial_waters.py`
3. Examine the visualization: `territorial_waters_validation.png`
4. Use QGIS to visually inspect the `.tif` and `.geojson` files

---

## Summary

You've now:

✅ Generated a proper 12nm territorial water mask for Bahrain
✅ Included geodesic distance calculations
✅ Clipped against Qatar and Saudi maritime boundaries
✅ Created multiple output formats (binary, GeoJSON, GeoTIFF)
✅ Validated the mask for accuracy
✅ Integrated it into your Flutter app

Your navigation system now correctly respects Bahrain's territorial waters!

🎉 **Done!**
