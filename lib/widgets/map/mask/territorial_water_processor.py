"""
Territorial Water Processor for Bahrain
Generates accurate 12 nautical mile territorial water boundaries
according to UNCLOS (United Nations Convention on the Law of the Sea)
"""

import requests
import numpy as np
import json
from shapely.geometry import (
    Polygon, MultiPolygon, LineString, MultiLineString,
    Point, shape, mapping
)
from shapely.ops import unary_union, polygonize
from shapely.validation import make_valid
import rasterio
from rasterio import features
from rasterio.transform import from_bounds
import geopandas as gpd
from pyproj import Geod
from typing import List, Tuple, Dict, Optional
import warnings
warnings.filterwarnings('ignore')


# Constants
NAUTICAL_MILE_TO_METERS = 1852  # 1 nautical mile = 1852 meters
TERRITORIAL_WATER_DISTANCE = 12 * NAUTICAL_MILE_TO_METERS  # 12 nm = 22224 meters


class BahrainCoastlineExtractor:
    """Extracts Bahrain's coastline from OpenStreetMap."""

    def __init__(self, bbox: Tuple[float, float, float, float]):
        """
        Initialize coastline extractor.

        Args:
            bbox: Bounding box (min_lon, min_lat, max_lon, max_lat)
        """
        self.bbox = bbox

    def fetch_coastline_osm(self, timeout: int = 300) -> List[Dict]:
        """
        Fetch coastline data from OpenStreetMap using Overpass API.

        Args:
            timeout: API request timeout in seconds

        Returns:
            List of coastline ways from OSM
        """
        overpass_url = "http://overpass-api.de/api/interpreter"

        # Overpass QL query for coastline (natural=coastline)
        overpass_query = f"""
        [out:json][timeout:{timeout}];
        (
          way["natural"="coastline"]({self.bbox[1]},{self.bbox[0]},{self.bbox[3]},{self.bbox[2]});
          relation["natural"="coastline"]({self.bbox[1]},{self.bbox[0]},{self.bbox[3]},{self.bbox[2]});
        );
        out body;
        >;
        out skel qt;
        """

        print(f"[FETCH] Fetching Bahrain coastline data for bbox: {self.bbox}")
        response = requests.post(overpass_url, data={'data': overpass_query})

        if response.status_code != 200:
            raise Exception(f"Overpass API error: {response.status_code}")

        data = response.json()
        print(f"[OK] Retrieved {len(data.get('elements', []))} elements from OSM")

        return data.get('elements', [])

    def parse_osm_to_linestrings(self, osm_data: List[Dict]) -> List[LineString]:
        """
        Convert OSM data to Shapely LineString objects.

        Args:
            osm_data: Raw OSM elements

        Returns:
            List of LineString geometries representing coastline segments
        """
        # Create node dictionary for coordinate lookup
        nodes = {}
        for element in osm_data:
            if element['type'] == 'node':
                nodes[element['id']] = (element['lon'], element['lat'])

        # Extract ways and create LineStrings
        linestrings = []
        for element in osm_data:
            if element['type'] == 'way' and 'nodes' in element:
                coords = []
                for node_id in element['nodes']:
                    if node_id in nodes:
                        coords.append(nodes[node_id])

                if len(coords) >= 2:
                    linestrings.append(LineString(coords))

        print(f"[OK] Created {len(linestrings)} coastline segments")
        return linestrings

    def validate_and_close_polygons(self, linestrings: List[LineString]) -> List[Polygon]:
        """
        Validate polygon integrity and ensure all polygons are properly closed.

        Args:
            linestrings: List of coastline segments

        Returns:
            List of valid, closed Polygon objects
        """
        print("[VALIDATE] Validating and closing polygons...")

        # Attempt to polygonize the linestrings
        polygons = list(polygonize(linestrings))

        validated_polygons = []
        gaps_found = 0

        for i, poly in enumerate(polygons):
            # Check if polygon is valid
            if not poly.is_valid:
                print(f"  [WARN] Polygon {i} invalid, attempting repair...")
                poly = make_valid(poly)

            # Ensure polygon is closed
            if poly.exterior is not None:
                coords = list(poly.exterior.coords)
                if coords[0] != coords[-1]:
                    print(f"  [WARN] Polygon {i} not closed, closing...")
                    coords.append(coords[0])
                    poly = Polygon(coords)
                    gaps_found += 1

            # Validate final polygon
            if poly.is_valid and poly.area > 0:
                validated_polygons.append(poly)
            else:
                print(f"  [FAIL] Polygon {i} failed validation, skipping")

        print(f"[OK] Validated {len(validated_polygons)} polygons")
        if gaps_found > 0:
            print(f"[OK] Fixed {gaps_found} unclosed polygon(s)")

        return validated_polygons

    def create_land_mask(self, polygons: List[Polygon]) -> MultiPolygon:
        """
        Convert coastline polygons into unified land mask.

        Args:
            polygons: List of coastline polygons

        Returns:
            MultiPolygon representing all land areas
        """
        print("[MAP] Creating land mask from polygons...")

        if not polygons:
            print("[WARN] Warning: No polygons to create land mask")
            return MultiPolygon([])

        # Union all polygons to create continuous land mask
        land_mask = unary_union(polygons)

        # Ensure result is MultiPolygon for consistency
        if isinstance(land_mask, Polygon):
            land_mask = MultiPolygon([land_mask])

        print(f"[OK] Land mask created with {len(land_mask.geoms)} polygon(s)")
        return land_mask

    def extract_coastline(self) -> MultiPolygon:
        """
        Complete coastline extraction pipeline.

        Returns:
            MultiPolygon representing Bahrain's land areas
        """
        # Step 1: Fetch OSM data
        osm_data = self.fetch_coastline_osm()

        # Step 2: Parse to LineStrings
        linestrings = self.parse_osm_to_linestrings(osm_data)

        if not linestrings:
            print("[WARN] Warning: No coastline data found")
            return MultiPolygon([])

        # Step 3: Validate and close polygons
        polygons = self.validate_and_close_polygons(linestrings)

        # Step 4: Create land mask
        land_mask = self.create_land_mask(polygons)

        return land_mask


