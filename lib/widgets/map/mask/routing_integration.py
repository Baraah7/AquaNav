"""
Routing Engine Integration for Land/Water Mask
Provides utilities for maritime route planning that respects coastline constraints.
"""

import numpy as np
from typing import Tuple, List, Optional
from dataclasses import dataclass
import json


@dataclass
class RoutePoint:
    """Represents a point in maritime route."""
    lon: float
    lat: float
    is_navigable: bool


class NavigationMaskHandler:
    """Handles land/water mask for routing operations."""
    
    def __init__(self, mask_path: str):
        """
        Load navigation mask from file.
        
        Args:
            mask_path: Path to .npz mask file
        """
        data = np.load(mask_path)
        self.mask = data['mask']
        self.bbox = tuple(data['bbox'])
        self.resolution = float(data['resolution'])
        self.width = int(data['width'])
        self.height = int(data['height'])
        
        print(f"Loaded navigation mask: {self.width}x{self.height}")
        print(f"Bounding box: {self.bbox}")
        print(f"Resolution: {self.resolution}° (~{self.resolution * 111:.1f}km)")
    
    def latlon_to_grid(self, lon: float, lat: float) -> Tuple[int, int]:
        """
        Convert geographic coordinates to grid indices.
        
        Args:
            lon: Longitude
            lat: Latitude
            
        Returns:
            Tuple of (row, col) grid indices
        """
        # Calculate normalized position in bbox
        x_norm = (lon - self.bbox[0]) / (self.bbox[2] - self.bbox[0])
        y_norm = (self.bbox[3] - lat) / (self.bbox[3] - self.bbox[1])
        
        # Convert to grid coordinates
        col = int(x_norm * self.width)
        row = int(y_norm * self.height)
        
        # Clamp to valid range
        col = max(0, min(col, self.width - 1))
        row = max(0, min(row, self.height - 1))
        
        return row, col
    
    def grid_to_latlon(self, row: int, col: int) -> Tuple[float, float]:
        """
        Convert grid indices to geographic coordinates.
        
        Args:
            row: Grid row index
            col: Grid column index
            
        Returns:
            Tuple of (lon, lat)
        """
        lon = self.bbox[0] + (col + 0.5) * self.resolution
        lat = self.bbox[3] - (row + 0.5) * self.resolution
        
        return lon, lat
    
    def is_navigable(self, lon: float, lat: float) -> bool:
        """
        Check if a geographic point is navigable (water).
        
        Args:
            lon: Longitude
            lat: Latitude
            
        Returns:
            True if point is in water, False if on land
        """
        row, col = self.latlon_to_grid(lon, lat)
        return bool(self.mask[row, col] == 1)
    
    def is_route_navigable(self, route: List[Tuple[float, float]], 
                          sample_points: int = 10) -> Tuple[bool, List[int]]:
        """
        Check if entire route is navigable, sampling along segments.
        
        Args:
            route: List of (lon, lat) waypoints
            sample_points: Number of points to sample per segment
            
        Returns:
            Tuple of (is_navigable, list of invalid segment indices)
        """
        invalid_segments = []
        
        for i in range(len(route) - 1):
            start = route[i]
            end = route[i + 1]
            
            # Sample points along segment
            for j in range(sample_points + 1):
                t = j / sample_points
                lon = start[0] + t * (end[0] - start[0])
                lat = start[1] + t * (end[1] - start[1])
                
                if not self.is_navigable(lon, lat):
                    invalid_segments.append(i)
                    break
        
        return len(invalid_segments) == 0, invalid_segments
    
    def find_nearest_water(self, lon: float, lat: float, 
                          max_search_radius: int = 50) -> Optional[Tuple[float, float]]:
        """
        Find nearest navigable water point from a land location.
        
        Args:
            lon: Starting longitude
            lat: Starting latitude
            max_search_radius: Maximum search radius in grid cells
            
        Returns:
            (lon, lat) of nearest water point, or None if not found
        """
        start_row, start_col = self.latlon_to_grid(lon, lat)
        
        # If already in water, return original point
        if self.mask[start_row, start_col] == 1:
            return lon, lat
        
        # Spiral search outward
        for radius in range(1, max_search_radius):
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if abs(dr) != radius and abs(dc) != radius:
                        continue
                    
                    row = start_row + dr
                    col = start_col + dc
                    
                    if (0 <= row < self.height and 
                        0 <= col < self.width and 
                        self.mask[row, col] == 1):
                        return self.grid_to_latlon(row, col)
        
        return None
    
    def get_navigable_area_stats(self) -> dict:
        """
        Get statistics about navigable area.
        
        Returns:
            Dictionary with area statistics
        """
        total_cells = self.width * self.height
        water_cells = np.sum(self.mask == 1)
        land_cells = total_cells - water_cells
        
        # Approximate area calculation (assumes square cells)
        cell_area_km2 = (self.resolution * 111) ** 2
        
        return {
            'total_cells': total_cells,
            'water_cells': int(water_cells),
            'land_cells': int(land_cells),
            'water_percentage': (water_cells / total_cells) * 100,
            'water_area_km2': water_cells * cell_area_km2,
            'land_area_km2': land_cells * cell_area_km2
        }


