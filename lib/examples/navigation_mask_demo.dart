import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/map/navigation_mask.dart';

/// Demo screen showing navigation mask functionality
/// This demonstrates land/water validation and route planning
class NavigationMaskDemo extends StatefulWidget {
  const NavigationMaskDemo({super.key});

  @override
  State<NavigationMaskDemo> createState() => _NavigationMaskDemoState();
}

class _NavigationMaskDemoState extends State<NavigationMaskDemo> {
  final NavigationMask _navigationMask = NavigationMask();
  bool _maskInitialized = false;
  final MapController _mapController = MapController();
  final List<LatLng> _markedPoints = [];
  String _statusMessage = 'Tap on the map to test locations';

  @override
  void initState() {
    super.initState();
    _initMask();
  }

  Future<void> _initMask() async {
    try {
      await _navigationMask.initialize();
      setState(() {
        _maskInitialized = true;
        _statusMessage = 'Navigation mask ready! Tap to test locations';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading mask: $e';
      });
    }
  }

  void _handleTap(LatLng point) {
    if (!_maskInitialized) return;

    final isNavigable = _navigationMask.isPointNavigable(point);

    setState(() {
      _markedPoints.add(point);
      if (_markedPoints.length > 10) {
        _markedPoints.removeAt(0);
      }

      _statusMessage = isNavigable
          ? '✓ Water - Navigable location'
          : '✗ Land - Not navigable';
    });

    // If on land, find nearest water
    if (!isNavigable) {
      final nearestWater = _navigationMask.findNearestWaterPoint(point);
      if (nearestWater != null) {
        final distance = _navigationMask.calculateDistance(point, nearestWater);
        setState(() {
          _statusMessage += '\nNearest water: ${distance.toStringAsFixed(0)}m away';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Mask Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(26.1, 50.6), // Bahrain center
              initialZoom: 10,
              onTap: (_, point) => _handleTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahaar.bahaarapp',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_markedPoints.isNotEmpty)
                MarkerLayer(
                  markers: _markedPoints.map((point) {
                    final isNavigable = _maskInitialized
                        ? _navigationMask.isPointNavigable(point)
                        : false;
                    return Marker(
                      point: point,
                      width: 30,
                      height: 30,
                      child: Icon(
                        isNavigable ? Icons.check_circle : Icons.cancel,
                        color: isNavigable ? Colors.green : Colors.red,
                        size: 25,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          // Status panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _maskInitialized ? Icons.check_circle : Icons.hourglass_empty,
                        color: _maskInitialized ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _maskInitialized ? 'Mask Loaded' : 'Loading...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points marked: ${_markedPoints.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Test points button
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: _testKnownLocations,
              child: const Icon(Icons.science),
            ),
          ),
        ],
      ),
    );
  }

  void _testKnownLocations() {
    if (!_maskInitialized) return;

    final testPoints = [
      {'name': 'Bahrain Island (Land)', 'point': const LatLng(26.0667, 50.5577)},
      {'name': 'Persian Gulf (Water)', 'point': const LatLng(26.2, 50.7)},
      {'name': 'Muharraq (Land)', 'point': const LatLng(26.2572, 50.6115)},
    ];

    final results = StringBuffer('Test Results:\n\n');
    for (final test in testPoints) {
      final point = test['point'] as LatLng;
      final isNavigable = _navigationMask.isPointNavigable(point);
      results.writeln('${test['name']}: ${isNavigable ? "✓ Water" : "✗ Land"}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Tests'),
        content: Text(results.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
