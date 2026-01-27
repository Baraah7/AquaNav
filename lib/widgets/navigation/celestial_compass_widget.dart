import 'dart:math' as math;
import 'package:flutter/material.dart' hide NavigationMode;
import 'package:Bahaar/services/navigation_mode_manager.dart';

/// A compass widget that displays the corrected true heading.
///
/// Shows:
/// - Current heading with star correction applied
/// - Navigation mode indicator (GPS/STAR/COMPASS)
/// - Correction confidence level
/// - Cardinal directions
class CelestialCompassWidget extends StatelessWidget {
  final NavigationModeManager modeManager;
  final double size;
  final bool showDetails;

  const CelestialCompassWidget({
    super.key,
    required this.modeManager,
    this.size = 200,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modeManager,
      builder: (context, _) {
        final state = modeManager.currentState;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompass(context, state),
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildDetails(context, state),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCompass(BuildContext context, NavigationState state) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CelestialCompassPainter(
          heading: state.bestHeading,
          mode: state.activeMode,
          confidence: state.correctionConfidence,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.bestHeading.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _getCardinalDirection(state.bestHeading),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getModeColor(state.activeMode),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, NavigationState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildModeChip(state.activeMode),
              Text(
                state.accuracyIndicator,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (state.activeMode == NavigationMode.star) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Correction: '),
                Text(
                  '${state.headingCorrection >= 0 ? '+' : ''}${state.headingCorrection.toStringAsFixed(1)}°',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: state.correctionConfidence,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      state.correctionConfidence >= 0.7
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip(NavigationMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getModeColor(mode).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getModeColor(mode)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getModeIcon(mode), size: 16, color: _getModeColor(mode)),
          const SizedBox(width: 4),
          Text(
            _getModeName(mode),
            style: TextStyle(
              color: _getModeColor(mode),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getCardinalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading < 67.5) return 'NE';
    if (heading < 112.5) return 'E';
    if (heading < 157.5) return 'SE';
    if (heading < 202.5) return 'S';
    if (heading < 247.5) return 'SW';
    if (heading < 292.5) return 'W';
    return 'NW';
  }

  Color _getModeColor(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.gps:
        return Colors.green;
      case NavigationMode.star:
        return Colors.amber;
      case NavigationMode.compass:
        return Colors.blue;
    }
  }

  IconData _getModeIcon(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.gps:
        return Icons.gps_fixed;
      case NavigationMode.star:
        return Icons.star;
      case NavigationMode.compass:
        return Icons.explore;
    }
  }

  String _getModeName(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.gps:
        return 'GPS';
      case NavigationMode.star:
        return 'STAR';
      case NavigationMode.compass:
        return 'COMPASS';
    }
  }
}

class _CelestialCompassPainter extends CustomPainter {
  final double heading;
  final NavigationMode mode;
  final double confidence;

  _CelestialCompassPainter({
    required this.heading,
    required this.mode,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Get mode color
    final modeColor = _getModeColor(mode);

    // Draw outer ring
    final ringPaint = Paint()
      ..color = modeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, ringPaint);

    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 10) {
      final angle = (i - heading) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final tickLength = isCardinal ? 15.0 : (i % 30 == 0 ? 10.0 : 5.0);

      final start = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      if (isCardinal) {
        tickPaint.color = modeColor;
        tickPaint.strokeWidth = 2;
      } else {
        tickPaint.color = Colors.grey.shade400;
        tickPaint.strokeWidth = 1;
      }

      canvas.drawLine(start, end, tickPaint);
    }

    // Draw cardinal letters
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final cardinals = {'N': 0, 'E': 90, 'S': 180, 'W': 270};

    cardinals.forEach((letter, degrees) {
      final angle = (degrees - heading) * math.pi / 180;
      final x = center.dx + (radius - 25) * math.sin(angle);
      final y = center.dy - (radius - 25) * math.cos(angle);

      textPainter.text = TextSpan(
        text: letter,
        style: TextStyle(
          color: letter == 'N' ? modeColor : Colors.grey.shade600,
          fontWeight: letter == 'N' ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    });

    // Draw north pointer (fixed at top)
    final pointerPaint = Paint()
      ..color = modeColor
      ..style = PaintingStyle.fill;

    final pointerPath = Path()
      ..moveTo(center.dx, center.dy - radius + 30)
      ..lineTo(center.dx - 8, center.dy - radius + 45)
      ..lineTo(center.dx + 8, center.dy - radius + 45)
      ..close();

    canvas.drawPath(pointerPath, pointerPaint);
  }

  Color _getModeColor(NavigationMode mode) {
    switch (mode) {
      case NavigationMode.gps:
        return Colors.green;
      case NavigationMode.star:
        return Colors.amber;
      case NavigationMode.compass:
        return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(_CelestialCompassPainter oldDelegate) =>
      heading != oldDelegate.heading ||
      mode != oldDelegate.mode ||
      confidence != oldDelegate.confidence;
}