class RoutePlanner:
    """Simple A* route planner using land/water mask."""
    
    def __init__(self, mask_handler: NavigationMaskHandler):
        """
        Initialize route planner.
        
        Args:
            mask_handler: NavigationMaskHandler instance
        """
        self.mask = mask_handler
    
    def plan_route(self, start: Tuple[float, float], 
                   end: Tuple[float, float]) -> Optional[List[Tuple[float, float]]]:
        """
        Plan a maritime route avoiding land.
        
        Args:
            start: (lon, lat) starting point
            end: (lon, lat) destination point
            
        Returns:
            List of waypoints, or None if no route found
        """
        # Convert to grid coordinates
        start_row, start_col = self.mask.latlon_to_grid(start[0], start[1])
        end_row, end_col = self.mask.latlon_to_grid(end[0], end[1])
        
        # Validate start and end points
        if not self.mask.is_navigable(start[0], start[1]):
            print(f"Start point {start} is on land, finding nearest water...")
            nearest = self.mask.find_nearest_water(start[0], start[1])
            if nearest:
                start = nearest
                start_row, start_col = self.mask.latlon_to_grid(start[0], start[1])
            else:
                print("Could not find navigable start point")
                return None
        
        if not self.mask.is_navigable(end[0], end[1]):
            print(f"End point {end} is on land, finding nearest water...")
            nearest = self.mask.find_nearest_water(end[0], end[1])
            if nearest:
                end = nearest
                end_row, end_col = self.mask.latlon_to_grid(end[0], end[1])
            else:
                print("Could not find navigable end point")
                return None
        
        # Simple A* implementation
        from heapq import heappush, heappop
        
        open_set = [(0, start_row, start_col)]
        came_from = {}
        g_score = {(start_row, start_col): 0}
        
        def heuristic(r1, c1, r2, c2):
            return np.sqrt((r1 - r2)**2 + (c1 - c2)**2)
        
        directions = [(-1,0), (1,0), (0,-1), (0,1), 
                     (-1,-1), (-1,1), (1,-1), (1,1)]
        
        while open_set:
            _, current_row, current_col = heappop(open_set)
            
            if (current_row, current_col) == (end_row, end_col):
                # Reconstruct path
                path = []
                current = (end_row, end_col)
                while current in came_from:
                    lon, lat = self.mask.grid_to_latlon(current[0], current[1])
                    path.append((lon, lat))
                    current = came_from[current]
                lon, lat = self.mask.grid_to_latlon(start_row, start_col)
                path.append((lon, lat))
                return list(reversed(path))
            
            for dr, dc in directions:
                neighbor_row = current_row + dr
                neighbor_col = current_col + dc
                
                # Check bounds
                if not (0 <= neighbor_row < self.mask.height and 
                       0 <= neighbor_col < self.mask.width):
                    continue
                
                # Check if navigable
                if self.mask.mask[neighbor_row, neighbor_col] != 1:
                    continue
                
                # Calculate tentative g_score
                move_cost = np.sqrt(dr**2 + dc**2)
                tentative_g = g_score.get((current_row, current_col), float('inf')) + move_cost
                
                if tentative_g < g_score.get((neighbor_row, neighbor_col), float('inf')):
                    came_from[(neighbor_row, neighbor_col)] = (current_row, current_col)
                    g_score[(neighbor_row, neighbor_col)] = tentative_g
                    f_score = tentative_g + heuristic(neighbor_row, neighbor_col, 
                                                      end_row, end_col)
                    heappush(open_set, (f_score, neighbor_row, neighbor_col))
        
        print("No navigable route found")
        return None


# Example usage
if __name__ == "__main__":
    # Load mask
    mask = NavigationMaskHandler("bahrain_navigation_mask.npz")
    
    # Display statistics
    stats = mask.get_navigable_area_stats()
    print("\nNavigable Area Statistics:")
    print(f"  Water area: {stats['water_area_km2']:.2f} km²")
    print(f"  Land area: {stats['land_area_km2']:.2f} km²")
    print(f"  Water coverage: {stats['water_percentage']:.2f}%")
    
    # Test point navigation
    test_point = (50.6, 26.2)  # Bahrain waters
    if mask.is_navigable(test_point[0], test_point[1]):
        print(f"\n✓ Point {test_point} is navigable")
    else:
        print(f"\n✗ Point {test_point} is on land")
        nearest = mask.find_nearest_water(test_point[0], test_point[1])
        if nearest:
            print(f"  Nearest water: {nearest}")
    
    # Plan a route
    planner = RoutePlanner(mask)
    route = planner.plan_route(
        start=(50.45, 26.0),
        end=(50.65, 26.25)
    )
    
    if route:
        print(f"\n✓ Route planned with {len(route)} waypoints")
        print(f"  Start: {route[0]}")
        print(f"  End: {route[-1]}")
