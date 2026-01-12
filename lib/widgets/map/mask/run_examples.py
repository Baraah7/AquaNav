#!/usr/bin/env python3
"""
Complete Example & Testing Script
Demonstrates all features of the coastline & land/water mask system
"""

import sys
import os
from typing import List, Tuple


def print_header(title: str):
    """Print formatted section header."""
    print("\n" + "="*70)
    print(f"  {title}")
    print("="*70 + "\n")


def example_1_generate_mask():
    """Example 1: Generate land/water mask from scratch."""
    print_header("EXAMPLE 1: Generate Coastline Mask")
    
    from coastline_processor import CoastlineMaskPipeline
    
    # Define Bahrain maritime region
    BAHRAIN_BBOX = (
        50.35,   # min_longitude (west)
        25.85,   # min_latitude (south)
        50.85,   # max_longitude (east)
        26.35    # max_latitude (north)
    )
    
    print("Configuration:")
    print(f"  Region: Bahrain Gulf waters")
    print(f"  Bounding box: {BAHRAIN_BBOX}")
    print(f"  Resolution: 0.001° (~111 meters)")
    print(f"  Expected grid: ~500x500 pixels\n")
    
    # Initialize pipeline
    pipeline = CoastlineMaskPipeline(
        bbox=BAHRAIN_BBOX,
        resolution=0.001
    )
    
    # Run complete pipeline
    print("Starting pipeline execution...")
    pipeline.run_pipeline(output_prefix="bahrain_navigation_mask")
    
    print("\n✓ Example 1 complete: Mask files generated")
    return True


def example_2_load_and_query():
    """Example 2: Load mask and perform navigability queries."""
    print_header("EXAMPLE 2: Load Mask & Query Points")
    
    from routing_integration import NavigationMaskHandler
    
    # Check if mask exists
    if not os.path.exists("bahrain_navigation_mask.npz"):
        print("⚠ Mask not found. Run Example 1 first.")
        return False
    
    # Load mask
    print("Loading navigation mask...")
    mask = NavigationMaskHandler("bahrain_navigation_mask.npz")
    
    # Get statistics
    stats = mask.get_navigable_area_stats()
    print(f"\nMask Statistics:")
    print(f"  Total area: {stats['water_area_km2'] + stats['land_area_km2']:.2f} km²")
    print(f"  Water (navigable): {stats['water_area_km2']:.2f} km² ({stats['water_percentage']:.1f}%)")
    print(f"  Land (blocked): {stats['land_area_km2']:.2f} km²")
    print(f"  Grid cells: {stats['water_cells']:,} water, {stats['land_cells']:,} land")
    
    # Test specific points
    test_points = [
        (50.6, 26.2, "Open Gulf waters"),
        (50.58, 26.23, "Near Bahrain coast"),
        (50.45, 26.0, "Southern waters"),
        (50.60, 26.28, "Near Muharraq"),
        (50.55, 26.15, "Central channel"),
    ]
    
    print(f"\nTesting {len(test_points)} locations:")
    for lon, lat, name in test_points:
        is_nav = mask.is_navigable(lon, lat)
        status = "✓ NAVIGABLE (water)" if is_nav else "✗ BLOCKED (land)"
        print(f"  {name:20} ({lon:.3f}, {lat:.3f}): {status}")
    
    # Test nearest water finding
    print("\nTesting nearest water search:")
    land_point = (50.58, 26.23)  # Likely on land
    if not mask.is_navigable(land_point[0], land_point[1]):
        nearest = mask.find_nearest_water(land_point[0], land_point[1])
        if nearest:
            distance_deg = ((nearest[0] - land_point[0])**2 + 
                          (nearest[1] - land_point[1])**2)**0.5
            distance_km = distance_deg * 111
            print(f"  Land point: {land_point}")
            print(f"  Nearest water: {nearest}")
            print(f"  Distance: ~{distance_km:.2f} km")
    
    print("\n✓ Example 2 complete: Query operations successful")
    return True


