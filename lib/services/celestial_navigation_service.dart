import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/celestial/star_model.dart';
import 'package:Bahaar/services/device_orientation_service.dart';
import 'package:Bahaar/utilities/astronomical_math.dart';

/// Navigation mode for the application.
enum NavigationMode {
  gps,     // Using GPS for navigation
  star,    // Using star-based heading correction
  compass, // Fallback to compass-only
}

/// Result of a star alignment operation.
class StarAlignmentResult {
  /// The star that was aligned.
  final Star star;

  /// Expected azimuth of the star (calculated from astronomy).
  final double expectedAzimuth;

  /// Observed azimuth from device orientation.
  final double observedAzimuth;

  /// Heading correction offset to apply.
  final double correctionOffset;

  /// Time of alignment.
  final DateTime alignmentTime;

  /// Confidence score (0-1).
  final double confidence;

  const StarAlignmentResult({
    required this.star,
    required this.expectedAzimuth,
    required this.observedAzimuth,
    required this.correctionOffset,
    required this.alignmentTime,
    required this.confidence,
  });

  @override
  String toString() =>
      'StarAlignment(${star.name}: correction=${correctionOffset.toStringAsFixed(1)}°, confidence=${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Celestial navigation service for star-based heading correction.
///
/// This service:
/// 1. Determines true north using stars
/// 2. Corrects compass heading errors
/// 3. Provides directional navigation when GPS is unreliable
///
/// It does NOT:
/// - Replace GPS
/// - Compute absolute position from stars alone
class CelestialNavigationService extends ChangeNotifier {
  static const String _methodChannel = 'celestial_navigation';

  final DeviceOrientationService _orientationService;
  final MethodChannel _channel = const MethodChannel(_methodChannel);

  StarCatalog? _starCatalog;
  NavigationMode _currentMode = NavigationMode.gps;

  // Observer position (from GPS seed)
  LatLng? _observerPosition;
  DateTime? _lastGpsUpdate;

  // Star alignment state
  final List<StarAlignmentResult> _alignmentHistory = [];
  double _headingCorrection = 0.0;
  double _correctionConfidence = 0.0;

  // Thresholds
  static const double _gpsStaleThresholdMinutes = 5.0;
  static const double _minAlignmentConfidence = 0.7;
  static const int _maxAlignmentHistory = 10;

  CelestialNavigationService({
    required DeviceOrientationService orientationService,
  }) : _orientationService = orientationService;

  // ============================================================
  // Getters
  // ============================================================

  NavigationMode get currentMode => _currentMode;
  double get headingCorrection => _headingCorrection;
  double get correctionConfidence => _correctionConfidence;
  LatLng? get observerPosition => _observerPosition;
  StarCatalog? get starCatalog => _starCatalog;
  List<StarAlignmentResult> get alignmentHistory =>
      List.unmodifiable(_alignmentHistory);

  /// Get the corrected true heading.
  double get trueHeading {
    final compassHeading = _orientationService.currentOrientation.compassHeading;
    return AstronomicalMath.normalizeDegrees(compassHeading + _headingCorrection);
  }

  /// Whether star-based correction is available.
  bool get isStarCorrectionAvailable =>
      _correctionConfidence >= _minAlignmentConfidence;

  // ============================================================
  // Initialization
  // ============================================================

  /// Initialize the service and load star catalog.
  Future<void> initialize() async {
    _starCatalog = await StarCatalog.load();
    notifyListeners();
  }

  /// Update observer position from GPS.
  void updatePosition(LatLng position) {
    _observerPosition = position;
    _lastGpsUpdate = DateTime.now();
    notifyListeners();
  }

  /// Check if GPS data is stale.
  bool get isGpsStale {
    if (_lastGpsUpdate == null) return true;
    final minutes = DateTime.now().difference(_lastGpsUpdate!).inMinutes;
    return minutes > _gpsStaleThresholdMinutes;
  }

