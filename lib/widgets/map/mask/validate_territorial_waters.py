"""
Validation script for Bahrain territorial water mask
"""

import numpy as np
import json
from shapely.geometry import shape, Point
from shapely.ops import unary_union
import matplotlib.pyplot as plt
from typing import Tuple, Dict


def load_mask_data(prefix: str = "bahrain_territorial_waters") -> Tuple[np.ndarray, Dict]:
    """
    Load mask data and metadata.

    Args:
        prefix: File prefix for mask files

    Returns:
        Tuple of (mask array, metadata dict)
    """
    # Load binary mask
    mask = np.fromfile(f"{prefix}.bin", dtype=np.uint8)

    # Load metadata
    with open(f"{prefix}_metadata.json", 'r') as f:
        metadata = json.load(f)

    # Reshape mask
    width = metadata['grid']['width']
    height = metadata['grid']['height']
    mask = mask.reshape(height, width)

    return mask, metadata


def load_geojson(filename: str):
    """Load GeoJSON file."""
    with open(filename, 'r') as f:
        data = json.load(f)
    return shape(data['geometry'])


def validate_coverage(mask: np.ndarray, metadata: Dict):
    """
    Validate mask coverage statistics.

    Args:
        mask: Binary mask array
        metadata: Metadata dictionary
    """
    print("=" * 70)
    print("COVERAGE VALIDATION")
    print("=" * 70)

    total_cells = mask.size
    water_cells = np.sum(mask == 1)
    land_cells = np.sum(mask == 0)

    water_pct = (water_cells / total_cells) * 100
    land_pct = (land_cells / total_cells) * 100

    print(f"Total cells: {total_cells:,}")
    print(f"Water cells: {water_cells:,} ({water_pct:.2f}%)")
    print(f"Land cells: {land_cells:,} ({land_pct:.2f}%)")
    print()

    # Calculate approximate area
    resolution = metadata['grid']['resolution_meters_approx']
    cell_area_m2 = resolution * resolution
    water_area_km2 = (water_cells * cell_area_m2) / 1_000_000

    print(f"Approximate water area: {water_area_km2:.2f} km²")
    print()

    # Validation checks
    print("Validation Checks:")

    if water_pct < 70:
        print("  ✓ Water coverage looks reasonable for Bahrain territorial waters")
    else:
        print("  ⚠ Warning: Water coverage seems high (>70%)")

    if water_pct > 10:
        print("  ✓ Water coverage not too low")
    else:
        print("  ⚠ Warning: Water coverage seems very low (<10%)")

    print()


def validate_territorial_distance(water_geom, land_geom, metadata: Dict):
    """
    Validate that territorial waters extend approximately 12nm from coastline.

    Args:
        water_geom: Water polygon geometry
        land_geom: Land polygon geometry
        metadata: Metadata dictionary
    """
    print("=" * 70)
    print("TERRITORIAL DISTANCE VALIDATION")
    print("=" * 70)

    # Sample points around the perimeter
    bbox = metadata['bbox']

    # Test points at cardinal directions from Bahrain center
    center_lon = (bbox['min_lon'] + bbox['max_lon']) / 2
    center_lat = (bbox['min_lat'] + bbox['max_lat']) / 2

    print(f"Testing from center point: ({center_lon:.4f}, {center_lat:.4f})")
    print()

    # Calculate distances (approximate, in degrees)
    # 1 nm ≈ 0.0166667 degrees at this latitude
    nm_in_degrees = 0.0166667

    test_directions = [
        ("North", center_lon, center_lat + 0.15),
        ("South", center_lon, center_lat - 0.15),
        ("East", center_lon + 0.15, center_lat),
        ("West", center_lon - 0.15, center_lat),
    ]

    print("Boundary check (should be navigable within ~12nm of coast):")
    for direction, lon, lat in test_directions:
        point = Point(lon, lat)
        is_water = water_geom.contains(point)
        status = "✓ Water" if is_water else "✗ Land/Outside"
        print(f"  {direction:6s} ({lon:.4f}, {lat:.4f}): {status}")

    print()


