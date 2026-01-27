import 'dart:math' as math;
import 'package:flutter/material.dart' hide NavigationMode;
import 'package:Bahaar/models/celestial/star_model.dart';
import 'package:Bahaar/services/celestial_navigation_service.dart';
import 'package:Bahaar/services/device_orientation_service.dart';
import 'package:Bahaar/services/navigation_mode_manager.dart';

/// Screen for manual star alignment to correct compass heading.
///
/// Features:
/// - List of visible navigation stars
/// - Device orientation display
/// - Alignment instructions
/// - Confidence level indicator
/// - Night-safe red UI option
class StarAlignmentScreen extends StatefulWidget {
  final CelestialNavigationService celestialService;
  final DeviceOrientationService orientationService;
  final NavigationModeManager modeManager;

  const StarAlignmentScreen({
    super.key,
    required this.celestialService,
    required this.orientationService,
    required this.modeManager,
  });

  @override
  State<StarAlignmentScreen> createState() => _StarAlignmentScreenState();
}

class _StarAlignmentScreenState extends State<StarAlignmentScreen> {
  bool _nightMode = true;
  Star? _selectedStar;
  bool _isAligning = false;
  StarAlignmentResult? _lastResult;

  @override
  void initState() {
    super.initState();
    widget.orientationService.addListener(_onOrientationUpdate);
    widget.celestialService.addListener(_onCelestialUpdate);
  }

  @override
  void dispose() {
    widget.orientationService.removeListener(_onOrientationUpdate);
    widget.celestialService.removeListener(_onCelestialUpdate);
    super.dispose();
  }

  void _onOrientationUpdate() {
    if (mounted) setState(() {});
  }

  void _onCelestialUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = _nightMode ? _nightTheme : Theme.of(context);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _nightMode ? Colors.black : null,
        appBar: AppBar(
          title: const Text('Star Alignment'),
          backgroundColor: _nightMode ? Colors.black : null,
          foregroundColor: _nightMode ? Colors.red.shade300 : null,
          actions: [
            IconButton(
              icon: Icon(_nightMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _nightMode = !_nightMode),
              tooltip: _nightMode ? 'Day Mode' : 'Night Mode',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildStatusHeader(),
              _buildOrientationDisplay(),
              Expanded(child: _buildStarList()),
              if (_selectedStar != null) _buildAlignmentPanel(),
              _buildSafetyNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final correction = widget.celestialService.headingCorrection;
    final confidence = widget.celestialService.correctionConfidence;
    final mode = widget.modeManager.activeMode;

    return Container(
      padding: const EdgeInsets.all(16),
      color: _nightMode ? Colors.grey.shade900 : Colors.grey.shade100,
      child: Row(
        children: [
          _buildModeIndicator(mode),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heading Correction: ${correction.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: _nightMode ? Colors.red.shade300 : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildConfidenceBar(confidence),
              ],
            ),
          ),
          if (widget.celestialService.alignmentHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAlignment,
              tooltip: 'Reset Alignment',
              color: _nightMode ? Colors.red.shade300 : null,
            ),
        ],
      ),
    );
  }

