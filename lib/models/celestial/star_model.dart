import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:Bahaar/utilities/astronomical_math.dart';

/// Represents a navigation star from the catalog.
class Star {
  final String name;
  final String arabic;
  final double ra;  // Right Ascension in degrees
  final double dec; // Declination in degrees
  final double magnitude;
  final String constellation;
  final String? note;

  const Star({
    required this.name,
    required this.arabic,
    required this.ra,
    required this.dec,
    required this.magnitude,
    required this.constellation,
    this.note,
  });

  factory Star.fromJson(Map<String, dynamic> json) {
    return Star(
      name: json['name'] as String,
      arabic: json['arabic'] as String,
      ra: (json['ra'] as num).toDouble(),
      dec: (json['dec'] as num).toDouble(),
      magnitude: (json['magnitude'] as num).toDouble(),
      constellation: json['constellation'] as String,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'arabic': arabic,
    'ra': ra,
    'dec': dec,
    'magnitude': magnitude,
    'constellation': constellation,
    if (note != null) 'note': note,
  };

  /// Calculate the current horizontal position (altitude/azimuth) of this star.
  StarPosition calculatePosition({
    required double observerLat,
    required double observerLon,
    DateTime? utcTime,
  }) {
    final time = utcTime ?? DateTime.now().toUtc();

    final coords = AstronomicalMath.equatorialToHorizontal(
      raDegrees: ra,
      decDegrees: dec,
      observerLatDegrees: observerLat,
      observerLonDegrees: observerLon,
      utcDateTime: time,
    );

    return StarPosition(
      star: this,
      altitude: coords.altitude,
      azimuth: coords.azimuth,
      calculationTime: time,
      observerLat: observerLat,
      observerLon: observerLon,
    );
  }

  /// Check if star is currently visible (above horizon).
  bool isVisible({
    required double observerLat,
    required double observerLon,
    DateTime? utcTime,
    double minAltitude = 5.0, // Minimum altitude above horizon
  }) {
    final position = calculatePosition(
      observerLat: observerLat,
      observerLon: observerLon,
      utcTime: utcTime,
    );
    return position.altitude >= minAltitude;
  }

  @override
  String toString() => 'Star($name, mag=$magnitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Star && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Calculated position of a star in the observer's sky.
class StarPosition {
  final Star star;
  final double altitude;  // Degrees above horizon (0-90)
  final double azimuth;   // Degrees from North (0-360)
  final DateTime calculationTime;
  final double observerLat;
  final double observerLon;

  const StarPosition({
    required this.star,
    required this.altitude,
    required this.azimuth,
    required this.calculationTime,
    required this.observerLat,
    required this.observerLon,
  });

  /// Whether the star is above the horizon.
  bool get isAboveHorizon => altitude > 0;

  /// Whether the star is at a good observation altitude (not too low, not directly overhead).
  bool get isGoodForObservation => altitude >= 15 && altitude <= 75;

  /// Cardinal direction string for the azimuth.
  String get cardinalDirection {
    if (azimuth >= 337.5 || azimuth < 22.5) return 'N';
    if (azimuth < 67.5) return 'NE';
    if (azimuth < 112.5) return 'E';
    if (azimuth < 157.5) return 'SE';
    if (azimuth < 202.5) return 'S';
    if (azimuth < 247.5) return 'SW';
    if (azimuth < 292.5) return 'W';
    return 'NW';
  }

  @override
  String toString() =>
      'StarPosition(${star.name}: alt=${altitude.toStringAsFixed(1)}°, az=${azimuth.toStringAsFixed(1)}° $cardinalDirection)';
}

/// Catalog of navigation stars loaded from assets.
class StarCatalog {
  final List<Star> _stars;

  StarCatalog._(this._stars);

  /// Load the star catalog from assets.
  static Future<StarCatalog> load() async {
    final jsonString = await rootBundle.loadString('assets/celestial/stars.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final starsJson = jsonData['stars'] as List<dynamic>;

    final stars = starsJson
        .map((s) => Star.fromJson(s as Map<String, dynamic>))
        .toList();

    // Sort by magnitude (brightest first)
    stars.sort((a, b) => a.magnitude.compareTo(b.magnitude));

    return StarCatalog._(stars);
  }

  /// All stars in the catalog.
  List<Star> get all => List.unmodifiable(_stars);

  /// Number of stars in the catalog.
  int get length => _stars.length;

  /// Get star by name (case-insensitive).
  Star? getByName(String name) {
    final nameLower = name.toLowerCase();
    try {
      return _stars.firstWhere(
        (s) => s.name.toLowerCase() == nameLower,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get star by Arabic name.
  Star? getByArabicName(String arabicName) {
    try {
      return _stars.firstWhere((s) => s.arabic == arabicName);
    } catch (_) {
      return null;
    }
  }

  /// Get Polaris (the North Star).
  Star? get polaris => getByName('Polaris');

  /// Get stars brighter than specified magnitude.
  List<Star> getBrighterThan(double magnitude) {
    return _stars.where((s) => s.magnitude <= magnitude).toList();
  }

  /// Get stars in a specific constellation.
  List<Star> getByConstellation(String constellation) {
    final constLower = constellation.toLowerCase();
    return _stars
        .where((s) => s.constellation.toLowerCase() == constLower)
        .toList();
  }

  /// Get currently visible stars from observer's location.
  List<StarPosition> getVisibleStars({
    required double observerLat,
    required double observerLon,
    DateTime? utcTime,
    double minAltitude = 5.0,
    double? maxMagnitude,
  }) {
    final time = utcTime ?? DateTime.now().toUtc();
    final positions = <StarPosition>[];

    for (final star in _stars) {
      if (maxMagnitude != null && star.magnitude > maxMagnitude) continue;

      final position = star.calculatePosition(
        observerLat: observerLat,
        observerLon: observerLon,
        utcTime: time,
      );

      if (position.altitude >= minAltitude) {
        positions.add(position);
      }
    }

    // Sort by altitude (highest first - easier to observe)
    positions.sort((a, b) => b.altitude.compareTo(a.altitude));

    return positions;
  }

  /// Get stars suitable for heading correction.
  /// Returns stars that are visible and at good observation altitudes.
  List<StarPosition> getNavigationStars({
    required double observerLat,
    required double observerLon,
    DateTime? utcTime,
    int maxStars = 5,
  }) {
    final visible = getVisibleStars(
      observerLat: observerLat,
      observerLon: observerLon,
      utcTime: utcTime,
      minAltitude: 15.0,
      maxMagnitude: 2.0,
    );

    // Filter to good observation altitudes and limit count
    return visible
        .where((p) => p.isGoodForObservation)
        .take(maxStars)
        .toList();
  }
}
