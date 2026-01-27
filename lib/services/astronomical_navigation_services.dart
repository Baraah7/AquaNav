/// Celestial Navigation Services
///
/// This module provides star-based navigation capabilities for the Bahaar app.
library;
/// It enables heading correction using celestial observations when GPS is unreliable.
///
/// ## Features
/// - Determine true north using stars
/// - Correct compass heading errors
/// - Provide directional navigation when GPS is weak
///
/// ## Architecture
/// ```
/// GPS (seed position)
///   ↓
/// Time → Sidereal Time
///   ↓
/// Star Catalog → Alt/Az
///   ↓
/// Sensor Orientation
///   ↓
/// Heading Correction
///   ↓
/// Navigation Output
/// ```
///
/// ## Usage
/// ```dart
/// // Initialize services
/// final orientationService = DeviceOrientationService();
/// final celestialService = CelestialNavigationService(
///   orientationService: orientationService,
/// );
/// await celestialService.initialize();
///
/// // Update position from GPS
/// celestialService.updatePosition(LatLng(26.0, 50.0));
///
/// // Get visible stars for alignment
/// final candidates = celestialService.getAlignmentCandidates();
///
/// // Align with a star
/// final result = celestialService.alignWithStar(candidates.first.star);
///
/// // Get corrected heading
/// final trueHeading = celestialService.trueHeading;
/// ```

// Core services
export 'celestial_navigation_service.dart';
export 'device_orientation_service.dart';
export 'navigation_mode_manager.dart';

// Re-export models
export 'package:Bahaar/models/celestial/star_model.dart';
export 'package:Bahaar/utilities/astronomical_math.dart';
