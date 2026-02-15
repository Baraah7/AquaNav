import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/services/fishing_activity_service.dart';
import 'package:Bahaar/models/fishing/fishing_activity_model.dart';

/// Renders fishing activity data on the map: vessel tracks, fishing events,
/// and intensity heatmap at low zoom levels.
class FishingActivityLayer extends StatelessWidget {
  final FishingActivityService service;
  final double currentZoom;
  final bool showTracks;
  final bool showEvents;
  final bool showHeatmap;

  const FishingActivityLayer({
    super.key,
    required this.service,
    required this.currentZoom,
    this.showTracks = true,
    this.showEvents = true,
    this.showHeatmap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!service.isInitialized) return const SizedBox.shrink();

    return Stack(
      children: [
        // Heatmap cells at low zoom
        if (showHeatmap && currentZoom < 10)
          PolygonLayer(polygons: _buildHeatmapCells()),

        // Vessel tracks as polylines
        if (showTracks && currentZoom >= 8)
          PolylineLayer(polylines: _buildTrackPolylines()),

        // Fishing events as clustered markers
        if (showEvents)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: currentZoom < 12 ? 80 : 40,
              disableClusteringAtZoom: 15,
              markers: _buildEventMarkers(),
              builder: (context, markers) =>
                  _buildClusterIcon(markers.length),
            ),
          ),
      ],
    );
  }

  List<Polyline> _buildTrackPolylines() {
    final tracks = service.getTracksForZoom(currentZoom);
    return tracks.map((track) {
      final points =
          track.positions.map((p) => LatLng(p.latitude, p.longitude)).toList();
      if (points.length < 2) return null;
      return Polyline(
        points: points,
        strokeWidth: 2.5,
        color: _colorForGearType(track.gearType),
      );
    }).whereType<Polyline>().toList();
  }

  List<Marker> _buildEventMarkers() {
    return service.events.map((event) {
      return Marker(
        point: LatLng(event.latitude, event.longitude),
        width: 30,
        height: 30,
        child: Tooltip(
          message: '${event.vesselName}\n'
              '${_eventTypeLabel(event.eventType)}\n'
              '${event.durationHours?.toStringAsFixed(1) ?? "?"} hrs',
          child: Icon(
            _iconForEventType(event.eventType),
            color: _colorForEventType(event.eventType),
            size: 22,
          ),
        ),
      );
    }).toList();
  }

  List<Polygon> _buildHeatmapCells() {
    const halfRes = 0.025; // half of 0.05 degree resolution
    return service.intensityCells.map((cell) {
      return Polygon(
        points: [
          LatLng(cell.latitude - halfRes, cell.longitude - halfRes),
          LatLng(cell.latitude - halfRes, cell.longitude + halfRes),
          LatLng(cell.latitude + halfRes, cell.longitude + halfRes),
          LatLng(cell.latitude + halfRes, cell.longitude - halfRes),
        ],
        color: _heatmapColor(cell.level),
        borderStrokeWidth: 0,
        borderColor: Colors.transparent,
      );
    }).toList();
  }

  Widget _buildClusterIcon(int count) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _eventTypeLabel(FishingEventType type) {
    switch (type) {
      case FishingEventType.fishing:
        return 'Fishing';
      case FishingEventType.portVisit:
        return 'Port Visit';
      case FishingEventType.encounter:
        return 'Encounter';
      case FishingEventType.loitering:
        return 'Loitering';
      case FishingEventType.transshipment:
        return 'Transshipment';
    }
  }

  Color _colorForGearType(String? gearType) {
    switch (gearType) {
      case 'trawler':
        return Colors.red;
      case 'longline':
        return Colors.blue;
      case 'purse_seine':
        return Colors.purple;
      case 'traditional_trap':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  IconData _iconForEventType(FishingEventType type) {
    switch (type) {
      case FishingEventType.fishing:
        return Icons.phishing;
      case FishingEventType.portVisit:
        return Icons.anchor;
      case FishingEventType.encounter:
        return Icons.swap_horiz;
      case FishingEventType.loitering:
        return Icons.pause_circle;
      case FishingEventType.transshipment:
        return Icons.swap_calls;
    }
  }

  Color _colorForEventType(FishingEventType type) {
    switch (type) {
      case FishingEventType.fishing:
        return Colors.deepOrange;
      case FishingEventType.portVisit:
        return Colors.blue;
      case FishingEventType.encounter:
        return Colors.amber;
      case FishingEventType.loitering:
        return Colors.grey;
      case FishingEventType.transshipment:
        return Colors.red;
    }
  }

  Color _heatmapColor(FishingIntensityLevel level) {
    switch (level) {
      case FishingIntensityLevel.low:
        return Colors.yellow.withValues(alpha: 0.15);
      case FishingIntensityLevel.moderate:
        return Colors.orange.withValues(alpha: 0.25);
      case FishingIntensityLevel.high:
        return Colors.deepOrange.withValues(alpha: 0.35);
      case FishingIntensityLevel.veryHigh:
        return Colors.red.withValues(alpha: 0.45);
    }
  }
}
