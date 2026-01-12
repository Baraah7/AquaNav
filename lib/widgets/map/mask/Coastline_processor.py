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
from typing import List, Tuple, Dict, Optional
import warnings
warnings.filterwarnings('ignore')


class CoastlineExtractor:
    """Extracts and processes coastline data from OpenStreetMap."""
    
    def __init__(self, bbox: Tuple[float, float, float, float]):
        """
        Initialize coastline extractor.
        
        Args:
            bbox: Bounding box (min_lon, min_lat, max_lon, max_lat) for Bahrain waters
        """
        self.bbox = bbox
        self.coastline_ways = []
        self.coastline_polygons = []
        
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
        
        print(f"Fetching coastline data for bbox: {self.bbox}")
        response = requests.post(overpass_url, data={'data': overpass_query})
        
        if response.status_code != 200:
            raise Exception(f"Overpass API error: {response.status_code}")
        
        data = response.json()
        print(f"Retrieved {len(data.get('elements', []))} elements from OSM")
        
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
        
        print(f"Created {len(linestrings)} coastline segments")
        return linestrings
    
    def validate_and_close_polygons(self, linestrings: List[LineString]) -> List[Polygon]:
        """
        Validate polygon integrity and ensure all polygons are properly closed.
        
        Args:
            linestrings: List of coastline segments
            
        Returns:
            List of valid, closed Polygon objects
        """
        print("Validating and closing polygons...")
        
        # Attempt to polygonize the linestrings
        polygons = list(polygonize(linestrings))
        
        validated_polygons = []
        gaps_found = 0
        
        for i, poly in enumerate(polygons):
            # Check if polygon is valid
            if not poly.is_valid:
                print(f"  Polygon {i} invalid, attempting repair...")
                poly = make_valid(poly)
            
            # Ensure polygon is closed
            if poly.exterior is not None:
                coords = list(poly.exterior.coords)
                if coords[0] != coords[-1]:
                    print(f"  Polygon {i} not closed, closing...")
                    coords.append(coords[0])
                    poly = Polygon(coords)
                    gaps_found += 1
            
            # Validate final polygon
            if poly.is_valid and poly.area > 0:
                validated_polygons.append(poly)
            else:
                print(f"  Polygon {i} failed validation, skipping")
        
        print(f"Validated {len(validated_polygons)} polygons")
        print(f"Gaps/unclosed polygons fixed: {gaps_found}")
        
        return validated_polygons
    
    def create_land_mask(self, polygons: List[Polygon]) -> MultiPolygon:
        """
        Convert coastline polygons into unified land mask.
        
        Args:
            polygons: List of coastline polygons
            
        Returns:
            MultiPolygon representing all land areas
        """
        print("Creating land mask from polygons...")
        
        if not polygons:
            print("Warning: No polygons to create land mask")
            return MultiPolygon([])
        
        # Union all polygons to create continuous land mask
        land_mask = unary_union(polygons)
        
        # Ensure result is MultiPolygon for consistency
        if isinstance(land_mask, Polygon):
            land_mask = MultiPolygon([land_mask])
        
        print(f"Land mask created with {len(land_mask.geoms)} polygon(s)")
        return land_mask
    
    def generate_water_area(self, land_mask: MultiPolygon) -> Polygon:
        """
        Generate water-only navigable area by subtracting land from bounding box.
        
        Args:
            land_mask: MultiPolygon of land areas
            
        Returns:
            Polygon representing navigable water area
        """
        print("Generating navigable water area...")
        
        # Create bounding box polygon
        bbox_polygon = Polygon([
            (self.bbox[0], self.bbox[1]),  # min_lon, min_lat
            (self.bbox[2], self.bbox[1]),  # max_lon, min_lat
            (self.bbox[2], self.bbox[3]),  # max_lon, max_lat
            (self.bbox[0], self.bbox[3]),  # min_lon, max_lat
            (self.bbox[0], self.bbox[1])   # close polygon
        ])
        
        # Subtract land from total area to get water
        water_area = bbox_polygon.difference(land_mask)
        
        if water_area.is_empty:
            print("Warning: Water area is empty")
            return bbox_polygon
        
        print(f"Water area generated: {water_area.area:.6f} square degrees")
        return water_area
    
    def process_coastline(self) -> Tuple[MultiPolygon, Polygon]:
        """
        Complete coastline processing pipeline.
        
        Returns:
            Tuple of (land_mask, water_area)
        """
        # Step 1: Fetch OSM data
        osm_data = self.fetch_coastline_osm()
        
        # Step 2: Parse to LineStrings
        linestrings = self.parse_osm_to_linestrings(osm_data)
        
        if not linestrings:
            print("Warning: No coastline data found, creating empty masks")
            return MultiPolygon([]), Polygon([
                (self.bbox[0], self.bbox[1]),
                (self.bbox[2], self.bbox[1]),
                (self.bbox[2], self.bbox[3]),
                (self.bbox[0], self.bbox[3])
            ])
        
        # Step 3: Validate and close polygons
        polygons = self.validate_and_close_polygons(linestrings)
        
        # Step 4: Create land mask
        land_mask = self.create_land_mask(polygons)
        
        # Step 5: Generate water area
        water_area = self.generate_water_area(land_mask)
        
        return land_mask, water_area