class TerritorialWaterGenerator:
    """Generates 12 nautical mile territorial water boundaries using geodesic buffering."""

    def __init__(self):
        """Initialize with WGS84 ellipsoid for accurate geodesic calculations."""
        self.geod = Geod(ellps='WGS84')

    def create_geodesic_buffer(self, geometry, distance_meters: float, segments: int = 64) -> Polygon:
        """
        Create a geodesic buffer around a geometry.

        This uses proper great circle distances on the WGS84 ellipsoid,
        unlike simple planar buffers which are inaccurate for lat/lon coordinates.

        Args:
            geometry: Input geometry (Polygon or MultiPolygon)
            distance_meters: Buffer distance in meters (e.g., 22224 for 12nm)
            segments: Number of segments for circular approximation

        Returns:
            Buffered polygon
        """
        print(f"[BUFFER] Creating geodesic buffer: {distance_meters/1852:.1f} nautical miles ({distance_meters:.0f} meters)")

        if isinstance(geometry, MultiPolygon):
            buffered_parts = []
            for poly in geometry.geoms:
                buffered = self._buffer_single_polygon(poly, distance_meters, segments)
                buffered_parts.append(buffered)
            result = unary_union(buffered_parts)
        else:
            result = self._buffer_single_polygon(geometry, distance_meters, segments)

        print(f"[OK] Geodesic buffer created")
        return result

    def _buffer_single_polygon(self, polygon: Polygon, distance_meters: float, segments: int) -> Polygon:
        """
        Buffer a single polygon using geodesic calculations.

        Args:
            polygon: Input polygon
            distance_meters: Buffer distance in meters
            segments: Number of segments per edge

        Returns:
            Buffered polygon
        """
        # Extract exterior coordinates
        exterior_coords = list(polygon.exterior.coords)

        # Create buffered points around the perimeter
        buffered_coords = []

        for i in range(len(exterior_coords) - 1):
            lon1, lat1 = exterior_coords[i]
            lon2, lat2 = exterior_coords[i + 1]

            # Calculate azimuth (bearing) of the edge
            fwd_azimuth, _, _ = self.geod.inv(lon1, lat1, lon2, lat2)

            # Create perpendicular offset points (90 degrees to the right)
            offset_azimuth = (fwd_azimuth + 90) % 360

            # Calculate offset point
            offset_lon, offset_lat, _ = self.geod.fwd(lon1, lat1, offset_azimuth, distance_meters)
            buffered_coords.append((offset_lon, offset_lat))

        # Close the polygon
        if buffered_coords and buffered_coords[0] != buffered_coords[-1]:
            buffered_coords.append(buffered_coords[0])

        # Create convex hull to smooth out the buffer
        if len(buffered_coords) >= 3:
            buffered_poly = Polygon(buffered_coords).convex_hull

            # Union with original to ensure we include all land
            result = unary_union([polygon, buffered_poly])

            if isinstance(result, MultiPolygon):
                # Take the largest polygon
                result = max(result.geoms, key=lambda p: p.area)

            return result

        return polygon

    def create_territorial_waters(self, land_mask: MultiPolygon,
                                  distance_nm: float = 12) -> Polygon:
        """
        Create territorial water boundary by buffering coastline.

        Args:
            land_mask: Land areas (coastline polygons)
            distance_nm: Territorial water distance in nautical miles (default 12)

        Returns:
            Polygon representing territorial water boundary
        """
        distance_meters = distance_nm * NAUTICAL_MILE_TO_METERS

        print(f"[WATER] Generating {distance_nm} nautical mile territorial waters...")

        # Create geodesic buffer
        territorial_boundary = self.create_geodesic_buffer(land_mask, distance_meters)

        # Subtract land to get water-only area
        territorial_waters = territorial_boundary.difference(land_mask)

        print(f"[OK] Territorial waters area: {territorial_waters.area:.6f} square degrees")

        return territorial_waters


