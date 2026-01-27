import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// Mock sensor event classes
class AccelerometerEvent {
  final double x, y, z;
  AccelerometerEvent(this.x, this.y, this.z);
}

class MagnetometerEvent {
  final double x, y, z;
  MagnetometerEvent(this.x, this.y, this.z);
}

class GyroscopeEvent {
  final double x, y, z;
  GyroscopeEvent(this.x, this.y, this.z);
}

/// Device orientation data from sensors.
class DeviceOrientation {
  /// Yaw/Heading - rotation around vertical axis (0-360°, 0=North)
  final double yaw;

  /// Pitch - tilt forward/backward (-90 to +90°)
  final double pitch;

  /// Roll - tilt left/right (-180 to +180°)
  final double roll;

  /// Raw magnetometer heading (compass heading, may have errors)
  final double compassHeading;

  /// Timestamp of the measurement
  final DateTime timestamp;

  const DeviceOrientation({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.compassHeading,
    required this.timestamp,
  });

  /// Whether the device is held roughly level (good for star observation).
  bool get isLevel => pitch.abs() < 15 && roll.abs() < 15;

  /// Whether device is pointing near zenith (looking straight up).
  bool get isPointingUp => pitch > 70;

  @override
  String toString() =>
      'Orientation(yaw=${yaw.toStringAsFixed(1)}°, pitch=${pitch.toStringAsFixed(1)}°, roll=${roll.toStringAsFixed(1)}°)';
}

