import 'package:flutter/material.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';

/// Overlay banner displaying active weather warnings on the map.
///
/// Color coded by severity:
/// - Yellow: Caution
/// - Orange: Dangerous
/// - Red: Blocked
class WeatherAlertOverlay extends StatelessWidget {
  final List<WeatherSafetyAssessment> warnings;
  final VoidCallback? onDismiss;

  const WeatherAlertOverlay({
    super.key,
    required this.warnings,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    // Use the worst safety level for the banner color
    final worstLevel = warnings
        .map((w) => w.level)
        .reduce((a, b) => a.index >= b.index ? a : b);

    // Collect all unique warning messages
    final allWarnings = warnings
        .expand((w) => w.warnings)
        .toSet()
        .toList();

    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: _backgroundColor(worstLevel),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _icon(worstLevel),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title(worstLevel),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allWarnings.join(' | '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.caution:
        return Colors.amber.shade700;
      case SafetyLevel.dangerous:
        return Colors.deepOrange;
      case SafetyLevel.blocked:
        return Colors.red.shade800;
      case SafetyLevel.safe:
        return Colors.green;
    }
  }

  IconData _icon(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.caution:
        return Icons.warning_amber_rounded;
      case SafetyLevel.dangerous:
        return Icons.dangerous;
      case SafetyLevel.blocked:
        return Icons.block;
      case SafetyLevel.safe:
        return Icons.check_circle;
    }
  }

  String _title(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.caution:
        return 'Weather Caution';
      case SafetyLevel.dangerous:
        return 'Dangerous Conditions';
      case SafetyLevel.blocked:
        return 'Navigation Blocked';
      case SafetyLevel.safe:
        return 'Conditions Safe';
    }
  }
}
