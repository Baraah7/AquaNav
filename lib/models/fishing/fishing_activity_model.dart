import 'package:latlong2/latlong.dart';

/// Types of fishing-related events
enum FishingEventType {
  fishing,
  portVisit,
  encounter,
  loitering,
  transshipment,
}

/// Intensity levels for aggregated fishing activity
enum FishingIntensityLevel { low, moderate, high, veryHigh }

/// A single vessel position within a track
class VesselPosition {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed; // knots
  final double? course; // degrees

  const VesselPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.course,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory VesselPosition.fromJson(Map<String, dynamic> json) {
    return VesselPosition(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num?)?.toDouble(),
      course: (json['course'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        if (speed != null) 'speed': speed,
        if (course != null) 'course': course,
      };
}

/// A fishing event (e.g., fishing activity, port visit, encounter)
class FishingEvent {
  final String id;
  final String vesselId;
  final String vesselName;
  final FishingEventType eventType;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  final double? durationHours;
  final Map<String, dynamic>? metadata;

  const FishingEvent({
    required this.id,
    required this.vesselId,
    required this.vesselName,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    this.durationHours,
    this.metadata,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory FishingEvent.fromJson(Map<String, dynamic> json) {
    return FishingEvent(
      id: json['id'] as String,
      vesselId: json['vessel_id'] as String,
      vesselName: json['vessel_name'] as String,
      eventType: _parseEventType(json['event_type'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      durationHours: (json['duration_hours'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static FishingEventType _parseEventType(String type) {
    switch (type) {
      case 'fishing':
        return FishingEventType.fishing;
      case 'port_visit':
      case 'portVisit':
        return FishingEventType.portVisit;
      case 'encounter':
        return FishingEventType.encounter;
      case 'loitering':
        return FishingEventType.loitering;
      case 'transshipment':
        return FishingEventType.transshipment;
      default:
        return FishingEventType.fishing;
    }
  }
}

/// A vessel track (sequence of positions with associated events)
class VesselTrack {
  final String vesselId;
  final String vesselName;
  final String? vesselFlag;
  final String? gearType;
  final List<VesselPosition> positions;
  final List<FishingEvent> events;

  const VesselTrack({
    required this.vesselId,
    required this.vesselName,
    this.vesselFlag,
    this.gearType,
    required this.positions,
    this.events = const [],
  });

  VesselTrack copyWith({
    String? vesselId,
    String? vesselName,
    String? vesselFlag,
    String? gearType,
    List<VesselPosition>? positions,
    List<FishingEvent>? events,
  }) {
    return VesselTrack(
      vesselId: vesselId ?? this.vesselId,
      vesselName: vesselName ?? this.vesselName,
      vesselFlag: vesselFlag ?? this.vesselFlag,
      gearType: gearType ?? this.gearType,
      positions: positions ?? this.positions,
      events: events ?? this.events,
    );
  }

  factory VesselTrack.fromJson(Map<String, dynamic> json) {
    return VesselTrack(
      vesselId: json['vessel_id'] as String,
      vesselName: json['vessel_name'] as String,
      vesselFlag: json['vessel_flag'] as String?,
      gearType: json['gear_type'] as String?,
      positions: (json['positions'] as List<dynamic>?)
              ?.map((p) =>
                  VesselPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map(
                  (e) => FishingEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Aggregated fishing intensity for a grid cell (used for heatmap)
class FishingIntensityCell {
  final double latitude;
  final double longitude;
  final int eventCount;
  final double totalHours;
  final FishingIntensityLevel level;

  const FishingIntensityCell({
    required this.latitude,
    required this.longitude,
    required this.eventCount,
    required this.totalHours,
    required this.level,
  });
}
