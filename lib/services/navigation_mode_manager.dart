import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:Bahaar/services/celestial_navigation_service.dart';
import 'package:Bahaar/services/device_orientation_service.dart';

/// Navigation mode for the application.
/// Re-exported from celestial_navigation_service for convenience.
export 'package:Bahaar/services/celestial_navigation_service.dart'
    show NavigationMode;

/// GPS signal quality assessment.
enum GpsQuality {
  excellent, // Accuracy < 5m
  good,      // Accuracy < 15m
  fair,      // Accuracy < 30m
  poor,      // Accuracy < 100m
  none,      // No GPS signal
}

/// Conditions for star navigation.
class StarNavigationConditions {
  final bool isNight;
  final bool hasClearSky;
  final bool hasStarAlignment;
  final double alignmentConfidence;

  const StarNavigationConditions({
    required this.isNight,
    required this.hasClearSky,
    required this.hasStarAlignment,
    required this.alignmentConfidence,
  });

  bool get canUseStarNavigation =>
      isNight && hasClearSky && hasStarAlignment && alignmentConfidence >= 0.7;
}

/// Unified navigation state combining all navigation sources.
class NavigationState {
  final NavigationMode activeMode;
  final GpsQuality gpsQuality;
  final LatLng? currentPosition;
  final double? gpsHeading;
  final double compassHeading;
  final double trueHeading;
  final double headingCorrection;
  final double correctionConfidence;
  final StarNavigationConditions starConditions;
  final DateTime timestamp;

  const NavigationState({
    required this.activeMode,
    required this.gpsQuality,
    required this.currentPosition,
    required this.gpsHeading,
    required this.compassHeading,
    required this.trueHeading,
    required this.headingCorrection,
    required this.correctionConfidence,
    required this.starConditions,
    required this.timestamp,
  });

  /// Get the best available heading based on current mode.
  double get bestHeading {
    switch (activeMode) {
      case NavigationMode.gps:
        return gpsHeading ?? trueHeading;
      case NavigationMode.star:
        return trueHeading;
      case NavigationMode.compass:
        return compassHeading;
    }
  }

  /// Human-readable mode description.
  String get modeDescription {
    switch (activeMode) {
      case NavigationMode.gps:
        return 'GPS Navigation';
      case NavigationMode.star:
        return 'Star Navigation';
      case NavigationMode.compass:
        return 'Compass Only';
    }
  }

  /// Accuracy indicator string.
  String get accuracyIndicator {
    switch (activeMode) {
      case NavigationMode.gps:
        switch (gpsQuality) {
          case GpsQuality.excellent:
            return 'High Accuracy';
          case GpsQuality.good:
            return 'Good Accuracy';
          case GpsQuality.fair:
            return 'Fair Accuracy';
          case GpsQuality.poor:
            return 'Low Accuracy';
          case GpsQuality.none:
            return 'No GPS';
        }
      case NavigationMode.star:
        if (correctionConfidence >= 0.9) return 'High Confidence';
        if (correctionConfidence >= 0.7) return 'Good Confidence';
        return 'Low Confidence';
      case NavigationMode.compass:
        return 'Uncorrected';
    }
  }
}

/// Manager for navigation mode switching and state coordination.
///
/// Implements the navigation state machine:
/// - GPS OK → GPS Mode
/// - GPS Weak + Night + Stars → Star Mode
/// - No GPS + No Stars → Compass Mode
class NavigationModeManager extends ChangeNotifier {
  final Location _location;
  final DeviceOrientationService _orientationService;
  final CelestialNavigationService _celestialService;

  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _stateUpdateTimer;

  // Current state
  NavigationMode _activeMode = NavigationMode.compass;
  GpsQuality _gpsQuality = GpsQuality.none;
  LatLng? _currentPosition;
  double? _gpsHeading;
  double? _gpsAccuracy;
  DateTime? _lastGpsUpdate;

  // User preferences
  bool _autoModeSwitch = true;
  bool _userAssumesClearSky = false;
  bool _userAssumesNight = false;

  // Thresholds
  static const double _gpsExcellentThreshold = 5.0;
  static const double _gpsGoodThreshold = 15.0;
  static const double _gpsFairThreshold = 30.0;
  static const double _gpsPoorThreshold = 100.0;
  static const int _gpsStaleSeconds = 30;

  NavigationModeManager({
    required Location location,
    required DeviceOrientationService orientationService,
    required CelestialNavigationService celestialService,
  })  : _location = location,
        _orientationService = orientationService,
        _celestialService = celestialService;

  // ============================================================
  // Getters
  // ============================================================

  NavigationMode get activeMode => _activeMode;
  GpsQuality get gpsQuality => _gpsQuality;
  LatLng? get currentPosition => _currentPosition;
  bool get autoModeSwitch => _autoModeSwitch;

  NavigationState get currentState => NavigationState(
        activeMode: _activeMode,
        gpsQuality: _gpsQuality,
        currentPosition: _currentPosition,
        gpsHeading: _gpsHeading,
        compassHeading: _orientationService.currentOrientation.compassHeading,
        trueHeading: _celestialService.trueHeading,
        headingCorrection: _celestialService.headingCorrection,
        correctionConfidence: _celestialService.correctionConfidence,
        starConditions: _getStarConditions(),
        timestamp: DateTime.now(),
      );

  // ============================================================
  // Lifecycle
  // ============================================================

  /// Start the navigation mode manager.
  Future<void> start() async {
    // Configure location
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
      distanceFilter: 1,
    );

    // Start orientation service
    await _orientationService.start();

