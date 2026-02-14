/// Configuration constants for the navigation system
class NavigationConstants {
  NavigationConstants._(); // Private constructor to prevent instantiation

  // ============================================================
  // OSRM Configuration
  // ============================================================

  /// Base URL for OSRM routing service
  /// Use public demo server or configure your own self-hosted instance
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  /// Whether to use the public OSRM API
  /// Set to false if using a self-hosted OSRM server
  static const bool usePublicOsrmApi = true;

  /// Maximum number of retry attempts for OSRM requests
  static const int osrmMaxRetries = 3;

  /// Timeout duration for OSRM API requests (seconds)
  static const int osrmTimeoutSeconds = 10;

  // ============================================================
  // Marine Navigation Configuration
  // ============================================================

  /// Average boat speed in meters per second (10 knots = 5.14 m/s)
  static const double averageBoatSpeedMs = 5.14;

  /// Average boat speed in knots
  static const double averageBoatSpeedKnots = 10.0;

  /// Marina search radius in meters (5 km default)
  static const double marinaSearchRadius = 5000.0;

  /// Maximum distance to snap to water grid (meters)
  static const double maxWaterSnapDistance = 100.0;

  // ============================================================
  // Navigation Session Configuration
  // ============================================================

  /// Distance threshold for considering user off-route (meters)
  static const double offRouteThreshold = 50.0;

  /// Distance threshold for reaching a waypoint (meters)
  static const double waypointProximity = 20.0;

  /// Maximum number of route recalculations per session
  static const int maxRecalculations = 5;

  /// Interval for location updates during navigation (milliseconds)
  static const int locationUpdateInterval = 1000;

  /// Maximum breadcrumb history length (to limit memory usage)
  static const int maxBreadcrumbs = 1000;

  // ============================================================
  // A* Pathfinding Configuration
  // ============================================================

  /// Weight for depth preference in cost function
  /// Higher weight = stronger preference for deeper water
  static const double aStarDepthWeight = 0.1;

  /// Penalty for passing through restricted areas
  /// Very high value to strongly discourage routing through restricted zones
  static const double aStarRestrictedPenalty = 1000.0;

  /// Cost multiplier for diagonal moves (sqrt(2))
  static const double aStarDiagonalCost = 1.414;

  /// Maximum iterations before A* algorithm gives up
  static const int aStarMaxIterations = 100000;

  /// Timeout for A* pathfinding (seconds)
  static const int aStarTimeoutSeconds = 10;

  // ============================================================
  // Weather & Safety Configuration
  // ============================================================

  /// Open-Meteo Marine API base URL (free, no API key)
  static const String openMeteoMarineBaseUrl = 'https://marine-api.open-meteo.com/v1/marine';

  /// Open-Meteo Forecast API base URL (for wind/visibility)
  static const String openMeteoForecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Interval for refreshing marine weather data (seconds)
  static const int weatherRefreshIntervalSeconds = 900; // 15 minutes

  /// Coarse weather grid resolution (degrees per sample point)
  static const double weatherGridResolution = 0.2;

  /// Wave height thresholds (meters)
  static const double waveHeightCaution = 1.0;
  static const double waveHeightDangerous = 2.0;
  static const double waveHeightBlocked = 3.0;

  /// Wind speed thresholds (km/h)
  static const double windSpeedCautionKph = 30.0;
  static const double windSpeedDangerousKph = 45.0;
  static const double windSpeedBlockedKph = 60.0;

  /// Visibility thresholds (meters)
  static const double visibilityCautionMeters = 5000.0;
  static const double visibilityDangerousMeters = 2000.0;
  static const double visibilityBlockedMeters = 500.0;

  /// A* cost multiplier for caution-level weather
  static const double weatherCautionMultiplier = 2.0;

  /// A* cost multiplier for dangerous-level weather
  static const double weatherDangerousMultiplier = 5.0;

  // ============================================================
  // Route Preferences
  // ============================================================

  /// Default zoom level for route overview
  static const double routeOverviewZoom = 12.0;

  /// Zoom level for viewing route details
  static const double routeDetailZoom = 15.0;

  /// Zoom level for marina handoff points
  static const double marinaZoom = 16.0;

  /// Buffer around route for map bounds (degrees)
  static const double routeBoundsBuffer = 0.01;

  // ============================================================
  // Distance & Speed Formatting
  // ============================================================

  /// Threshold for displaying distances in kilometers (meters)
  static const double kmThreshold = 1000.0;

  /// Threshold for displaying long durations in hours (seconds)
  static const int hourThreshold = 3600;

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Convert meters to nautical miles
  static double metersToNauticalMiles(double meters) {
    return meters / 1852.0;
  }

  /// Convert nautical miles to meters
  static double nauticalMilesToMeters(double nauticalMiles) {
    return nauticalMiles * 1852.0;
  }

  /// Convert meters per second to knots
  static double msToKnots(double metersPerSecond) {
    return metersPerSecond * 1.94384;
  }

  /// Convert knots to meters per second
  static double knotsToMs(double knots) {
    return knots / 1.94384;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < kmThreshold) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration for display
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < hourThreshold) {
      final minutes = (seconds / 60).round();
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Format speed for display (m/s to knots)
  static String formatSpeed(double metersPerSecond) {
    final knots = msToKnots(metersPerSecond);
    return '${knots.toStringAsFixed(1)} kn';
  }
}