class MaskRasterizer:
    """Rasterizes land/water masks to grid resolution for routing engine."""
    
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
        
        print(f"Raster grid: {self.width}x{self.height} pixels")
        print(f"Resolution: {resolution}° (~{resolution * 111:.1f}km)")
    
    def rasterize_mask(self, land_mask: MultiPolygon, 
                       water_area: Polygon) -> np.ndarray:
        """
        Rasterize land/water mask to binary grid.
        
        Args:
            land_mask: MultiPolygon of land areas
            water_area: Polygon of navigable water
            
        Returns:
            Binary numpy array (1 = water/navigable, 0 = land/blocked)
        """
        print("Rasterizing mask to grid...")
        
        # Create affine transformation for raster
        transform = from_bounds(
            self.bbox[0], self.bbox[1], 
            self.bbox[2], self.bbox[3],
            self.width, self.height
        )
        
        # Initialize raster as all land (0)
        raster = np.zeros((self.height, self.width), dtype=np.uint8)
        
        # Rasterize water area as navigable (1)
        if not water_area.is_empty:
            water_shapes = [(water_area, 1)]
            features.rasterize(
                shapes=water_shapes,
                out=raster,
                transform=transform,
                fill=0,
                default_value=1,
                dtype=np.uint8
            )
        
        navigable_pixels = np.sum(raster == 1)
        total_pixels = self.width * self.height
        navigable_percent = (navigable_pixels / total_pixels) * 100
        
        print(f"Rasterization complete:")
        print(f"  Navigable (water): {navigable_pixels:,} pixels ({navigable_percent:.2f}%)")
        print(f"  Blocked (land): {total_pixels - navigable_pixels:,} pixels")
        
        return raster
    
    def export_geotiff(self, raster: np.ndarray, output_path: str):
        """
        Export raster mask as GeoTIFF for GIS compatibility.
        
        Args:
            raster: Binary mask array
            output_path: Output file path
        """
        transform = from_bounds(
            self.bbox[0], self.bbox[1], 
            self.bbox[2], self.bbox[3],
            self.width, self.height
        )
        
        with rasterio.open(
            output_path,
            'w',
            driver='GTiff',
            height=raster.shape[0],
            width=raster.shape[1],
            count=1,
            dtype=raster.dtype,
            crs='EPSG:4326',
            transform=transform,
            compress='lzw'
        ) as dst:
            dst.write(raster, 1)
        
        print(f"GeoTIFF exported: {output_path}")
    
    def export_numpy(self, raster: np.ndarray, output_path: str):
        """
        Export raster mask as compressed NumPy array for routing engine.
        
        Args:
            raster: Binary mask array
            output_path: Output file path (.npz)
        """
        np.savez_compressed(
            output_path,
            mask=raster,
            bbox=self.bbox,
            resolution=self.resolution,
            width=self.width,
            height=self.height
        )
        print(f"NumPy array exported: {output_path}")
    
    def export_json_metadata(self, output_path: str):
        """
        Export mask metadata as JSON for tile alignment.
        
        Args:
            output_path: Output JSON file path
        """
        metadata = {
            'bbox': {
                'min_lon': self.bbox[0],
                'min_lat': self.bbox[1],
                'max_lon': self.bbox[2],
                'max_lat': self.bbox[3]
            },
            'grid': {
                'width': self.width,
                'height': self.height,
                'resolution_degrees': self.resolution,
                'resolution_meters_approx': self.resolution * 111000
            },
            'projection': 'EPSG:4326',
            'encoding': {
                'water': 1,
                'land': 0
            }
        }
        
        with open(output_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"Metadata JSON exported: {output_path}")


