import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapScreen();
}

class _MapScreen extends State<Map> {
  MapController mapController = M
  Location location = Location();
  bool _serviceEnabled = false;
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();
    initLocation();
  }

  Future<void> initLocation() async {
    try {
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        log('Location service not enabled');
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          log('User denied location service');
          return;
        }
      }

      _permissionStatus = await location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        log('Location permission denied');
        _permissionStatus = await location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          log('User denied location permission');
          return;
        }
      }

      _locationData = await location.getLocation();
      log('Location fetched: ${_locationData.toString()}');
      setState(() {});
    } catch (e) {
      log('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          flutterMap(_locationData)],
      ),
    );
  }
}