def example_3_route_planning():
    """Example 3: Plan maritime routes avoiding land."""
    print_header("EXAMPLE 3: Maritime Route Planning")
    
    from routing_integration import NavigationMaskHandler, RoutePlanner
    
    # Check if mask exists
    if not os.path.exists("bahrain_navigation_mask.npz"):
        print("⚠ Mask not found. Run Example 1 first.")
        return False
    
    # Load mask and create planner
    print("Initializing route planner...")
    mask = NavigationMaskHandler("bahrain_navigation_mask.npz")
    planner = RoutePlanner(mask)
    
    # Define test routes
    routes_to_test = [
        {
            'name': 'South to North Gulf crossing',
            'start': (50.45, 26.0),
            'end': (50.65, 26.25)
        },
        {
            'name': 'Coastal route along Bahrain',
            'start': (50.50, 26.05),
            'end': (50.62, 26.20)
        },
        {
            'name': 'Eastern channel navigation',
            'start': (50.70, 26.10),
            'end': (50.75, 26.25)
        }
    ]
    
    successful_routes = []
    
    for i, route_spec in enumerate(routes_to_test, 1):
        print(f"\n[Route {i}] {route_spec['name']}")
        print(f"  Start: {route_spec['start']}")
        print(f"  End: {route_spec['end']}")
        
        route = planner.plan_route(route_spec['start'], route_spec['end'])
        
        if route:
            # Calculate route length
            total_distance = 0
            for j in range(len(route) - 1):
                dx = route[j+1][0] - route[j][0]
                dy = route[j+1][1] - route[j][1]
                total_distance += (dx**2 + dy**2)**0.5
            
            distance_km = total_distance * 111
            
            print(f"  ✓ Route found!")
            print(f"  Waypoints: {len(route)}")
            print(f"  Distance: ~{distance_km:.2f} km")
            
            # Validate route doesn't cross land
            is_valid, invalid_segments = mask.is_route_navigable(route, sample_points=20)
            if is_valid:
                print(f"  ✓ Route validated: No land crossings")
            else:
                print(f"  ⚠ Warning: {len(invalid_segments)} segments may cross land")
            
            successful_routes.append((route_spec['name'], route))
        else:
            print(f"  ✗ No route found (may be blocked by land)")
    
    print(f"\n✓ Example 3 complete: {len(successful_routes)}/{len(routes_to_test)} routes planned")
    return successful_routes


def example_4_visualization():
    """Example 4: Generate visualizations."""
    print_header("EXAMPLE 4: Generate Visualizations")
    
    from mask_visualizer import MaskVisualizer
    
    # Check if mask exists
    if not os.path.exists("bahrain_navigation_mask.npz"):
        print("⚠ Mask not found. Run Example 1 first.")
        return False
    
    print("Creating mask visualizer...")
    viz = MaskVisualizer(
        "bahrain_navigation_mask.npz",
        "bahrain_navigation_mask_metadata.json"
    )
    
    # Generate basic mask visualization
    print("\n[1/3] Generating basic mask visualization...")
    viz.plot_mask(
        output_path="mask_visualization.png",
        show_grid=True
    )
    print("  ✓ Saved: mask_visualization.png")
    
    # Generate validation report
    print("\n[2/3] Generating validation report...")
    viz.plot_validation_report(output_path="validation_report.png")
    print("  ✓ Saved: validation_report.png")
    
    # Generate route visualization (if routes exist)
    print("\n[3/3] Generating route visualization...")
    from routing_integration import NavigationMaskHandler, RoutePlanner
    
    mask = NavigationMaskHandler("bahrain_navigation_mask.npz")
    planner = RoutePlanner(mask)
    
    # Plan a sample route
    route = planner.plan_route(
        start=(50.45, 26.0),
        end=(50.65, 26.25)
    )
    
    if route:
        viz.plot_route_on_mask(
            route=route,
            output_path="route_visualization.png"
        )
        print("  ✓ Saved: route_visualization.png")
    else:
        print("  ⚠ Could not generate route visualization (no route found)")
    
    print("\n✓ Example 4 complete: Visualizations generated")
    print("\nGenerated files:")
    print("  • mask_visualization.png - Binary land/water mask")
    print("  • validation_report.png - Comprehensive validation report")
    if route:
        print("  • route_visualization.png - Sample route on mask")
    
    return True