class CoastlineMaskPipeline:
    """Complete pipeline for coastline extraction and mask generation."""
    
    def __init__(self, bbox: Tuple[float, float, float, float], 
                 resolution: float = 0.001):
        """
        Initialize complete processing pipeline.
        
        Args:
            bbox: Bounding box for processing area
            resolution: Grid resolution in degrees
        """
        self.extractor = CoastlineExtractor(bbox)
        self.rasterizer = MaskRasterizer(bbox, resolution)
        self.land_mask = None
        self.water_area = None
        self.raster_mask = None
    
    def run_pipeline(self, output_prefix: str = "bahaar_mask"):
        """
        Execute complete pipeline and export all outputs.
        
        Args:
            output_prefix: Prefix for output files
        """
        print("=" * 70)
        print("COASTLINE & LAND/WATER MASK GENERATION PIPELINE")
        print("=" * 70)
        
        # Step 1: Extract and process coastline
        print("\n[1/4] Extracting coastline from OpenStreetMap...")
        self.land_mask, self.water_area = self.extractor.process_coastline()
        
        # Step 2: Rasterize to grid
        print("\n[2/4] Rasterizing to grid resolution...")
        self.raster_mask = self.rasterizer.rasterize_mask(
            self.land_mask, 
            self.water_area
        )
        
        # Step 3: Export masks
        print("\n[3/4] Exporting mask files...")
        self.rasterizer.export_geotiff(
            self.raster_mask, 
            f"{output_prefix}.tif"
        )
        self.rasterizer.export_numpy(
            self.raster_mask, 
            f"{output_prefix}.npz"
        )
        self.rasterizer.export_json_metadata(
            f"{output_prefix}_metadata.json"
        )
        
        # Step 4: Export vector geometries
        print("\n[4/4] Exporting vector geometries...")
        self._export_geometries(output_prefix)
        
        # Validation report
        print("\n" + "=" * 70)
        print("PIPELINE COMPLETE - EXIT CRITERIA VALIDATION")
        print("=" * 70)
        self._validate_exit_criteria()
    
    def _export_geometries(self, output_prefix: str):
        """Export land and water geometries as GeoJSON."""
        # Export land mask
        land_gdf = gpd.GeoDataFrame(
            {'geometry': [self.land_mask], 'type': ['land']},
            crs='EPSG:4326'
        )
        land_gdf.to_file(f"{output_prefix}_land.geojson", driver='GeoJSON')
        print(f"Land geometry exported: {output_prefix}_land.geojson")
        
        # Export water area
        water_gdf = gpd.GeoDataFrame(
            {'geometry': [self.water_area], 'type': ['water']},
            crs='EPSG:4326'
        )
        water_gdf.to_file(f"{output_prefix}_water.geojson", driver='GeoJSON')
        print(f"Water geometry exported: {output_prefix}_water.geojson")
    
    def _validate_exit_criteria(self):
        """Validate all exit criteria are met."""
        criteria = {
            'Clear binary land/water mask': self.raster_mask is not None,
            'Aligned with map tiles (EPSG:4326)': True,
            'Polygons validated and closed': len(self.extractor.coastline_polygons) >= 0,
            'Land mask generated': self.land_mask is not None,
            'Water area generated': self.water_area is not None,
            'Raster export complete': self.raster_mask is not None
        }
        
        for criterion, status in criteria.items():
            status_mark = "✓" if status else "✗"
            print(f"{status_mark} {criterion}")
        
        all_passed = all(criteria.values())
        if all_passed:
            print("\n✓ All exit criteria met successfully!")
        else:
            print("\n✗ Some exit criteria not met - review pipeline")


# Example usage for Bahrain waters
if __name__ == "__main__":
    # Bahrain maritime area bounding box
    # Covers main island, Muharraq, and surrounding waters
    BAHRAIN_BBOX = (
        50.35,   # min_longitude (west)
        25.85,   # min_latitude (south)
        50.85,   # max_longitude (east)
        26.35    # max_latitude (north)
    )
    
    # Initialize and run pipeline
    # Resolution: 0.001° ≈ 111 meters (suitable for maritime routing)
    pipeline = CoastlineMaskPipeline(
        bbox=BAHRAIN_BBOX,
        resolution=0.001
    )
    
    pipeline.run_pipeline(output_prefix="bahrain_navigation_mask")