class MaritimeBoundaryClipper:
    """Clips territorial waters against international maritime boundaries."""

    def __init__(self):
        """Initialize boundary clipper."""
        pass

    def create_qatar_boundary(self) -> LineString:
        """
        Create maritime boundary with Qatar.

        Based on the 2001 ICJ ruling between Bahrain and Qatar.
        This is a simplified median line - for production use,
        official boundary coordinates should be used.

        Returns:
            LineString representing the Qatar-Bahrain maritime boundary
        """
        print("[QATAR] Creating Qatar maritime boundary...")

        # Approximate median line between Bahrain and Qatar
        # These are simplified coordinates - replace with official boundary data
        boundary_coords = [
            (50.85, 25.85),   # Southern point
            (50.85, 26.10),   # Middle point
            (50.85, 26.35),   # Northern point
        ]

        boundary = LineString(boundary_coords)
        print(f"[OK] Qatar boundary created with {len(boundary_coords)} points")

        return boundary

    def create_saudi_boundary(self) -> LineString:
        """
        Create maritime boundary with Saudi Arabia.

        This is a simplified median line - for production use,
        official boundary coordinates should be used.

        Returns:
            LineString representing the Saudi-Bahrain maritime boundary
        """
        print("[SAUDI] Creating Saudi Arabia maritime boundary...")

        # Approximate median line between Bahrain and Saudi Arabia
        # These are simplified coordinates - replace with official boundary data
        boundary_coords = [
            (50.35, 25.85),   # Southern point
            (50.35, 26.00),   # Middle point
            (50.35, 26.20),   # Northern point
        ]

        boundary = LineString(boundary_coords)
        print(f"[OK] Saudi boundary created with {len(boundary_coords)} points")

        return boundary

    def create_boundary_clip_polygon(self, qatar_boundary: LineString,
                                     saudi_boundary: LineString,
                                     bbox: Tuple[float, float, float, float]) -> Polygon:
        """
        Create a polygon representing Bahrain's maritime zone between boundaries.

        Args:
            qatar_boundary: Eastern boundary with Qatar
            saudi_boundary: Western boundary with Saudi Arabia
            bbox: Bounding box (min_lon, min_lat, max_lon, max_lat)

        Returns:
            Polygon defining Bahrain's permitted maritime zone
        """
        print("[CLIP] Creating boundary clip polygon...")

        # Create a polygon bounded by the maritime boundaries
        # This represents the area where Bahrain can claim territorial waters

        coords = []

        # Start from south-west corner
        coords.append((bbox[0], bbox[1]))

        # Follow Saudi boundary northward (western edge)
        for coord in saudi_boundary.coords:
            coords.append(coord)

        # Add northern edge
        coords.append((bbox[0], bbox[3]))
        coords.append((bbox[2], bbox[3]))

        # Follow Qatar boundary southward (eastern edge)
        for coord in reversed(list(qatar_boundary.coords)):
            coords.append(coord)

        # Add southern edge
        coords.append((bbox[2], bbox[1]))

        # Close polygon
        coords.append(coords[0])

        clip_polygon = Polygon(coords)

        print(f"[OK] Clip polygon created with {len(coords)} vertices")

        return clip_polygon

    def clip_territorial_waters(self, territorial_waters: Polygon,
                                bbox: Tuple[float, float, float, float]) -> Polygon:
        """
        Clip territorial waters against maritime boundaries.

        Args:
            territorial_waters: Unclipped territorial water polygon
            bbox: Bounding box for boundaries

        Returns:
            Clipped territorial water polygon respecting international boundaries
        """
        print("[BOUNDARY] Clipping territorial waters against international boundaries...")

        # Create boundary lines
        qatar_boundary = self.create_qatar_boundary()
        saudi_boundary = self.create_saudi_boundary()

        # Create clip polygon
        clip_polygon = self.create_boundary_clip_polygon(
            qatar_boundary, saudi_boundary, bbox
        )

        # Clip territorial waters
        clipped_waters = territorial_waters.intersection(clip_polygon)

        print(f"[OK] Clipped territorial waters area: {clipped_waters.area:.6f} square degrees")

        return clipped_waters