    // Subscribe to location updates
    _locationSubscription = _location.onLocationChanged.listen(
      _onLocationUpdate,
      onError: (e) => debugPrint('Location error: $e'),
    );

    // Periodic state evaluation
    _stateUpdateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _evaluateNavigationMode(),
    );

    notifyListeners();
  }

  /// Stop the navigation mode manager.
  void stop() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    _stateUpdateTimer?.cancel();
    _stateUpdateTimer = null;

    _orientationService.stop();

    notifyListeners();
  }

  // ============================================================
  // Location Updates
  // ============================================================

  void _onLocationUpdate(LocationData data) {
    final lat = data.latitude;
    final lon = data.longitude;

    if (lat != null && lon != null) {
      _currentPosition = LatLng(lat, lon);
      _gpsHeading = data.heading;
      _gpsAccuracy = data.accuracy;
      _lastGpsUpdate = DateTime.now();

      // Update celestial service with position
      _celestialService.updatePosition(_currentPosition!);

      // Assess GPS quality
      _updateGpsQuality();
    }

    notifyListeners();
  }

  void _updateGpsQuality() {
    if (_gpsAccuracy == null || _isGpsStale()) {
      _gpsQuality = GpsQuality.none;
    } else if (_gpsAccuracy! <= _gpsExcellentThreshold) {
      _gpsQuality = GpsQuality.excellent;
    } else if (_gpsAccuracy! <= _gpsGoodThreshold) {
      _gpsQuality = GpsQuality.good;
    } else if (_gpsAccuracy! <= _gpsFairThreshold) {
      _gpsQuality = GpsQuality.fair;
    } else if (_gpsAccuracy! <= _gpsPoorThreshold) {
      _gpsQuality = GpsQuality.poor;
    } else {
      _gpsQuality = GpsQuality.none;
    }
  }

  bool _isGpsStale() {
    if (_lastGpsUpdate == null) return true;
    return DateTime.now().difference(_lastGpsUpdate!).inSeconds >
        _gpsStaleSeconds;
  }

  // ============================================================
  // Mode Management
  // ============================================================

  /// Evaluate and potentially switch navigation mode.
  void _evaluateNavigationMode() {
    if (!_autoModeSwitch) return;

    final newMode = _determineOptimalMode();

    if (newMode != _activeMode) {
      _activeMode = newMode;
      debugPrint('Navigation mode changed to: $_activeMode');
      notifyListeners();
    }
  }

  NavigationMode _determineOptimalMode() {
    // Priority 1: GPS if available and good quality
    if (_gpsQuality == GpsQuality.excellent ||
        _gpsQuality == GpsQuality.good) {
      return NavigationMode.gps;
    }

    // Priority 2: Star navigation if conditions are met
    final starConditions = _getStarConditions();
    if (starConditions.canUseStarNavigation) {
      return NavigationMode.star;
    }

    // Priority 3: Fair GPS is still better than compass alone
    if (_gpsQuality == GpsQuality.fair) {
      return NavigationMode.gps;
    }

    // Priority 4: Star navigation with lower threshold if GPS is poor
    if (_gpsQuality == GpsQuality.poor || _gpsQuality == GpsQuality.none) {
      if (starConditions.hasStarAlignment &&
          starConditions.alignmentConfidence >= 0.5) {
        return NavigationMode.star;
      }
    }

    // Fallback: Compass only
    return NavigationMode.compass;
  }

  StarNavigationConditions _getStarConditions() {
    // In a real app, these would be determined by:
    // - Time of day and astronomical twilight calculations
    // - Weather API for cloud cover
    // - Light sensor for ambient light
    // For now, use user assumptions or time-based estimation

    final isNight = _userAssumesNight || _estimateIsNight();
    final hasClearSky = _userAssumesClearSky;
    final hasAlignment = _celestialService.isStarCorrectionAvailable;
    final confidence = _celestialService.correctionConfidence;

    return StarNavigationConditions(
      isNight: isNight,
      hasClearSky: hasClearSky,
      hasStarAlignment: hasAlignment,
      alignmentConfidence: confidence,
    );
  }

  bool _estimateIsNight() {
    // Simple estimation based on time
    // A more accurate implementation would use astronomical calculations
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 19;
  }

  // ============================================================
  // User Controls
  // ============================================================

  /// Manually set navigation mode (disables auto-switching).
  void setMode(NavigationMode mode) {
    _activeMode = mode;
    _autoModeSwitch = false;
    notifyListeners();
  }

  /// Enable automatic mode switching.
  void enableAutoMode() {
    _autoModeSwitch = true;
    _evaluateNavigationMode();
    notifyListeners();
  }

  /// Set user assumption about clear sky (for star navigation).
  void setClearSkyAssumption(bool isClear) {
    _userAssumesClearSky = isClear;
    _evaluateNavigationMode();
    notifyListeners();
  }

  /// Set user assumption about night time.
  void setNightAssumption(bool isNight) {
    _userAssumesNight = isNight;
    _evaluateNavigationMode();
    notifyListeners();
  }

  // ============================================================
  // Navigation Helpers
  // ============================================================

  /// Get current heading based on active mode.
  double getCurrentHeading() => currentState.bestHeading;

  /// Calculate turn angle to reach target bearing.
  double getTurnAngle(double targetBearing) {
    final currentHeading = getCurrentHeading();
    double turn = targetBearing - currentHeading;

    // Normalize to -180 to +180
    if (turn > 180) turn -= 360;
    if (turn < -180) turn += 360;

    return turn;
  }

  /// Get direction to true north.
  double getTrueNorthDirection() => getTurnAngle(0);

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
