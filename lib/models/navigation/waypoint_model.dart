import 'package:latlong2/latlong.dart';

// Represents a navigation waypoint along a route
class Waypoint {
  final String id;
  final LatLng location;
  final WaypointType type;
  final double distanceFromStart;
  final double? bearing;
  // Instruction Example: "Turn left", "Launch boat at marina"
  final String? instruction;
  final int? estimatedTime;
  final RouteSegmentType segmentType;

  const Waypoint({
    required this.id,
    required this.location,
    required this.type,
    required this.distanceFromStart,
    this.bearing,
    this.instruction,
    this.estimatedTime,
    required this.segmentType,
  });

  // Create Waypoint from JSON - used when receiving data from API
  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as String,
      location: LatLng(
        json['location']['lat'] as double,
        json['location']['lon'] as double,
      ),
      type: WaypointType.values.byName(json['type'] as String),
      distanceFromStart: json['distance_from_start'] as double,
      bearing: json['bearing'] as double?,
      instruction: json['instruction'] as String?,
      estimatedTime: json['estimated_time'] as int?,
      segmentType: RouteSegmentType.values.byName(json['segment_type'] as String),
    );
  }

  // Convert Waypoint to JSON - used for saving or sending to backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': {
        'lat': location.latitude,
        'lon': location.longitude,
      },
      'type': type.name,
      'distance_from_start': distanceFromStart,
      if (bearing != null) 'bearing': bearing,
      if (instruction != null) 'instruction': instruction,
      if (estimatedTime != null) 'estimated_time': estimatedTime,
      'segment_type': segmentType.name,
    };
  }

  // Create a copy with modified fields
  Waypoint copyWith({
    String? id,
    LatLng? location,
    WaypointType? type,
    double? distanceFromStart,
    double? bearing,
    String? instruction,
    int? estimatedTime,
    RouteSegmentType? segmentType,
  }) {
    return Waypoint(
      id: id ?? this.id,
      location: location ?? this.location,
      type: type ?? this.type,
      distanceFromStart: distanceFromStart ?? this.distanceFromStart,
      bearing: bearing ?? this.bearing,
      instruction: instruction ?? this.instruction,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      segmentType: segmentType ?? this.segmentType,
    );
  }

  // Used for debugging 
  @override
  String toString() {
    return 'Waypoint(id: $id, type: ${type.displayName}, instruction: $instruction)';
  }
  
  // Equality override - two waypoints are considered equal if they share same ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Waypoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Types of waypoints in a navigation route
enum WaypointType {
  start('Start', 'Begin navigation'),
  end('End', 'Destination reached'),
  turn('Turn', 'Direction change'),
  marinaEntry('Marina Entry', 'Launch boat at marina'),
  marinaExit('Marina Exit', 'Dock boat at marina'),
  intermediate('Intermediate', 'Continue on route');

  final String displayName;
  final String defaultInstruction;

  const WaypointType(this.displayName, this.defaultInstruction);
}

// Types of route segments
enum RouteSegmentType {
  land('Land', 'Driving or walking'),
  marine('Marine', 'Boating'),
  transition('Transition', 'Marina handoff');

  final String displayName;
  final String description;

  const RouteSegmentType(this.displayName, this.description);
}