def example_5_flutter_integration():
    """Example 5: Show Flutter/Dart integration code."""
    print_header("EXAMPLE 5: Flutter/Dart Integration Guide")
    
    flutter_code = '''
// Add to pubspec.yaml assets:
//   - assets/navigation/bahrain_navigation_mask.bin
//   - assets/navigation/mask_metadata.json

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:convert';

class NavigationMask {
  late Uint8List mask;
  late int width, height;
  late double minLon, minLat, maxLon, maxLat, resolution;
  
  // Load mask from assets
  Future<void> loadMask() async {
    // Load metadata
    String metadataJson = await rootBundle.loadString(
      'assets/navigation/mask_metadata.json'
    );
    Map<String, dynamic> metadata = json.decode(metadataJson);
    
    width = metadata['grid']['width'];
    height = metadata['grid']['height'];
    minLon = metadata['bbox']['min_lon'];
    minLat = metadata['bbox']['min_lat'];
    maxLon = metadata['bbox']['max_lon'];
    maxLat = metadata['bbox']['max_lat'];
    resolution = metadata['grid']['resolution_degrees'];
    
    // Load binary mask
    ByteData data = await rootBundle.load(
      'assets/navigation/bahrain_navigation_mask.bin'
    );
    mask = data.buffer.asUint8List();
    
    print('Navigation mask loaded: ${width}x$height');
  }
  
  // Check if coordinate is navigable
  bool isNavigable(double lon, double lat) {
    // Convert to grid coordinates
    int col = ((lon - minLon) / (maxLon - minLon) * width).floor();
    int row = ((maxLat - lat) / (maxLat - minLat) * height).floor();
    
    // Clamp to valid range
    col = col.clamp(0, width - 1);
    row = row.clamp(0, height - 1);
    
    // Check mask value (1 = water, 0 = land)
    return mask[row * width + col] == 1;
  }
  
  // Validate fishing spot coordinates
  bool validateFishingSpot(double lon, double lat) {
    if (!isNavigable(lon, lat)) {
      print('Warning: Fishing spot is on land!');
      return false;
    }
    return true;
  }
  
  // Find nearest navigable point
  (double, double)? findNearestWater(double lon, double lat, {int maxRadius = 50}) {
    int startCol = ((lon - minLon) / (maxLon - minLon) * width).floor();
    int startRow = ((maxLat - lat) / (maxLat - minLat) * height).floor();
    
    // Already in water
    if (mask[startRow * width + startCol] == 1) {
      return (lon, lat);
    }
    
    // Spiral search
    for (int radius = 1; radius <= maxRadius; radius++) {
      for (int dr = -radius; dr <= radius; dr++) {
        for (int dc = -radius; dc <= radius; dc++) {
          if (dr.abs() != radius && dc.abs() != radius) continue;
          
          int row = startRow + dr;
          int col = startCol + dc;
          
          if (row >= 0 && row < height && col >= 0 && col < width) {
            if (mask[row * width + col] == 1) {
              double nearLon = minLon + (col + 0.5) * resolution;
              double nearLat = maxLat - (row + 0.5) * resolution;
              return (nearLon, nearLat);
            }
          }
        }
      }
    }
    
    return null; // No water found
  }
}

// Usage in Bahaar app:
final navigationMask = NavigationMask();

Future<void> initializeNavigation() async {
  await navigationMask.loadMask();
  print('Navigation system ready');
}

void onFishingSpotSelected(double lon, double lat) {
  if (navigationMask.isNavigable(lon, lat)) {
    // Proceed with route planning
    planRoute(currentLocation, (lon, lat));
  } else {
    // Find nearest water and suggest correction
    var nearest = navigationMask.findNearestWater(lon, lat);
    if (nearest != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Fishing Spot on Land'),
          content: Text('Did you mean: ${nearest.$1}, ${nearest.$2}?'),
        ),
      );
    }
  }
}
    '''
    
    print("Flutter/Dart integration code:")
    print("-" * 70)
    print(flutter_code)
    print("-" * 70)
    
    print("\nSteps to integrate:")
    print("  1. Convert .npz to .bin format:")
    print("     import numpy as np")
    print("     mask = np.load('bahrain_navigation_mask.npz')['mask']")
    print("     mask.tofile('bahrain_navigation_mask.bin')")
    print("  2. Copy .bin and metadata.json to Flutter assets/")
    print("  3. Add to pubspec.yaml under assets:")
    print("  4. Use NavigationMask class in your app")
    
    print("\n✓ Example 5 complete: Integration guide provided")
    return True