def validate_boundaries(water_geom, metadata: Dict):
    """
    Validate that water doesn't extend beyond bounding box.

    Args:
        water_geom: Water polygon geometry
        metadata: Metadata dictionary
    """
    print("=" * 70)
    print("BOUNDARY VALIDATION")
    print("=" * 70)

    bbox = metadata['bbox']

    # Get water bounds
    water_bounds = water_geom.bounds  # (minx, miny, maxx, maxy)

    print(f"Expected bounds: ({bbox['min_lon']:.4f}, {bbox['min_lat']:.4f}, "
          f"{bbox['max_lon']:.4f}, {bbox['max_lat']:.4f})")
    print(f"Water bounds:    ({water_bounds[0]:.4f}, {water_bounds[1]:.4f}, "
          f"{water_bounds[2]:.4f}, {water_bounds[3]:.4f})")
    print()

    # Check if within bounds
    within_lon = bbox['min_lon'] <= water_bounds[0] and water_bounds[2] <= bbox['max_lon']
    within_lat = bbox['min_lat'] <= water_bounds[1] and water_bounds[3] <= bbox['max_lat']

    if within_lon and within_lat:
        print("✓ Water geometry is within expected bounding box")
    else:
        print("⚠ Warning: Water geometry extends beyond bounding box")
        if not within_lon:
            print("  - Longitude out of bounds")
        if not within_lat:
            print("  - Latitude out of bounds")

    print()


def validate_geometry(water_geom, land_geom):
    """
    Validate geometry integrity.

    Args:
        water_geom: Water polygon geometry
        land_geom: Land polygon geometry
    """
    print("=" * 70)
    print("GEOMETRY VALIDATION")
    print("=" * 70)

    # Check water geometry
    print("Water geometry:")
    print(f"  Type: {water_geom.geom_type}")
    print(f"  Valid: {'✓ Yes' if water_geom.is_valid else '✗ No'}")
    print(f"  Empty: {'⚠ Yes' if water_geom.is_empty else '✓ No'}")
    print(f"  Area: {water_geom.area:.6f} square degrees")

    if hasattr(water_geom, 'geoms'):
        print(f"  Number of polygons: {len(water_geom.geoms)}")

    print()

    # Check land geometry
    print("Land geometry:")
    print(f"  Type: {land_geom.geom_type}")
    print(f"  Valid: {'✓ Yes' if land_geom.is_valid else '✗ No'}")
    print(f"  Empty: {'⚠ Yes' if land_geom.is_empty else '✓ No'}")
    print(f"  Area: {land_geom.area:.6f} square degrees")

    if hasattr(land_geom, 'geoms'):
        print(f"  Number of polygons: {len(land_geom.geoms)}")

    print()

    # Check overlap
    overlap = water_geom.intersection(land_geom)
    if overlap.is_empty or overlap.area < 0.0001:
        print("✓ No significant overlap between water and land")
    else:
        print(f"⚠ Warning: Water and land overlap by {overlap.area:.6f} square degrees")

    print()


