import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/fishing/fishing_activity_model.dart';

/// Geometry utilities for track simplification and spatial aggregation
class GeometryUtils {
  GeometryUtils._();

  /// Douglas-Peucker line simplification algorithm.
  /// [tolerance] is in degrees (~0.001 ≈ 100m at Bahrain latitude).
  static List<LatLng> simplifyTrack(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return List.of(points);

    // Find the point with the maximum distance from the start-end line
    double maxDist = 0;
    int maxIndex = 0;
    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final dist = _perpendicularDistance(points[i], start, end);
      if (dist > maxDist) {
        maxDist = dist;
        maxIndex = i;
      }
    }

    // If max distance exceeds tolerance, recursively simplify
    if (maxDist > tolerance) {
      final left = simplifyTrack(points.sublist(0, maxIndex + 1), tolerance);
      final right = simplifyTrack(points.sublist(maxIndex), tolerance);
      // Combine, removing the duplicate point at the junction
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  /// Perpendicular distance from a point to a line segment (in degrees).
  static double _perpendicularDistance(
      LatLng point, LatLng lineStart, LatLng lineEnd) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;

    if (dx == 0 && dy == 0) {
      // Start and end are the same point
      final px = point.longitude - lineStart.longitude;
      final py = point.latitude - lineStart.latitude;
      return sqrt(px * px + py * py);
    }

    // Normalized distance along the line
    final t = ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    final nearestLon = lineStart.longitude + clampedT * dx;
    final nearestLat = lineStart.latitude + clampedT * dy;

    final px = point.longitude - nearestLon;
    final py = point.latitude - nearestLat;
    return sqrt(px * px + py * py);
  }

  /// Check if a point is within a bounding box.
  static bool isInBounds(LatLng point, LatLng sw, LatLng ne) {
    return point.latitude >= sw.latitude &&
        point.latitude <= ne.latitude &&
        point.longitude >= sw.longitude &&
        point.longitude <= ne.longitude;
  }

  /// Aggregate fishing events into grid cells for heatmap visualization.
  /// [resolution] is the cell size in degrees.
  static List<FishingIntensityCell> aggregateToGrid(
    List<FishingEvent> events,
    double resolution,
  ) {
    if (events.isEmpty) return [];

    // Group events by grid cell
    final Map<(int, int), List<FishingEvent>> grid = {};
    for (final event in events) {
      final row = (event.latitude / resolution).floor();
      final col = (event.longitude / resolution).floor();
      grid.putIfAbsent((row, col), () => []).add(event);
    }

    // Convert to intensity cells
    return grid.entries.map((entry) {
      final (row, col) = entry.key;
      final cellEvents = entry.value;
      final totalHours = cellEvents.fold<double>(
        0.0,
        (sum, e) => sum + (e.durationHours ?? 0),
      );
      final count = cellEvents.length;

      FishingIntensityLevel level;
      if (count >= 8 || totalHours >= 40) {
        level = FishingIntensityLevel.veryHigh;
      } else if (count >= 5 || totalHours >= 20) {
        level = FishingIntensityLevel.high;
      } else if (count >= 3 || totalHours >= 10) {
        level = FishingIntensityLevel.moderate;
      } else {
        level = FishingIntensityLevel.low;
      }

      return FishingIntensityCell(
        latitude: (row + 0.5) * resolution,
        longitude: (col + 0.5) * resolution,
        eventCount: count,
        totalHours: totalHours,
        level: level,
      );
    }).toList();
  }
}