/// Service for tracking device orientation using sensors.
///
/// Combines accelerometer, gyroscope, and magnetometer data to provide
/// accurate device orientation for star alignment.
class DeviceOrientationService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Raw sensor data
  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _magX = 0, _magY = 0, _magZ = 0;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  // Filtered orientation
  double _yaw = 0;
  double _pitch = 0;
  double _roll = 0;
  double _compassHeading = 0;

  // Complementary filter parameters
  static const double _alpha = 0.96; // Gyro weight (higher = more gyro)
  DateTime? _lastUpdate;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  DeviceOrientation get currentOrientation => DeviceOrientation(
        yaw: _yaw,
        pitch: _pitch,
        roll: _roll,
        compassHeading: _compassHeading,
        timestamp: DateTime.now(),
      );

  // Mock sensor streams
  Stream<AccelerometerEvent> accelerometerEventStream({Duration? samplingPeriod}) {
    return Stream.periodic(samplingPeriod ?? const Duration(milliseconds: 20), (_) {
      return AccelerometerEvent(0.0, 0.0, 9.8);
    });
  }

  Stream<MagnetometerEvent> magnetometerEventStream({Duration? samplingPeriod}) {
    return Stream.periodic(samplingPeriod ?? const Duration(milliseconds: 20), (_) {
      return MagnetometerEvent(0.0, 20.0, -40.0);
    });
  }

  Stream<GyroscopeEvent> gyroscopeEventStream({Duration? samplingPeriod}) {
    return Stream.periodic(samplingPeriod ?? const Duration(milliseconds: 20), (_) {
      return GyroscopeEvent(0.0, 0.0, 0.0);
    });
  }

  /// Start listening to sensor updates.
  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _lastUpdate = DateTime.now();

    // Subscribe to accelerometer
    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onAccelerometerEvent);

    // Subscribe to magnetometer
    _magSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onMagnetometerEvent);

    // Subscribe to gyroscope
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onGyroscopeEvent);

    notifyListeners();
  }

  /// Stop listening to sensor updates.
  void stop() {
    _accelSubscription?.cancel();
    _magSubscription?.cancel();
    _gyroSubscription?.cancel();

    _accelSubscription = null;
    _magSubscription = null;
    _gyroSubscription = null;

    _isRunning = false;
    notifyListeners();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    _accelX = event.x;
    _accelY = event.y;
    _accelZ = event.z;

    _updateOrientation();
  }

  void _onMagnetometerEvent(MagnetometerEvent event) {
    _magX = event.x;
    _magY = event.y;
    _magZ = event.z;

    _updateCompassHeading();
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    _gyroX = event.x;
    _gyroY = event.y;
    _gyroZ = event.z;
  }

  void _updateOrientation() {
    final now = DateTime.now();
    final dt = _lastUpdate != null
        ? (now.difference(_lastUpdate!).inMicroseconds / 1000000.0)
        : 0.02;
    _lastUpdate = now;

    // Calculate pitch and roll from accelerometer
    final accelMagnitude =
        math.sqrt(_accelX * _accelX + _accelY * _accelY + _accelZ * _accelZ);

    if (accelMagnitude < 0.1) return; // Device in freefall, skip

    // Normalize accelerometer
    final ax = _accelX / accelMagnitude;
    final ay = _accelY / accelMagnitude;
    final az = _accelZ / accelMagnitude;

    // Calculate pitch and roll from accelerometer (in radians)
    final accelPitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    final accelRoll = math.atan2(ay, az);

    // Complementary filter: combine accelerometer and gyroscope
    // Gyro gives short-term accuracy, accelerometer provides long-term stability
    _pitch = _alpha * (_pitch + _gyroY * dt) +
        (1 - _alpha) * _toDegrees(accelPitch);
    _roll =
        _alpha * (_roll + _gyroX * dt) + (1 - _alpha) * _toDegrees(accelRoll);

    // Clamp values
    _pitch = _pitch.clamp(-90.0, 90.0);
    _roll = _normalizeAngle180(_roll);

    notifyListeners();
  }

  void _updateCompassHeading() {
    // Tilt compensation for magnetometer
    final pitchRad = _toRadians(_pitch);
    final rollRad = _toRadians(_roll);

    // Compensate magnetometer readings for device tilt
    final magXComp = _magX * math.cos(pitchRad) +
        _magY * math.sin(rollRad) * math.sin(pitchRad) -
        _magZ * math.cos(rollRad) * math.sin(pitchRad);

    final magYComp =
        _magY * math.cos(rollRad) + _magZ * math.sin(rollRad);

    // Calculate heading
    double heading = math.atan2(-magYComp, magXComp);
    heading = _toDegrees(heading);

    // Normalize to 0-360
    _compassHeading = _normalizeAngle360(heading);

    // Apply complementary filter to yaw
    final now = DateTime.now();
    final dt = _lastUpdate != null
        ? (now.difference(_lastUpdate!).inMicroseconds / 1000000.0)
        : 0.02;

    // Integrate gyroscope for yaw
    double gyroYaw = _yaw + _toDegrees(_gyroZ) * dt;
    gyroYaw = _normalizeAngle360(gyroYaw);

    // Blend gyro and magnetometer
    // Handle wraparound at 0/360 boundary
    double diff = _compassHeading - gyroYaw;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    _yaw = _normalizeAngle360(gyroYaw + (1 - _alpha) * diff);

    notifyListeners();
  }

  /// Get the device's pointing direction as azimuth (0-360°, 0=North).
  /// This accounts for device tilt when the phone is held up to the sky.
  double getPointingAzimuth() {
    // When device is tilted up, the top of the phone points in a direction
    // that combines yaw and pitch
    if (_pitch.abs() < 45) {
      // Device is mostly level, use compass heading
      return _compassHeading;
    } else {
      // Device is tilted significantly, use yaw
      return _yaw;
    }
  }

  /// Get the device's pointing elevation (how high it's pointing).
  /// 0° = horizontal, 90° = straight up
  double getPointingElevation() {
    // When phone is held normally, pitch indicates elevation
    // Positive pitch = phone tilted back = pointing up
    return (90 - _pitch.abs()).clamp(0.0, 90.0);
  }

  // Utility methods
  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  static double _normalizeAngle360(double angle) {
    double result = angle % 360.0;
    if (result < 0) result += 360.0;
    return result;
  }

  static double _normalizeAngle180(double angle) {
    double result = angle % 360.0;
    if (result > 180) result -= 360;
    if (result < -180) result += 360;
    return result;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}