  // ============================================================
  // Navigation Mode Management
  // ============================================================

  /// Determine the appropriate navigation mode.
  NavigationMode determineNavigationMode({
    required bool hasGps,
    required bool isNight,
    required bool hasClearSky,
  }) {
    if (hasGps && !isGpsStale) {
      return NavigationMode.gps;
    }

    if (isNight && hasClearSky && isStarCorrectionAvailable) {
      return NavigationMode.star;
    }

    return NavigationMode.compass;
  }

  /// Set the navigation mode manually.
  void setNavigationMode(NavigationMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  // ============================================================
  // Star Alignment (Manual Selection - Phase 7)
  // ============================================================

  /// Get stars currently visible and suitable for alignment.
  List<StarPosition> getAlignmentCandidates() {
    if (_starCatalog == null || _observerPosition == null) {
      return [];
    }

    return _starCatalog!.getNavigationStars(
      observerLat: _observerPosition!.latitude,
      observerLon: _observerPosition!.longitude,
    );
  }

  /// Perform star alignment with a selected star.
  ///
  /// User points device at the star and confirms alignment.
  /// This calculates the correction offset between expected and observed azimuth.
  StarAlignmentResult? alignWithStar(Star star) {
    if (_observerPosition == null) {
      return null;
    }

    // Calculate expected star position
    final expectedPosition = star.calculatePosition(
      observerLat: _observerPosition!.latitude,
      observerLon: _observerPosition!.longitude,
    );

    // Get observed device orientation
    final orientation = _orientationService.currentOrientation;
    final observedAzimuth = _orientationService.getPointingAzimuth();

    // Calculate correction offset
    // correction = expected - observed
    double correction = expectedPosition.azimuth - observedAzimuth;

    // Normalize to -180 to +180
    correction = AstronomicalMath.normalizeDegreesSymmetric(correction);

    // Calculate confidence based on observation conditions
    double confidence = _calculateAlignmentConfidence(
      starAltitude: expectedPosition.altitude,
      devicePitch: orientation.pitch,
      deviceRoll: orientation.roll,
    );

    final result = StarAlignmentResult(
      star: star,
      expectedAzimuth: expectedPosition.azimuth,
      observedAzimuth: observedAzimuth,
      correctionOffset: correction,
      alignmentTime: DateTime.now(),
      confidence: confidence,
    );

    // Add to history and update correction
    _addAlignmentResult(result);

    return result;
  }

  /// Align using Polaris (North Star) for quick true north determination.
  ///
  /// Polaris is always within ~1° of true north, making it ideal for
  /// heading correction in the Northern Hemisphere.
  StarAlignmentResult? alignWithPolaris() {
    final polaris = _starCatalog?.polaris;
    if (polaris == null) return null;

    // Check if Polaris is visible
    if (_observerPosition != null) {
      final position = polaris.calculatePosition(
        observerLat: _observerPosition!.latitude,
        observerLon: _observerPosition!.longitude,
      );

      if (!position.isAboveHorizon) {
        return null; // Polaris not visible (Southern Hemisphere or below horizon)
      }
    }

    return alignWithStar(polaris);
  }

  double _calculateAlignmentConfidence({
    required double starAltitude,
    required double devicePitch,
    required double deviceRoll,
  }) {
    double confidence = 1.0;

    // Reduce confidence if star is too low or too high
    if (starAltitude < 15) {
      confidence *= 0.7; // Low stars have more atmospheric distortion
    } else if (starAltitude > 75) {
      confidence *= 0.8; // High stars are harder to align with
    }

    // Reduce confidence if device is not stable
    if (deviceRoll.abs() > 10) {
      confidence *= 0.9;
    }

    return confidence.clamp(0.0, 1.0);
  }

  void _addAlignmentResult(StarAlignmentResult result) {
    _alignmentHistory.add(result);

    // Keep only recent alignments
    while (_alignmentHistory.length > _maxAlignmentHistory) {
      _alignmentHistory.removeAt(0);
    }

    // Calculate weighted average correction
    _updateHeadingCorrection();
    notifyListeners();
  }

  void _updateHeadingCorrection() {
    if (_alignmentHistory.isEmpty) {
      _headingCorrection = 0.0;
      _correctionConfidence = 0.0;
      return;
    }

    // Weight recent alignments more heavily
    double totalWeight = 0;
    double weightedSum = 0;
    double confidenceSum = 0;

    final now = DateTime.now();
    for (int i = 0; i < _alignmentHistory.length; i++) {
      final result = _alignmentHistory[i];

      // Time-based decay (older alignments have less weight)
      final ageMinutes = now.difference(result.alignmentTime).inMinutes;
      final timeWeight = 1.0 / (1.0 + ageMinutes / 10.0);

      // Combined weight
      final weight = result.confidence * timeWeight;

      // Handle angle wraparound
      double correction = result.correctionOffset;
      if (i > 0) {
        final prevCorrection = weightedSum / totalWeight;
        final diff = correction - prevCorrection;
        if (diff > 180) correction -= 360;
        if (diff < -180) correction += 360;
      }

      weightedSum += correction * weight;
      totalWeight += weight;
      confidenceSum += result.confidence;
    }

    if (totalWeight > 0) {
      _headingCorrection = weightedSum / totalWeight;
      _correctionConfidence = confidenceSum / _alignmentHistory.length;
    }
  }

  /// Clear alignment history and reset correction.
  void resetAlignment() {
    _alignmentHistory.clear();
    _headingCorrection = 0.0;
    _correctionConfidence = 0.0;
    notifyListeners();
  }

  // ============================================================
  // Navigation Output (Phase 8)
  // ============================================================

  /// Calculate the turn angle needed to reach a target bearing.
  ///
  /// Returns positive for turn right, negative for turn left.
  double calculateTurnAngle(double targetBearing) {
    final currentHeading = trueHeading;
    double turn = targetBearing - currentHeading;

    // Normalize to -180 to +180 (shortest turn)
    if (turn > 180) turn -= 360;
    if (turn < -180) turn += 360;

    return turn;
  }

  /// Get the direction to true north.
  double get trueNorthDirection => calculateTurnAngle(0);

  /// Get cardinal direction string for current heading.
  String get cardinalDirection {
    final heading = trueHeading;
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading < 67.5) return 'NE';
    if (heading < 112.5) return 'E';
    if (heading < 157.5) return 'SE';
    if (heading < 202.5) return 'S';
    if (heading < 247.5) return 'SW';
    if (heading < 292.5) return 'W';
    return 'NW';
  }

  // ============================================================
  // Python Bridge (for advanced features)
  // ============================================================

  /// Call Python celestial service for position calculation.
  /// Used for advanced multi-star position fixing.
  Future<Map<String, dynamic>?> calculatePositionFromStars(
    List<Map<String, dynamic>> observations,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'calculate_from_names',
        {
          'observations': observations,
          'time': DateTime.now().toUtc().toIso8601String(),
          if (_observerPosition != null)
            'estimated_position': {
              'lat': _observerPosition!.latitude,
              'lon': _observerPosition!.longitude,
            },
        },
      );

      return result?.cast<String, dynamic>();
    } on PlatformException catch (e) {
      debugPrint('Error calling celestial service: ${e.message}');
      return null;
    }
  }

  /// Get list of available navigation stars from Python service.
  Future<List<Map<String, dynamic>>?> getAvailableStars({
    double minMagnitude = 2.0,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'list_stars',
        {'min_magnitude': minMagnitude},
      );

      if (result?['success'] == true) {
        final stars = result!['stars'] as List<dynamic>;
        return stars.cast<Map<String, dynamic>>();
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Error getting star list: ${e.message}');
      return null;
    }
  }

}