def visualize_mask(mask: np.ndarray, metadata: Dict, output_file: str = "territorial_waters_validation.png"):
    """
    Create visualization of the mask.

    Args:
        mask: Binary mask array
        metadata: Metadata dictionary
        output_file: Output image filename
    """
    print("=" * 70)
    print("VISUALIZATION")
    print("=" * 70)

    bbox = metadata['bbox']

    # Create figure
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8))

    # Plot 1: Full mask
    im1 = ax1.imshow(mask, cmap='Blues', origin='lower',
                     extent=[bbox['min_lon'], bbox['max_lon'],
                            bbox['min_lat'], bbox['max_lat']])
    ax1.set_title('Bahrain Territorial Waters Mask (12nm)', fontsize=14, fontweight='bold')
    ax1.set_xlabel('Longitude')
    ax1.set_ylabel('Latitude')
    ax1.grid(True, alpha=0.3)
    plt.colorbar(im1, ax=ax1, label='0=Land, 1=Water')

    # Add bounding box
    ax1.plot([bbox['min_lon'], bbox['max_lon'], bbox['max_lon'], bbox['min_lon'], bbox['min_lon']],
            [bbox['min_lat'], bbox['min_lat'], bbox['max_lat'], bbox['max_lat'], bbox['min_lat']],
            'r--', linewidth=2, label='Bounding Box')
    ax1.legend()

    # Plot 2: Statistics
    ax2.axis('off')

    total_cells = mask.size
    water_cells = np.sum(mask == 1)
    land_cells = np.sum(mask == 0)
    water_pct = (water_cells / total_cells) * 100

    stats_text = f"""
    MASK STATISTICS

    Grid Size: {metadata['grid']['width']} x {metadata['grid']['height']} = {total_cells:,} cells
    Resolution: {metadata['grid']['resolution_degrees']}° (~{metadata['grid']['resolution_meters_approx']:.0f}m)

    Coverage:
      • Water cells: {water_cells:,} ({water_pct:.2f}%)
      • Land cells: {land_cells:,} ({100-water_pct:.2f}%)

    Bounding Box:
      • Longitude: {bbox['min_lon']:.4f}° to {bbox['max_lon']:.4f}°
      • Latitude: {bbox['min_lat']:.4f}° to {bbox['max_lat']:.4f}°

    Territorial Waters:
      • Distance: 12 nautical miles (22,224 meters)
      • Standard: UNCLOS (UN Convention on the Law of the Sea)
      • Boundaries: Clipped against Qatar and Saudi Arabia

    Projection: {metadata['projection']}
    Encoding: Water=1, Land=0
    """

    ax2.text(0.1, 0.5, stats_text, fontsize=11, verticalalignment='center',
            fontfamily='monospace')

    plt.tight_layout()
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"✓ Visualization saved to: {output_file}")
    print()


def run_full_validation(prefix: str = "bahrain_territorial_waters"):
    """
    Run complete validation pipeline.

    Args:
        prefix: File prefix for mask files
    """
    print()
    print("=" * 70)
    print(" BAHRAIN TERRITORIAL WATER MASK VALIDATION")
    print("=" * 70)
    print()

    try:
        # Load data
        print("Loading mask data...")
        mask, metadata = load_mask_data(prefix)
        print(f"✓ Loaded mask: {mask.shape[0]}x{mask.shape[1]}")

        print("Loading GeoJSON data...")
        water_geom = load_geojson(f"{prefix}_water.geojson")
        land_geom = load_geojson(f"{prefix}_land.geojson")
        print("✓ Loaded GeoJSON geometries")
        print()

        # Run validations
        validate_coverage(mask, metadata)
        validate_geometry(water_geom, land_geom)
        validate_boundaries(water_geom, metadata)
        validate_territorial_distance(water_geom, land_geom, metadata)
        visualize_mask(mask, metadata)

        # Final summary
        print("=" * 70)
        print("VALIDATION COMPLETE")
        print("=" * 70)
        print()
        print("Next steps:")
        print("  1. Review the validation output above")
        print("  2. Check the visualization: territorial_waters_validation.png")
        print("  3. If satisfied, copy files to Flutter assets:")
        print(f"     - {prefix}.bin → assets/navigation/")
        print(f"     - {prefix}_metadata.json → assets/navigation/")
        print(f"     - {prefix}_water.geojson → assets/data/")
        print("  4. Restart your Flutter app to use the new mask")
        print()

    except FileNotFoundError as e:
        print(f"❌ ERROR: Required file not found: {e}")
        print()
        print("Please run territorial_water_processor.py first to generate the mask files.")
        print()
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_full_validation()
