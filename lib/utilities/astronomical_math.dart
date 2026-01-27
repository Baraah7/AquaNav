import 'dart:math' as math;

/// Core astronomical calculations for celestial navigation.
/// Implements Julian Date, Sidereal Time, and coordinate transformations.
class AstronomicalMath {
  static const double _degreesToRadians = math.pi / 180.0;
  static const double _radiansToDegrees = 180.0 / math.pi;

  /// Convert degrees to radians.
  static double toRadians(double degrees) => degrees * _degreesToRadians;

  /// Convert radians to degrees.
  static double toDegrees(double radians) => radians * _radiansToDegrees;

  /// Normalize angle to 0-360 degrees.
  static double normalizeDegrees(double degrees) {
    double result = degrees % 360.0;
    if (result < 0) result += 360.0;
    return result;
  }

  /// Normalize angle to -180 to +180 degrees.
  static double normalizeDegreesSymmetric(double degrees) {
    double result = normalizeDegrees(degrees);
    if (result > 180) result -= 360;
    return result;
  }

  /// Calculate Julian Date from UTC DateTime.
  ///
  /// The Julian Date is a continuous count of days since the beginning
  /// of the Julian period (January 1, 4713 BC). This is essential for
  /// astronomical calculations.
  static double calculateJulianDate(DateTime utcDateTime) {
    final int year = utcDateTime.year;
    final int month = utcDateTime.month;
    final int day = utcDateTime.day;
    final double hours = utcDateTime.hour +
        utcDateTime.minute / 60.0 +
        utcDateTime.second / 3600.0 +
        utcDateTime.millisecond / 3600000.0;

    // Adjust for January and February (treated as months 13 and 14 of previous year)
    int y = year;
    int m = month;
    if (month <= 2) {
      y = year - 1;
      m = month + 12;
    }

    // Calculate intermediate values
    final int a = y ~/ 100;
    final int b = 2 - a + (a ~/ 4);

    // Julian Day Number at noon
    final double jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;

    // Add fractional day (hours as fraction)
    return jd + (hours / 24.0);
  }

  /// Calculate days since J2000.0 epoch (January 1, 2000 at 12:00 TT).
  static double daysSinceJ2000(DateTime utcDateTime) {
    final double jd = calculateJulianDate(utcDateTime);
    return jd - 2451545.0; // J2000.0 epoch
  }

  /// Calculate Greenwich Mean Sidereal Time (GMST) in degrees.
  ///
  /// GMST is the hour angle of the vernal equinox at the Prime Meridian.
  /// This is the foundation for converting celestial to horizontal coordinates.
  static double calculateGMST(DateTime utcDateTime) {
    final double d = daysSinceJ2000(utcDateTime);

    // GMST formula (simplified, accurate to ~0.1 second over decades)
    // Reference: Meeus, "Astronomical Algorithms"
    double gmst = 280.46061837 +
        360.98564736629 * d +
        0.000387933 * (d / 36525.0) * (d / 36525.0) -
        (d / 36525.0) * (d / 36525.0) * (d / 36525.0) / 38710000.0;

    return normalizeDegrees(gmst);
  }

  /// Calculate Local Sidereal Time (LST) in degrees.
  ///
  /// LST = GMST + Observer's Longitude (East positive)
  static double calculateLST(DateTime utcDateTime, double longitudeDegrees) {
    final double gmst = calculateGMST(utcDateTime);
    return normalizeDegrees(gmst + longitudeDegrees);
  }

  /// Calculate Greenwich Hour Angle (GHA) from Right Ascension.
  ///
  /// GHA = GMST - RA (measured westward from Greenwich)
  static double calculateGHA(double raDegrees, DateTime utcDateTime) {
    final double gmst = calculateGMST(utcDateTime);
    return normalizeDegrees(gmst - raDegrees);
  }

  /// Calculate Local Hour Angle (LHA) from GHA and observer longitude.
  ///
  /// LHA = GHA + Longitude (East positive)
  static double calculateLHA(
      double ghaDegrees, double observerLongitudeDegrees) {
    return normalizeDegrees(ghaDegrees + observerLongitudeDegrees);
  }

