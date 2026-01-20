import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/models/navigation/route_model.dart';

/// Widget for displaying navigation route as colored polylines
///
/// Features:
/// - Color-coded segments (blue=land, cyan=marine)
/// - Active segment highlighting
/// - White border for visibility
/// - Segment transition markers
class RoutePolylineLayer extends StatelessWidget {
  final NavigationRoute route;
  final int? activeSegmentIndex;
  final bool showMarkers;

  const RoutePolylineLayer({
    super.key,
    required this.route,
    this.activeSegmentIndex,
    this.showMarkers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Draw all route segments
        ...route.segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isActive = activeSegmentIndex == index;

          return PolylineLayer(
            polylines: [
              // White border for contrast
              Polyline(
                points: segment.geometry,
                strokeWidth: isActive ? 10.0 : 6.0,
                color: Colors.white,
              ),
              // Colored segment line
              Polyline(
                points: segment.geometry,
                strokeWidth: isActive ? 7.0 : 4.0,
                color: _getSegmentColor(segment.type),
                borderStrokeWidth: isActive ? 2.0 : 0.0,
                borderColor: Colors.white,
              ),
            ],
          );
        }),

        // Marina transition markers
        if (showMarkers)
          MarkerLayer(
            markers: _buildTransitionMarkers(),
          ),

        // Start and end markers
        if (showMarkers)
          MarkerLayer(
            markers: [
              // Start marker
              Marker(
                point: route.origin,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // End marker
              Marker(
                point: route.destination,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Get color for segment type
  Color _getSegmentColor(SegmentType type) {
    switch (type) {
      case SegmentType.land:
        return Colors.blue.withValues(alpha: 0.9);
      case SegmentType.marine:
        return Colors.cyan.withValues(alpha: 0.9);
    }
  }

  /// Build markers for segment transitions (marina handoffs)
  List<Marker> _buildTransitionMarkers() {
    final markers = <Marker>[];

    for (int i = 0; i < route.segments.length - 1; i++) {
      final currentSegment = route.segments[i];
      final nextSegment = route.segments[i + 1];

      // Check if this is a land-marine transition
      final isTransition = currentSegment.type != nextSegment.type;

      if (isTransition) {
        final transitionPoint = currentSegment.geometry.last;
        final marina = currentSegment.exitMarina ?? nextSegment.entryMarina;

        markers.add(
          Marker(
            point: transitionPoint,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentSegment.type == SegmentType.land
                        ? Icons.directions_boat
                        : Icons.directions_car,
                    color: Colors.white,
                    size: 20,
                  ),
                  if (marina != null)
                    Text(
                      marina.name.length > 10
                          ? '${marina.name.substring(0, 10)}...'
                          : marina.name,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }
}

/// Route summary statistics widget
class RouteStatsCard extends StatelessWidget {
  final NavigationRoute route;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onCancel;

  const RouteStatsCard({
    super.key,
    required this.route,
    this.onStartNavigation,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                route.isHybrid ? Icons.compare_arrows : Icons.navigation,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                route.isHybrid ? 'Hybrid Route' : 'Direct Route',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Distance and duration
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: _formatDistance(route.totalDistance),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _formatDuration(route.estimatedDuration),
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          // Hybrid route breakdown
          if (route.isHybrid) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSegmentStat(
                    icon: Icons.directions_car,
                    label: 'Land',
                    distance: route.metrics.landDistance,
                    duration: route.metrics.landDuration,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSegmentStat(
                    icon: Icons.directions_boat,
                    label: 'Marine',
                    distance: route.metrics.marineDistance,
                    duration: route.metrics.marineDuration,
                    color: Colors.cyan,
                  ),
                ),
              ],
            ),
          ],

          // Validation warnings
          if (!route.validation.isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route crosses ${route.validation.landPoints} restricted points',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Start navigation button
          if (onStartNavigation != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartNavigation,
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentStat({
    required IconData icon,
    required String label,
    required double distance,
    required int duration,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatDistance(distance),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}
