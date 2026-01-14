import 'package:flutter/material.dart';
import 'package:Bahaar/models/navigation/navigation_session_model.dart';
import 'package:Bahaar/models/navigation/waypoint_model.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

/// Active navigation overlay showing turn-by-turn instructions and progress
///
/// Features:
/// - Top instruction card with next waypoint
/// - Bottom progress card with metrics
/// - Recalculating indicator
/// - End navigation button
class ActiveNavigationOverlay extends StatelessWidget {
  final NavigationSession session;
  final VoidCallback? onEndNavigation;
  final VoidCallback? onRecenter;
  final bool isRecalculating;

  const ActiveNavigationOverlay({
    super.key,
    required this.session,
    this.onEndNavigation,
    this.onRecenter,
    this.isRecalculating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top instruction card
        Positioned(
          top: 60,
          left: 16,
          right: 16,
          child: _buildInstructionCard(context),
        ),

        // Bottom progress card
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildProgressCard(context),
        ),

        // Recenter button (right side)
        if (onRecenter != null)
          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter_nav',
              onPressed: onRecenter,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

        // Recalculating overlay
        if (isRecalculating)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Recalculating route...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build the instruction card showing next waypoint
  Widget _buildInstructionCard(BuildContext context) {
    final nextWaypoint = session.nextWaypoint;

    if (nextWaypoint == null) {
      return _buildArrivalCard();
    }

    final distanceToWaypoint = _calculateDistanceToWaypoint(nextWaypoint);
    final icon = _getWaypointIcon(nextWaypoint.type);
    final color = _getSegmentColor(nextWaypoint.segmentType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Instruction and distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDistance(distanceToWaypoint),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextWaypoint.instruction ?? 'Continue',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // End navigation button
          if (onEndNavigation != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onEndNavigation,
              tooltip: 'End Navigation',
            ),
        ],
      ),
    );
  }

  /// Build arrival card when nearing destination
  Widget _buildArrivalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.flag,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arriving',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have reached your destination',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (onEndNavigation != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onEndNavigation,
            ),
        ],
      ),
    );
  }

  /// Build the progress card showing navigation metrics
  Widget _buildProgressCard(BuildContext context) {
    final progress = session.progressPercentage;
    final distanceRemaining = session.distanceRemaining;
    final timeRemaining = session.timeRemaining;
    final currentSpeed = session.currentSpeed ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: _formatDistance(distanceRemaining),
                color: Colors.blue,
              ),
              _buildMetricItem(
                icon: Icons.access_time,
                label: 'ETA',
                value: _formatDuration(timeRemaining),
                color: Colors.orange,
              ),
              _buildMetricItem(
                icon: Icons.speed,
                label: 'Speed',
                value: NavigationConstants.formatSpeed(currentSpeed),
                color: Colors.green,
              ),
            ],
          ),

          // Marina transition indicator
          if (session.isNearingTransition) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_boat, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Marina transition ahead',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  double _calculateDistanceToWaypoint(Waypoint waypoint) {
    if (session.currentLocation == null) {
      return waypoint.distanceFromStart - session.metrics.distanceTraveled;
    }
    // Approximate - actual distance would need haversine calculation
    return (waypoint.distanceFromStart - session.metrics.distanceTraveled).clamp(0, double.infinity);
  }

  IconData _getWaypointIcon(WaypointType type) {
    switch (type) {
      case WaypointType.start:
        return Icons.play_arrow;
      case WaypointType.end:
        return Icons.flag;
      case WaypointType.turn:
        return Icons.turn_right;
      case WaypointType.marinaEntry:
        return Icons.directions_boat;
      case WaypointType.marinaExit:
        return Icons.directions_car;
      case WaypointType.intermediate:
        return Icons.navigation;
    }
  }

  Color _getSegmentColor(RouteSegmentType type) {
    switch (type) {
      case RouteSegmentType.land:
        return Colors.blue;
      case RouteSegmentType.marine:
        return Colors.cyan;
      case RouteSegmentType.transition:
        return Colors.orange;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 25) return Colors.red;
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.blue;
    return Colors.green;
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