  /// Convert equatorial coordinates (RA/Dec) to horizontal coordinates (Alt/Az).
  ///
  /// This is the core transformation for determining where a star appears
  /// in the observer's sky.
  ///
  /// Returns: (altitude, azimuth) in degrees
  /// - Altitude: 0° at horizon, 90° at zenith
  /// - Azimuth: 0° at North, 90° at East, 180° at South, 270° at West
  static ({double altitude, double azimuth}) equatorialToHorizontal({
    required double raDegrees,
    required double decDegrees,
    required double observerLatDegrees,
    required double observerLonDegrees,
    required DateTime utcDateTime,
  }) {
    // Calculate Local Hour Angle
    final double gha = calculateGHA(raDegrees, utcDateTime);
    final double lha = calculateLHA(gha, observerLonDegrees);

    // Convert to radians
    final double lhaRad = toRadians(lha);
    final double decRad = toRadians(decDegrees);
    final double latRad = toRadians(observerLatDegrees);

    // Calculate altitude using spherical trigonometry
    final double sinAlt =
        math.sin(latRad) * math.sin(decRad) +
        math.cos(latRad) * math.cos(decRad) * math.cos(lhaRad);

    final double altitude = toDegrees(math.asin(sinAlt.clamp(-1.0, 1.0)));

    // Calculate azimuth
    final double cosAz = (math.sin(decRad) -
            math.sin(latRad) * math.sin(toRadians(altitude))) /
        (math.cos(latRad) * math.cos(toRadians(altitude)));

    double azimuth = toDegrees(math.acos(cosAz.clamp(-1.0, 1.0)));

    // Adjust azimuth based on hour angle
    // If LHA > 180°, the star is east of the meridian
    if (math.sin(lhaRad) > 0) {
      azimuth = 360.0 - azimuth;
    }

    return (altitude: altitude, azimuth: azimuth);
  }

  /// Calculate atmospheric refraction correction.
  ///
  /// Light from celestial objects is bent as it passes through Earth's
  /// atmosphere, making objects appear higher than they actually are.
  /// This returns the correction to subtract from observed altitude.
  ///
  /// Uses Bennett's formula for accuracy across all altitudes.
  static double atmosphericRefraction({
    required double altitudeDegrees,
    double temperatureCelsius = 10.0,
    double pressureKPa = 101.0,
  }) {
    if (altitudeDegrees <= 0 || altitudeDegrees >= 90) {
      return 0.0;
    }

    // Bennett's formula (arcminutes)
    final double h = altitudeDegrees;
    double r = 1.0 / math.tan(toRadians(h + 7.31 / (h + 4.4)));

    // Temperature and pressure correction
    final double tempKelvin = temperatureCelsius + 273.15;
    r = r * (pressureKPa / 101.0) * (283.0 / tempKelvin);

    // Convert arcminutes to degrees
    return r / 60.0;
  }

  /// Calculate horizon dip due to observer height.
  ///
  /// An elevated observer sees a depressed horizon compared to true horizontal.
  /// Returns the dip angle in degrees to subtract from observed altitude.
  static double horizonDip(double heightMeters) {
    if (heightMeters <= 0) return 0.0;

    // Dip in arcminutes = 1.76 * sqrt(height in meters)
    final double dipArcmin = 1.76 * math.sqrt(heightMeters);
    return dipArcmin / 60.0;
  }

  /// Calculate true altitude from observed altitude with corrections.
  static double correctedAltitude({
    required double observedAltitude,
    double observerHeightMeters = 0.0,
    double temperatureCelsius = 10.0,
    double pressureKPa = 101.0,
  }) {
    double corrected = observedAltitude;

    // Apply refraction correction
    corrected -= atmosphericRefraction(
      altitudeDegrees: observedAltitude,
      temperatureCelsius: temperatureCelsius,
      pressureKPa: pressureKPa,
    );

    // Apply horizon dip correction
    corrected -= horizonDip(observerHeightMeters);

    return corrected;
  }

  /// Calculate the angular distance between two points on the celestial sphere.
  ///
  /// Used for star pattern matching and validation.
  static double angularDistance({
    required double ra1Degrees,
    required double dec1Degrees,
    required double ra2Degrees,
    required double dec2Degrees,
  }) {
    final double ra1 = toRadians(ra1Degrees);
    final double dec1 = toRadians(dec1Degrees);
    final double ra2 = toRadians(ra2Degrees);
    final double dec2 = toRadians(dec2Degrees);

    // Haversine formula for spherical distance
    final double deltaRa = ra2 - ra1;
    final double deltaDec = dec2 - dec1;

    final double a = math.sin(deltaDec / 2) * math.sin(deltaDec / 2) +
        math.cos(dec1) *
            math.cos(dec2) *
            math.sin(deltaRa / 2) *
            math.sin(deltaRa / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return toDegrees(c);
  }
}