def run_all_examples():
    """Run all examples in sequence."""
    print_header("COASTLINE & LAND/WATER MASK - COMPLETE EXAMPLES")
    
    print("This script demonstrates all features of the system:")
    print("  1. Generate coastline mask from OpenStreetMap")
    print("  2. Load and query navigation mask")
    print("  3. Plan maritime routes avoiding land")
    print("  4. Generate visualizations")
    print("  5. Show Flutter integration")
    
    input("\nPress Enter to start examples...")
    
    results = {}
    
    # Example 1: Generate mask
    try:
        results['generate'] = example_1_generate_mask()
    except Exception as e:
        print(f"\n✗ Example 1 failed: {e}")
        results['generate'] = False
    
    # Example 2: Load and query
    try:
        results['query'] = example_2_load_and_query()
    except Exception as e:
        print(f"\n✗ Example 2 failed: {e}")
        results['query'] = False
    
    # Example 3: Route planning
    try:
        results['routing'] = example_3_route_planning()
    except Exception as e:
        print(f"\n✗ Example 3 failed: {e}")
        results['routing'] = False
    
    # Example 4: Visualization
    try:
        results['visualization'] = example_4_visualization()
    except Exception as e:
        print(f"\n✗ Example 4 failed: {e}")
        results['visualization'] = False
    
    # Example 5: Flutter integration
    try:
        results['flutter'] = example_5_flutter_integration()
    except Exception as e:
        print(f"\n✗ Example 5 failed: {e}")
        results['flutter'] = False
    
    # Final summary
    print_header("EXAMPLES COMPLETE - SUMMARY")
    
    success_count = sum(1 for v in results.values() if v)
    total_count = len(results)
    
    print(f"Completed: {success_count}/{total_count} examples")
    print("\nResults:")
    for name, success in results.items():
        status = "✓ SUCCESS" if success else "✗ FAILED"
        print(f"  {name:15} {status}")
    
    print("\nGenerated files:")
    files = [
        "bahrain_navigation_mask.tif",
        "bahrain_navigation_mask.npz",
        "bahrain_navigation_mask_metadata.json",
        "bahrain_navigation_mask_land.geojson",
        "bahrain_navigation_mask_water.geojson",
        "mask_visualization.png",
        "validation_report.png",
        "route_visualization.png"
    ]
    
    for filename in files:
        if os.path.exists(filename):
            size_kb = os.path.getsize(filename) / 1024
            print(f"  ✓ {filename:40} ({size_kb:.1f} KB)")
    
    print("\nReady for integration with Bahaar fishing app! 🎣")


if __name__ == "__main__":
    run_all_examples()
