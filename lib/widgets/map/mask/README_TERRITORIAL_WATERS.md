# Bahrain Territorial Water Mask Generator

This tool generates accurate 12 nautical mile territorial water boundaries for Bahrain according to UNCLOS (United Nations Convention on the Law of the Sea).

## Features

- **Geodesic Buffering**: Uses proper great circle distances on the WGS84 ellipsoid for accurate 12nm boundaries
- **Coastline Extraction**: Fetches Bahrain's coastline from OpenStreetMap
- **Maritime Boundaries**: Clips territorial waters against Qatar and Saudi Arabia boundaries
- **Multiple Output Formats**: Generates binary mask, GeoJSON, GeoTIFF, and metadata files
- **Production Ready**: Optimized for Flutter map integration with proper masking

## Installation

### 1. Install Python Dependencies

```bash
cd lib/widgets/map/mask
pip install -r requirements.txt
```

Or install individually:

```bash
pip install requests numpy shapely rasterio geopandas pyproj
```

### 2. Verify Installation

```bash
python -c "import shapely, rasterio, geopandas, pyproj; print('All dependencies installed!')"
```

## Usage

### Quick Start

```bash
python territorial_water_processor.py
```

This will:
1. Fetch Bahrain's coastline from OpenStreetMap
2. Generate a geodesic 12nm buffer around the coastline
3. Clip against Qatar and Saudi Arabia maritime boundaries
4. Rasterize to a 500x500 grid at ~111m resolution
5. Save all output files with the prefix `bahrain_territorial_waters`

### Output Files

The script generates 6 files:

| File | Format | Description |
|------|--------|-------------|
| `bahrain_territorial_waters.bin` | Binary | Raw binary mask (1=water, 0=land) for Flutter |
| `bahrain_territorial_waters.npz` | NumPy | Compressed numpy array with metadata |
| `bahrain_territorial_waters.tif` | GeoTIFF | Raster mask for GIS tools (QGIS, ArcGIS) |
| `bahrain_territorial_waters_water.geojson` | GeoJSON | Vector polygon of territorial waters |
| `bahrain_territorial_waters_land.geojson` | GeoJSON | Vector polygon of land areas |
| `bahrain_territorial_waters_metadata.json` | JSON | Grid parameters and projection info |

### Advanced Usage

#### Custom Bounding Box

```python
from territorial_water_processor import TerritorialWaterPipeline

# Extend the bounding box if needed
custom_bbox = (
    50.25,   # min_longitude
    25.75,   # min_latitude
    50.95,   # max_longitude
    26.45    # max_latitude
)

pipeline = TerritorialWaterPipeline(
    bbox=custom_bbox,
    resolution=0.001,
    territorial_distance_nm=12
)

pipeline.run_pipeline(output_prefix="custom_output")
```

#### Higher Resolution

```python
# For higher accuracy (smaller grid cells)
pipeline = TerritorialWaterPipeline(
    bbox=BAHRAIN_BBOX,
    resolution=0.0005,  # ~55 meters per cell
    territorial_distance_nm=12
)
```

#### Different Territorial Distance

```python
# For contiguous zone (24nm) or EEZ (200nm)
pipeline = TerritorialWaterPipeline(
    bbox=BAHRAIN_BBOX,
    resolution=0.001,
    territorial_distance_nm=24  # or 200
)
```

## Configuration

### Bounding Box

The default bounding box is:

```python
BAHRAIN_BBOX = (
    50.30,   # min_longitude (west)
    25.80,   # min_latitude (south)
    50.90,   # max_longitude (east)
    26.40    # max_latitude (north)
)
```

This covers:
- Main Bahrain Island
- Muharraq Island
- Hawar Islands
- All surrounding waters within 12nm
- Causeway to Saudi Arabia

### Maritime Boundaries

The script includes simplified maritime boundaries:

#### Qatar Boundary (Eastern)
Based on the 2001 ICJ ruling between Bahrain and Qatar.

