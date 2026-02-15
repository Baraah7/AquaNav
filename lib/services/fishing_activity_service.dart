import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/fishing/fishing_activity_model.dart';
import 'package:Bahaar/utilities/geometry_utils.dart';

/// Service for fetching and managing fishing activity data.
/// Tries Global Fishing Watch API first, falls back to bundled sample data.
class FishingActivityService {
  final http.Client _client;

  // Bahrain bounding box
  static const double _minLat = 25.5;
  static const double _maxLat = 27.0;
  static const double _minLon = 49.5;
  static const double _maxLon = 51.0;

  // GFW API
  static const String _gfwBaseUrl =
      'https://gateway.api.globalfishingwatch.org/v3';
  String? _gfwApiToken;

  // Cached data
  List<VesselTrack> _tracks = [];
  List<FishingEvent> _events = [];
  List<FishingIntensityCell> _intensityCells = [];
  final Map<double, List<VesselTrack>> _simplifiedTrackCache = {};

  bool _isInitialized = false;
  bool _usingFallback = false;

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get usingFallback => _usingFallback;
  List<VesselTrack> get tracks => _tracks;
  List<FishingEvent> get events => _events;
  List<FishingIntensityCell> get intensityCells => _intensityCells;

  FishingActivityService({http.Client? client})
      : _client = client ?? http.Client();

  /// Initialize: try GFW API first, fall back to sample data.
  Future<void> initialize() async {
    try {
      _gfwApiToken = dotenv.env['GFW_API_TOKEN'];
      if (_gfwApiToken != null && _gfwApiToken!.isNotEmpty) {
        await _fetchFromGfwApi();
      } else {
        throw Exception('No GFW API token configured');
      }
    } catch (e) {
      log('GFW API unavailable, loading sample data: $e');
      await _loadFallbackData();
      _usingFallback = true;
    }

    // Pre-compute intensity grid for heatmap
    _intensityCells = GeometryUtils.aggregateToGrid(_events, 0.05);

    _isInitialized = true;
    log('Fishing activity service initialized: '
        '${_tracks.length} tracks, ${_events.length} events '
        '(fallback: $_usingFallback)');
  }

  /// Get tracks simplified for the current zoom level.
  List<VesselTrack> getTracksForZoom(double zoom) {
    double tolerance;
    if (zoom >= 14) {
      tolerance = 0.0001; // ~10m, nearly full detail
    } else if (zoom >= 12) {
      tolerance = 0.001; // ~100m
    } else if (zoom >= 10) {
      tolerance = 0.005; // ~500m
    } else {
      tolerance = 0.01; // ~1km, very simplified
    }

    return _simplifiedTrackCache.putIfAbsent(tolerance, () {
      return _tracks.map((track) {
        final simplifiedPositions = _simplifyPositions(track.positions, tolerance);
        return track.copyWith(positions: simplifiedPositions);
      }).toList();
    });
  }

  /// Get events visible in the current viewport.
  List<FishingEvent> getEventsInBounds(LatLng sw, LatLng ne) {
    return _events
        .where((e) => GeometryUtils.isInBounds(e.latLng, sw, ne))
        .toList();
  }

  /// Simplify positions using Douglas-Peucker on their LatLng coordinates.
  List<VesselPosition> _simplifyPositions(
      List<VesselPosition> positions, double tolerance) {
    if (positions.length <= 2) return positions;

    final latLngs = positions.map((p) => p.latLng).toList();
    final simplified = GeometryUtils.simplifyTrack(latLngs, tolerance);

    // Map back to VesselPositions by matching coordinates
    final result = <VesselPosition>[];
    int searchFrom = 0;
    for (final point in simplified) {
      for (int i = searchFrom; i < positions.length; i++) {
        if (positions[i].latitude == point.latitude &&
            positions[i].longitude == point.longitude) {
          result.add(positions[i]);
          searchFrom = i + 1;
          break;
        }
      }
    }
    return result.isNotEmpty ? result : positions;
  }

  /// Fetch fishing activity data from Global Fishing Watch API.
  Future<void> _fetchFromGfwApi() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final startStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Fetch fishing events in the Bahrain bounding box
    final eventsUrl = Uri.parse(
      '$_gfwBaseUrl/events?datasets[0]=public-global-fishing-events:latest'
      '&start-date=$startStr&end-date=$endStr'
      '&geometry={"type":"Polygon","coordinates":[['
      '[$_minLon,$_minLat],[$_maxLon,$_minLat],'
      '[$_maxLon,$_maxLat],[$_minLon,$_maxLat],'
      '[$_minLon,$_minLat]]]}'
      '&limit=100',
    );

    final eventsResponse = await _client.get(
      eventsUrl,
      headers: {
        'Authorization': 'Bearer $_gfwApiToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    if (eventsResponse.statusCode != 200) {
      throw Exception(
          'GFW events API returned ${eventsResponse.statusCode}');
    }

    final eventsJson = jsonDecode(eventsResponse.body);
    final entries = eventsJson['entries'] as List<dynamic>? ?? [];

    // Group events by vessel
    final Map<String, List<FishingEvent>> vesselEvents = {};
    for (final entry in entries) {
      final vesselId = entry['vessel']?['id']?.toString() ?? 'unknown';
      final vesselName =
          entry['vessel']?['name']?.toString() ?? 'Unknown Vessel';
      final position = entry['position'];
      if (position == null) continue;

      final event = FishingEvent(
        id: entry['id']?.toString() ?? '',
        vesselId: vesselId,
        vesselName: vesselName,
        eventType: _mapGfwEventType(entry['type']?.toString() ?? ''),
        latitude: (position['lat'] as num?)?.toDouble() ?? 0,
        longitude: (position['lon'] as num?)?.toDouble() ?? 0,
        startTime: DateTime.tryParse(entry['start']?.toString() ?? '') ??
            DateTime.now(),
        endTime: DateTime.tryParse(entry['end']?.toString() ?? '') ??
            DateTime.now(),
        durationHours: (entry['durationHrs'] as num?)?.toDouble(),
      );

      vesselEvents.putIfAbsent(vesselId, () => []).add(event);
      _events.add(event);
    }

    // Create tracks from vessel events (simplified - just event positions)
    for (final entry in vesselEvents.entries) {
      final events = entry.value;
      if (events.isEmpty) continue;
      final positions = events
          .map((e) => VesselPosition(
                latitude: e.latitude,
                longitude: e.longitude,
                timestamp: e.startTime,
              ))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _tracks.add(VesselTrack(
        vesselId: entry.key,
        vesselName: events.first.vesselName,
        positions: positions,
        events: events,
      ));
    }
  }

  FishingEventType _mapGfwEventType(String gfwType) {
    switch (gfwType.toLowerCase()) {
      case 'fishing':
        return FishingEventType.fishing;
      case 'port_visit':
        return FishingEventType.portVisit;
      case 'encounter':
        return FishingEventType.encounter;
      case 'loitering':
        return FishingEventType.loitering;
      default:
        return FishingEventType.fishing;
    }
  }

  /// Load bundled sample data as fallback.
  Future<void> _loadFallbackData() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/data/fishing_activity_sample.geojson');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final tracksJson = data['tracks'] as List<dynamic>? ?? [];

      for (final trackJson in tracksJson) {
        final track =
            VesselTrack.fromJson(trackJson as Map<String, dynamic>);
        _tracks.add(track);
        _events.addAll(track.events);
      }
    } catch (e) {
      log('Error loading fallback fishing data: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