  Widget _buildModeIndicator(NavigationMode mode) {
    final IconData icon;
    final String label;
    Color color;

    switch (mode) {
      case NavigationMode.gps:
        icon = Icons.gps_fixed;
        label = 'GPS';
        color = Colors.green;
      case NavigationMode.star:
        icon = Icons.star;
        label = 'STAR';
        color = Colors.amber;
      case NavigationMode.compass:
        icon = Icons.explore;
        label = 'COMPASS';
        color = Colors.blue;
    }

    if (_nightMode) color = Colors.red.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Row(
      children: [
        Text(
          'Confidence: ',
          style: TextStyle(
            color: _nightMode ? Colors.red.shade200 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: _nightMode ? Colors.grey.shade800 : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              confidence >= 0.7
                  ? (_nightMode ? Colors.red.shade400 : Colors.green)
                  : (_nightMode ? Colors.red.shade700 : Colors.orange),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: _nightMode ? Colors.red.shade300 : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationDisplay() {
    final orientation = widget.orientationService.currentOrientation;
    final trueHeading = widget.celestialService.trueHeading;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompassWidget(trueHeading),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrientationRow('Compass', orientation.compassHeading),
              _buildOrientationRow('True Heading', trueHeading),
              _buildOrientationRow('Pitch', orientation.pitch),
              _buildOrientationRow('Roll', orientation.roll),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassWidget(double heading) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _CompassPainter(
          heading: heading,
          color: _nightMode ? Colors.red.shade300 : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildOrientationRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: _nightMode ? Colors.red.shade200 : Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}°',
            style: TextStyle(
              color: _nightMode ? Colors.red.shade300 : null,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarList() {
    final candidates = widget.celestialService.getAlignmentCandidates();

    if (candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: _nightMode ? Colors.red.shade300 : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No visible stars',
                style: TextStyle(
                  color: _nightMode ? Colors.red.shade300 : null,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'GPS position required to calculate star positions.\nEnsure you are outdoors with clear sky.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _nightMode ? Colors.red.shade200 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: candidates.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final position = candidates[index];
        return _buildStarTile(position);
      },
    );
  }

  Widget _buildStarTile(StarPosition position) {
    final isSelected = _selectedStar == position.star;
    final textColor = _nightMode ? Colors.red.shade300 : null;

    return Card(
      color: isSelected
          ? (_nightMode ? Colors.red.shade900 : Colors.blue.shade50)
          : (_nightMode ? Colors.grey.shade900 : null),
      child: ListTile(
        leading: Icon(
          Icons.star,
          color: _nightMode
              ? Colors.red.shade300
              : _getMagnitudeColor(position.star.magnitude),
          size: 32,
        ),
        title: Text(
          position.star.name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${position.star.arabic} • ${position.star.constellation}\n'
          'Alt: ${position.altitude.toStringAsFixed(1)}° • Az: ${position.azimuth.toStringAsFixed(1)}° ${position.cardinalDirection}',
          style: TextStyle(
            color: _nightMode ? Colors.red.shade200 : null,
          ),
        ),
        isThreeLine: true,
        trailing: position.star.name == 'Polaris'
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _nightMode ? Colors.red.shade800 : Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NORTH',
                  style: TextStyle(
                    color: _nightMode ? Colors.red.shade100 : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              )
            : null,
        onTap: () => setState(() => _selectedStar = position.star),
      ),
    );
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude < 0) return Colors.white;
    if (magnitude < 1) return Colors.yellow;
    if (magnitude < 2) return Colors.amber;
    return Colors.orange;
  }

  Widget _buildAlignmentPanel() {
    final starPosition = _selectedStar!.calculatePosition(
      observerLat: widget.celestialService.observerPosition!.latitude,
      observerLon: widget.celestialService.observerPosition!.longitude,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      color: _nightMode ? Colors.grey.shade900 : Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Align with ${_selectedStar!.name}',
            style: TextStyle(
              color: _nightMode ? Colors.red.shade300 : null,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Point your device at the star:\n'
            '• Look ${starPosition.cardinalDirection} at ${starPosition.azimuth.toStringAsFixed(0)}°\n'
            '• Elevation: ${starPosition.altitude.toStringAsFixed(0)}° above horizon',
            style: TextStyle(
              color: _nightMode ? Colors.red.shade200 : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_lastResult != null) ...[
            Text(
              'Last alignment: ${_lastResult!.correctionOffset.toStringAsFixed(1)}° correction '
              '(${(_lastResult!.confidence * 100).toStringAsFixed(0)}% confidence)',
              style: TextStyle(
                color: _nightMode ? Colors.red.shade200 : Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedStar = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _nightMode ? Colors.red.shade300 : null,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isAligning ? null : _performAlignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nightMode ? Colors.red.shade800 : null,
                    foregroundColor: _nightMode ? Colors.red.shade100 : null,
                  ),
                  icon: _isAligning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isAligning ? 'Aligning...' : 'Confirm Alignment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: _nightMode ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.amber.shade50,
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: _nightMode ? Colors.red.shade300 : Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Directional aid only. Requires clear sky. Not sole navigation tool.',
              style: TextStyle(
                color: _nightMode ? Colors.red.shade200 : Colors.amber.shade900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performAlignment() async {
    if (_selectedStar == null) return;

    setState(() => _isAligning = true);

    // Brief delay to allow user to stabilize device
    await Future.delayed(const Duration(milliseconds: 500));

    final result = widget.celestialService.alignWithStar(_selectedStar!);

    setState(() {
      _isAligning = false;
      _lastResult = result;
    });

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alignment complete: ${result.correctionOffset.toStringAsFixed(1)}° correction',
          ),
          backgroundColor: _nightMode ? Colors.red.shade800 : Colors.green,
        ),
      );
    }
  }

  void _resetAlignment() {
    widget.celestialService.resetAlignment();
    setState(() {
      _lastResult = null;
      _selectedStar = null;
    });
  }

  ThemeData get _nightTheme => ThemeData.dark().copyWith(
        primaryColor: Colors.red.shade300,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey.shade900,
        colorScheme: ColorScheme.dark(
          primary: Colors.red.shade300,
          secondary: Colors.red.shade400,
        ),
      );
}

/// Custom painter for compass display.
class _CompassPainter extends CustomPainter {
  final double heading;
  final Color color;

  _CompassPainter({required this.heading, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw circle
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw cardinal directions
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - heading) * math.pi / 180;
      final x = center.dx + (radius - 15) * math.sin(angle);
      final y = center.dy - (radius - 15) * math.cos(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: directions[i] == 'N' ? color : color.withValues(alpha: 0.5),
          fontWeight: directions[i] == 'N' ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw needle (always points up - device direction)
    final needlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final needlePath = Path()
      ..moveTo(center.dx, center.dy - radius + 20)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();

    canvas.drawPath(needlePath, needlePaint);

    // Draw center dot
    canvas.drawCircle(center, 4, needlePaint);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      heading != oldDelegate.heading || color != oldDelegate.color;
}