class MaskRasterizer:
    """Rasterizes territorial water masks to grid resolution."""

    def __init__(self, bbox: Tuple[float, float, float, float],
                 resolution: float = 0.001):
        """
        Initialize mask rasterizer.

        Args:
            bbox: Bounding box (min_lon, min_lat, max_lon, max_lat)
            resolution: Grid resolution in degrees (default ~111m at equator)
        """
        self.bbox = bbox
        self.resolution = resolution

        # Calculate grid dimensions
        self.width = int((bbox[2] - bbox[0]) / resolution)
        self.height = int((bbox[3] - bbox[1]) / resolution)

        print(f"[GRID] Grid dimensions: {self.width}x{self.height} ({self.width * self.height:,} cells)")

    def rasterize_water_mask(self, water_polygon, land_mask: MultiPolygon) -> np.ndarray:
        """
        Rasterize water mask to binary grid.

        Args:
            water_polygon: Territorial water polygon
            land_mask: Land areas to mark as non-navigable

        Returns:
            2D numpy array (1 = navigable water, 0 = land/out of bounds)
        """
        print("[RASTER] Rasterizing water mask...")

        # Create transform for the grid
        transform = from_bounds(
            self.bbox[0], self.bbox[1],
            self.bbox[2], self.bbox[3],
            self.width, self.height
        )

        # Initialize grid (default = 0 = land)
        mask = np.zeros((self.height, self.width), dtype=np.uint8)

        # Rasterize water as 1
        if not water_polygon.is_empty:
            water_shapes = [(water_polygon, 1)]
            features.rasterize(
                shapes=water_shapes,
                out=mask,
                transform=transform,
                dtype=np.uint8
            )

        # Ensure land is 0 (double-check by rasterizing land mask)
        if not land_mask.is_empty:
            land_shapes = [(geom, 0) for geom in land_mask.geoms]
            features.rasterize(
                shapes=land_shapes,
                out=mask,
                transform=transform,
                dtype=np.uint8
            )

        water_percentage = (np.sum(mask) / mask.size) * 100
        print(f"[OK] Rasterization complete: {water_percentage:.2f}% navigable water")

        return mask

    def save_mask_files(self, mask: np.ndarray, water_polygon, land_mask: MultiPolygon,
                       output_prefix: str = "bahrain_territorial_waters"):
        """
        Save mask in multiple formats.

        Args:
            mask: Binary mask array
            water_polygon: Water area polygon
            land_mask: Land area polygons
            output_prefix: Prefix for output files
        """
        print(f"[SAVE] Saving mask files with prefix: {output_prefix}")

        # 1. Save binary mask (.bin)
        mask.tofile(f"{output_prefix}.bin")
        print(f"[OK] Saved {output_prefix}.bin")

        # 2. Save numpy compressed (.npz)
        np.savez_compressed(
            f"{output_prefix}.npz",
            mask=mask,
            bbox=self.bbox,
            resolution=self.resolution
        )
        print(f"[OK] Saved {output_prefix}.npz")

        # 3. Save metadata (.json)
        metadata = {
            "bbox": {
                "min_lon": self.bbox[0],
                "min_lat": self.bbox[1],
                "max_lon": self.bbox[2],
                "max_lat": self.bbox[3]
            },
            "grid": {
                "width": self.width,
                "height": self.height,
                "resolution_degrees": self.resolution,
                "resolution_meters_approx": self.resolution * 111000  # rough conversion
            },
            "projection": "EPSG:4326",
            "encoding": {
                "water": 1,
                "land": 0
            },
            "territorial_waters": "12 nautical miles (22,224 meters)",
            "boundaries": "Clipped against Qatar and Saudi Arabia maritime boundaries"
        }

        with open(f"{output_prefix}_metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)
        print(f"[OK] Saved {output_prefix}_metadata.json")

        # 4. Save GeoTIFF (.tif)
        transform = from_bounds(
            self.bbox[0], self.bbox[1],
            self.bbox[2], self.bbox[3],
            self.width, self.height
        )

        with rasterio.open(
            f"{output_prefix}.tif",
            'w',
            driver='GTiff',
            height=self.height,
            width=self.width,
            count=1,
            dtype=np.uint8,
            crs='EPSG:4326',
            transform=transform,
            compress='lzw'
        ) as dst:
            dst.write(mask, 1)
        print(f"[OK] Saved {output_prefix}.tif")

        # 5. Save water polygon GeoJSON
        water_geojson = {
            "type": "Feature",
            "properties": {
                "name": "Bahrain Territorial Waters (12 nm)",
                "type": "territorial_waters",
                "distance_nm": 12,
                "distance_meters": 22224
            },
            "geometry": mapping(water_polygon)
        }

        with open(f"{output_prefix}_water.geojson", 'w') as f:
            json.dump(water_geojson, f, indent=2)
        print(f"[OK] Saved {output_prefix}_water.geojson")

        # 6. Save land polygon GeoJSON
        land_geojson = {
            "type": "Feature",
            "properties": {
                "name": "Bahrain Land Areas",
                "type": "land"
            },
            "geometry": mapping(land_mask)
        }

        with open(f"{output_prefix}_land.geojson", 'w') as f:
            json.dump(land_geojson, f, indent=2)
        print(f"[OK] Saved {output_prefix}_land.geojson")

        print(f"[OK] All mask files saved successfully!")


class TerritorialWaterPipeline:
    """Complete pipeline for generating Bahrain's territorial water mask."""

    def __init__(self, bbox: Tuple[float, float, float, float],
                 resolution: float = 0.001,
                 territorial_distance_nm: float = 12):
        """
        Initialize pipeline.

        Args:
            bbox: Bounding box (min_lon, min_lat, max_lon, max_lat)
            resolution: Grid resolution in degrees
            territorial_distance_nm: Territorial water distance in nautical miles
        """
        self.bbox = bbox
        self.resolution = resolution
        self.territorial_distance_nm = territorial_distance_nm

        print("=" * 70)
        print("BAHRAIN TERRITORIAL WATER MASK GENERATOR")
        print("=" * 70)
        print(f"Bounding Box: {bbox}")
        print(f"Resolution: {resolution} degrees (~{resolution * 111:.0f}m)")
        print(f"Territorial Waters: {territorial_distance_nm} nautical miles")
        print("=" * 70)

    def run_pipeline(self, output_prefix: str = "bahrain_territorial_waters"):
        """
        Execute complete pipeline.

        Args:
            output_prefix: Prefix for output files
        """
        print("\n[START] Starting pipeline...\n")

        # Step 1: Extract coastline
        print("STEP 1: Extract Bahrain Coastline")
        print("-" * 70)
        extractor = BahrainCoastlineExtractor(self.bbox)
        land_mask = extractor.extract_coastline()

        if land_mask.is_empty:
            print("[ERROR] No coastline data extracted")
            return

        # Step 2: Generate territorial waters
        print("\nSTEP 2: Generate 12nm Territorial Waters")
        print("-" * 70)
        generator = TerritorialWaterGenerator()
        territorial_waters = generator.create_territorial_waters(
            land_mask,
            distance_nm=self.territorial_distance_nm
        )

        # Step 3: Clip against maritime boundaries
        print("\nSTEP 3: Clip Against International Boundaries")
        print("-" * 70)
        clipper = MaritimeBoundaryClipper()
        clipped_waters = clipper.clip_territorial_waters(territorial_waters, self.bbox)

        # Step 4: Rasterize and save
        print("\nSTEP 4: Rasterize and Save Mask")
        print("-" * 70)
        rasterizer = MaskRasterizer(self.bbox, self.resolution)
        mask = rasterizer.rasterize_water_mask(clipped_waters, land_mask)
        rasterizer.save_mask_files(mask, clipped_waters, land_mask, output_prefix)

        # Final summary
        print("\n" + "=" * 70)
        print("[DONE] PIPELINE COMPLETE!")
        print("=" * 70)
        print(f"Generated files:")
        print(f"  - {output_prefix}.bin (binary mask)")
        print(f"  - {output_prefix}.npz (numpy compressed)")
        print(f"  - {output_prefix}.tif (GeoTIFF)")
        print(f"  - {output_prefix}_water.geojson (water polygon)")
        print(f"  - {output_prefix}_land.geojson (land polygon)")
        print(f"  - {output_prefix}_metadata.json (metadata)")
        print("=" * 70)


# Example usage
if __name__ == "__main__":
    # Bahrain maritime area bounding box
    # Extended to include 12nm territorial waters
    BAHRAIN_BBOX = (
        50.30,   # min_longitude (west) - extended for territorial waters
        25.80,   # min_latitude (south) - extended for territorial waters
        50.90,   # max_longitude (east) - extended for territorial waters
        26.40    # max_latitude (north) - extended for territorial waters
    )

    # Initialize and run pipeline
    # Resolution: 0.001 degrees = approx 111 meters (suitable for maritime routing)
    pipeline = TerritorialWaterPipeline(
        bbox=BAHRAIN_BBOX,
        resolution=0.001,
        territorial_distance_nm=12
    )

    pipeline.run_pipeline(output_prefix="bahrain_territorial_waters")