**⚠️ IMPORTANT**: The current implementation uses simplified coordinates. For production use, replace with official boundary coordinates from:
- [UNGEGN (United Nations Group of Experts on Geographical Names)](https://unstats.un.org/unsd/ungegn/)
- [IHO (International Hydrographic Organization)](https://iho.int/)
- Official Bahrain government maritime boundary data

#### Saudi Arabia Boundary (Western)
Simplified median line between Bahrain and Saudi Arabia.

**⚠️ IMPORTANT**: Replace with official King Fahd Causeway maritime boundary coordinates.

### To Update Boundaries

Edit [territorial_water_processor.py](territorial_water_processor.py):

```python
def create_qatar_boundary(self) -> LineString:
    # Replace these coordinates with official boundary data
    boundary_coords = [
        (50.85, 25.85),
        (50.85, 26.10),
        (50.85, 26.35),
    ]
    return LineString(boundary_coords)
```

## Integration with Flutter

### 1. Copy Generated Files

After running the script, copy the generated files to your Flutter assets:

```bash
# From lib/widgets/map/mask/ run:
cp bahrain_territorial_waters.bin ../../../assets/navigation/
cp bahrain_territorial_waters_metadata.json ../../../assets/navigation/
cp bahrain_territorial_waters_water.geojson ../../../assets/data/
```

### 2. Update Asset References

Your existing Flutter code already uses these files:
- [NavigationMask](../../services/navigation_mask.dart) loads the `.bin` file
- [EnhancedDepthLayer](../enhanced_depth_layer.dart) uses the mask for tile clipping
- [IntegratedMap](../../screens/integrated_map.dart) initializes the mask

### 3. Verify in App

The mask is automatically used for:
- Route validation (blocking land crossings)
- Depth layer masking (showing bathymetry only over water)
- Marina location validation
- Navigation waypoint checking

## Validation

### Visual Validation with QGIS

1. Open QGIS
2. Load the generated files:
   - `bahrain_territorial_waters.tif` (raster layer)
   - `bahrain_territorial_waters_water.geojson` (vector layer)
   - `bahrain_territorial_waters_land.geojson` (vector layer)
3. Verify:
   - 12nm distance from coastline
   - No overlap with Qatar territorial waters
   - No overlap with Saudi Arabia territorial waters
   - All islands properly included

### Programmatic Validation

```python
from territorial_water_processor import TerritorialWaterPipeline
import numpy as np

# Run pipeline
pipeline = TerritorialWaterPipeline(bbox=BAHRAIN_BBOX)
pipeline.run_pipeline()

# Load and check mask
mask = np.fromfile('bahrain_territorial_waters.bin', dtype=np.uint8)
mask = mask.reshape(500, 500)

# Statistics
water_cells = np.sum(mask == 1)
land_cells = np.sum(mask == 0)
total_cells = mask.size

print(f"Water cells: {water_cells} ({water_cells/total_cells*100:.1f}%)")
print(f"Land cells: {land_cells} ({land_cells/total_cells*100:.1f}%)")
```

## Troubleshooting

### Issue: "No coastline data found"

**Cause**: OpenStreetMap API timeout or network issue

**Solution**:
```python
extractor = BahrainCoastlineExtractor(bbox)
osm_data = extractor.fetch_coastline_osm(timeout=600)  # Increase timeout
```

### Issue: "Invalid polygon geometry"

**Cause**: OSM coastline has gaps or self-intersections

**Solution**: The script automatically attempts to fix invalid geometries using `make_valid()`. If issues persist, manually download OSM data and fix in QGIS before importing.

### Issue: Territorial waters extend into neighboring countries

**Cause**: Maritime boundary coordinates are incorrect

**Solution**: Update the boundary coordinates in `create_qatar_boundary()` and `create_saudi_boundary()` with official data.

### Issue: Grid resolution too low

**Cause**: Default resolution is 0.001° (~111m)

**Solution**: Increase resolution (decrease the number):
```python
pipeline = TerritorialWaterPipeline(
    bbox=BAHRAIN_BBOX,
    resolution=0.0005  # ~55m per cell
)
```

⚠️ **Warning**: Higher resolution = larger file sizes and slower processing

## Technical Details

### Geodesic Buffering

The script uses `pyproj.Geod` for accurate distance calculations on the WGS84 ellipsoid:

```python
geod = Geod(ellps='WGS84')
offset_lon, offset_lat, _ = geod.fwd(lon, lat, azimuth, distance_meters)
```

This ensures:
- Accurate 12nm = 22,224 meters
- Proper great circle distances
- Correct for Earth's curvature

### Coordinate Reference System

All data uses **EPSG:4326 (WGS84)**:
- Longitude/Latitude in decimal degrees
- Standard for GPS and web maps
- Compatible with Flutter MapLibre and Mapbox

### Grid Indexing

The binary mask uses row-major order:

```
mask[row, col] where:
- row = (lat - min_lat) / resolution
- col = (lon - min_lon) / resolution
```

## References

- [UNCLOS (United Nations Convention on the Law of the Sea)](https://www.un.org/depts/los/convention_agreements/texts/unclos/unclos_e.pdf)
- [ICJ Bahrain-Qatar Case (2001)](https://www.icj-cij.org/case/87)
- [OpenStreetMap Coastline](https://osmdata.openstreetmap.de/data/coastlines.html)
- [Pyproj Documentation](https://pyproj4.github.io/pyproj/stable/)
- [Shapely Documentation](https://shapely.readthedocs.io/)

## License

This tool is part of the Bahaar maritime navigation application.

## Support

For issues or questions, please refer to the main project documentation.
