import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/services/navigation_mask.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapScreen();
}

class _MapScreen extends State<Map> {
  MapController mapController = MapController();
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;
  bool _mapReady = false;
  final NavigationMask _navigationMask = NavigationMask();
  bool _maskInitialized = false;

  @override
  void initState() {
    super.initState();
    initLocation();
    initNavigationMask();
  }

  Future<void> initNavigationMask() async {
    try {
      await _navigationMask.initialize();
      if (mounted) {
        setState(() {
          _maskInitialized = true;
        });
        log('Navigation mask initialized successfully');
      }
    } catch (e) {
      log('Error initializing navigation mask: $e');
    }
  }

  Future<void> initLocation() async {
    try {
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        log('Location service not enabled');
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          log('User denied location service');
          if (mounted) setState(() {});
          return;
        }
      }

      _permissionStatus = await location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        log('Location permission denied');
        _permissionStatus = await location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          log('User denied location permission');
          if (mounted) setState(() {});
          return;
        }
      }

      _locationData = await location.getLocation();
      log('Location fetched: ${_locationData.toString()}');
      if (mounted) {
        setState(() {});
        // Move to location only if map is ready
        _moveToLocationIfReady();
      }
    } catch (e) {
      log('Error getting location: $e');
      if (mounted) setState(() {});
    }
  }

  void _moveToLocationIfReady() {
    if (_mapReady && _locationData != null) {
      final targetLocation = LatLng(_locationData!.latitude ?? 0, _locationData!.longitude ?? 0);

      // Validate location against navigation mask if initialized
      if (_maskInitialized) {
        final isNavigable = _navigationMask.isPointNavigable(targetLocation);
        if (!isNavigable) {
          log('Warning: Current location appears to be on land');
          // Optionally find nearest water location
          final nearestWater = _navigationMask.findNearestWaterPoint(targetLocation);
          if (nearestWater != null) {
            log('Nearest water location: ${nearestWater.latitude}, ${nearestWater.longitude}');
          }
        } else {
          log('Location validated: on navigable water');
        }
      }

      mapController.move(targetLocation, 16);
    }
  }

  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });
    _moveToLocationIfReady();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialZoom: 5,
              onMapReady: _onMapReady,
              onTap: (tapPosition, point) {
                // Validate tapped location if mask is initialized
                if (_maskInitialized) {
                  final isNavigable = _navigationMask.isPointNavigable(point);
                  log('Tapped location (${point.latitude}, ${point.longitude}): ${isNavigable ? "Water" : "Land"}');

                  if (!isNavigable) {
                    // Show a snackbar when user taps on land
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('This location is on land. Tap on water for navigation.'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Find Water',
                          onPressed: () {
                            final nearestWater = _navigationMask.findNearestWaterPoint(point);
                            if (nearestWater != null) {
                              mapController.move(nearestWater, mapController.camera.zoom);
                              log('Moved to nearest water: ${nearestWater.latitude}, ${nearestWater.longitude}');
                            }
                          },
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahaar.bahaarapp',
                maxZoom: 19,
                subdomains: const ['a', 'b', 'c'],
                additionalOptions: const {
                  'id': 'mapbox.streets',
                },
              ),
              if (_locationData != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_locationData!.latitude ?? 0, _locationData!.longitude ?? 0),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.my_location,
                        color: _maskInitialized && _navigationMask.isNavigable(
                          _locationData!.longitude ?? 0,
                          _locationData!.latitude ?? 0,
                        ) ? Colors.blue : Colors.orange,
                        size: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Navigation mask status indicator
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _maskInitialized ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _maskInitialized ? Icons.check_circle : Icons.hourglass_empty,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _maskInitialized ? 'Navigation Ready' : 'Loading Mask...',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
