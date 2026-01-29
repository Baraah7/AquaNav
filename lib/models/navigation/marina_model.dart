import 'package:latlong2/latlong.dart';

/// Represents a marina, harbor, slipway, or boat launch point
class Marina {
  final String id;
  final String name;
  final LatLng location;
  final MarinaType type;
  final MarinaAccessType accessType;
  final double? depth;
  final List<String> facilities;
  final String? osmId;
  final bool isValidated;
  final Map<String, dynamic>? metadata;

  const Marina({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    this.accessType = MarinaAccessType.public,
    this.depth,
    this.facilities = const [],
    this.osmId,
    this.isValidated = false,
    this.metadata,
  });

  /// Create Marina from GeoJSON feature
  factory Marina.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return Marina(
      id: json['id'] as String,
      name: properties['name'] as String,
      location: LatLng(coordinates[1], coordinates[0]), // GeoJSON is [lon, lat]
      type: _parseMarinaType(properties['type'] as String),
      accessType: _parseAccessType(properties['access'] as String?),
      depth: properties['depth_m'] as double?,
      facilities: (properties['facilities'] as List?)?.cast<String>() ?? [],
      osmId: properties['osm_id'] as String?,
      isValidated: properties['validated'] as bool? ?? false,
      metadata: properties,
    );
  }

  /// Create Marina from OpenStreetMap node data
  factory Marina.fromOsmNode(Map<String, dynamic> osmData) {
    final tags = osmData['tags'] as Map<String, dynamic>;
    final lat = osmData['lat'] as double;
    final lon = osmData['lon'] as double;

    return Marina(
      id: 'osm_${osmData['id']}',
      name: tags['name'] as String? ?? 'Unnamed Marina',
      location: LatLng(lat, lon),
      type: _parseMarinaTypeFromOsmTags(tags),
      accessType: _parseAccessType(tags['access'] as String?),
      depth: _parseDepth(tags),
      facilities: _parseFacilities(tags),
      osmId: osmData['id'].toString(),
      isValidated: false,
      metadata: tags,
    );
  }

  /// Convert Marina to GeoJSON feature
  Map<String, dynamic> toJson() {
    return {
      'type': 'Feature',
      'id': id,
      'properties': {
        'name': name,
        'type': type.value,
        'access': accessType.value,
        if (depth != null) 'depth_m': depth,
        'facilities': facilities,
        if (osmId != null) 'osm_id': osmId,
        'validated': isValidated,
        if (metadata != null) ...metadata!,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [location.longitude, location.latitude],
      },
    };
  }

  /// Parse marina type from string
  static MarinaType _parseMarinaType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'marina':
        return MarinaType.marina;
      case 'harbor':
      case 'harbour':
        return MarinaType.harbor;
      case 'slipway':
        return MarinaType.slipway;
      case 'boat_ramp':
      case 'boatramp':
        return MarinaType.boatRamp;
      case 'port':
        return MarinaType.port;
      default:
        return MarinaType.marina;
    }
  }

  /// Parse marina type from OSM tags
  static MarinaType _parseMarinaTypeFromOsmTags(Map<String, dynamic> tags) {
    if (tags['leisure'] == 'marina') return MarinaType.marina;
    if (tags['leisure'] == 'slipway') return MarinaType.slipway;
    if (tags['waterway'] == 'dock') return MarinaType.harbor;
    if (tags['amenity'] == 'boat_ramp') return MarinaType.boatRamp;
    if (tags['landuse'] == 'port') return MarinaType.port;
    return MarinaType.marina;
  }

  /// Parse access type from string
  static MarinaAccessType _parseAccessType(String? accessString) {
    if (accessString == null) return MarinaAccessType.public;

    switch (accessString.toLowerCase()) {
      case 'public':
      case 'yes':
        return MarinaAccessType.public;
      case 'private':
      case 'no':
        return MarinaAccessType.private;
      case 'customers':
        return MarinaAccessType.customers;
      case 'permissive':
        return MarinaAccessType.permissive;
      default:
        return MarinaAccessType.public;
    }
  }

  /// Parse depth from OSM tags
  static double? _parseDepth(Map<String, dynamic> tags) {
    final depthStr = tags['depth'] as String?;
    if (depthStr == null) return null;

    // Try to parse depth (e.g., "3.5", "3.5 m")
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(depthStr);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }

    return null;
  }

  /// Parse facilities from OSM tags
  static List<String> _parseFacilities(Map<String, dynamic> tags) {
    final facilities = <String>[];

    if (tags['amenity:parking'] == 'yes' || tags['parking'] == 'yes') {
      facilities.add('parking');
    }
    if (tags['amenity:fuel'] == 'yes' || tags['fuel'] == 'yes') {
      facilities.add('fuel');
    }
    if (tags['amenity:toilets'] == 'yes' || tags['toilets'] == 'yes') {
      facilities.add('restroom');
    }
    if (tags['amenity:restaurant'] == 'yes' || tags['restaurant'] == 'yes') {
      facilities.add('restaurant');
    }
    if (tags['amenity:shower'] == 'yes' || tags['shower'] == 'yes') {
      facilities.add('shower');
    }

    return facilities;
  }

  @override
  String toString() {
    return 'Marina(id: $id, name: $name, type: ${type.displayName}, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Marina && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of marina/launch facilities
enum MarinaType {
  marina('marina', 'Marina'),
  harbor('harbor', 'Harbor'),
  slipway('slipway', 'Slipway'),
  boatRamp('boat_ramp', 'Boat Ramp'),
  port('port', 'Port');

  final String value;
  final String displayName;

  const MarinaType(this.value, this.displayName);
}

/// Access types for marinas
enum MarinaAccessType {
  public('public', 'Public'),
  private('private', 'Private'),
  customers('customers', 'Customers Only'),
  permissive('permissive', 'Permissive');

  final String value;
  final String displayName;

  const MarinaAccessType(this.value, this.displayName);
}
