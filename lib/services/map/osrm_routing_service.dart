import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:Bahaar/models/navigation/route_model.dart';
import 'package:Bahaar/utilities/navigation_constants.dart';

/// Service for interfacing with OSRM (Open Source Routing Machine) for land-based routing
class OsrmRoutingService {
  final http.Client _client;
  final String _baseUrl;

  OsrmRoutingService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? NavigationConstants.osrmBaseUrl;

  /// Get a route between two points using OSRM
  ///
  /// [origin] - Starting point
  /// [destination] - Ending point
  /// [profile] - Routing profile (driving, walking, cycling)
  ///
  /// Returns a [RouteSegment] if successful, null if no route found
  Future<RouteSegment?> getRoute({
    required LatLng origin,
    required LatLng destination,
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < NavigationConstants.osrmMaxRetries) {
      try {
        attempts++;

        // Build OSRM request URL
        final url = Uri.parse(
          '$_baseUrl/route/v1/${profile.value}/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=true&alternatives=false',
        );

        log('OSRM request (attempt $attempts): $url');

        // Make HTTP request with timeout
        final response = await _client.get(url).timeout(
              Duration(seconds: NavigationConstants.osrmTimeoutSeconds),
            );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;

          // Check if route was found
          if (data['code'] == 'Ok' && data['routes'] != null) {
            final routes = data['routes'] as List;
            if (routes.isNotEmpty) {
              log('OSRM route found: ${routes[0]['distance']}m');
              return _parseOsrmResponse(data, SegmentType.land, profile);
            }
          }

          // No route found
          log('OSRM: No route found between points');
          return null;
        } else if (response.statusCode == 400) {
          // Bad request - likely no route possible
          log('OSRM: Bad request - no route possible (400)');
          return null;
        } else {
          throw Exception('OSRM HTTP error: ${response.statusCode}');
        }
      } on http.ClientException catch (e) {
        lastError = e;
        log('OSRM network error (attempt $attempts): $e');
      } on FormatException catch (e) {
        lastError = e;
        log('OSRM JSON parsing error: $e');
        return null; // Don't retry on parsing errors
      } catch (e) {
        lastError = Exception(e.toString());
        log('OSRM error (attempt $attempts): $e');
      }

      // Wait before retry (exponential backoff)
      if (attempts < NavigationConstants.osrmMaxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    // All retries failed
    log('OSRM: All retry attempts failed. Last error: $lastError');
    return null;
  }

  /// Parse OSRM response into a RouteSegment
  RouteSegment _parseOsrmResponse(
    Map<String, dynamic> data,
    SegmentType type,
    OsrmProfile profile,
  ) {
    final route = data['routes'][0] as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    final distance = (route['distance'] as num).toDouble();
    final duration = (route['duration'] as num).toInt();

    // Convert GeoJSON coordinates [lon, lat] to LatLng
    final points = coordinates
        .map((coord) => LatLng(coord[1] as double, coord[0] as double))
        .toList();

    return RouteSegment(
      type: type,
      geometry: points,
      distance: distance,
      duration: duration,
      transportMode: profile.transportMode,
    );
  }

  /// Get multiple route alternatives between two points
  ///
  /// Returns a list of alternative routes (max 3)
  Future<List<RouteSegment>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    try {
      // Build OSRM request URL with alternatives=true
      final url = Uri.parse(
        '$_baseUrl/route/v1/${profile.value}/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true&alternatives=true',
      );

      log('OSRM alternatives request: $url');

      final response = await _client.get(url).timeout(
            Duration(seconds: NavigationConstants.osrmTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok' && data['routes'] != null) {
          final routes = data['routes'] as List;
          log('OSRM: Found ${routes.length} alternative routes');

          return routes.map((routeData) {
            return _parseOsrmRouteData(routeData, SegmentType.land, profile);
          }).toList();
        }
      }

      log('OSRM: No alternative routes found');
      return [];
    } catch (e) {
      log('Error getting alternative routes: $e');
      return [];
    }
  }

  /// Parse a single route data object from OSRM
  RouteSegment _parseOsrmRouteData(
    Map<String, dynamic> routeData,
    SegmentType type,
    OsrmProfile profile,
  ) {
    final geometry = routeData['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    final distance = (routeData['distance'] as num).toDouble();
    final duration = (routeData['duration'] as num).toInt();

    final points = coordinates
        .map((coord) => LatLng(coord[1] as double, coord[0] as double))
        .toList();

    return RouteSegment(
      type: type,
      geometry: points,
      distance: distance,
      duration: duration,
      transportMode: profile.transportMode,
    );
  }

  /// Check if OSRM service is reachable
  Future<bool> isServiceAvailable() async {
    try {
      final url = Uri.parse('$_baseUrl/route/v1/driving/0,0;0.1,0.1');
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200 || response.statusCode == 400;
    } catch (e) {
      log('OSRM service check failed: $e');
      return false;
    }
  }

  /// Get estimated time and distance for a route without full geometry
  /// Useful for quick route preview
  Future<({double distance, int duration})?> getRouteEstimate({
    required LatLng origin,
    required LatLng destination,
    OsrmProfile profile = OsrmProfile.driving,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/${profile.value}/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=false&geometries=geojson&steps=false',
      );

      final response = await _client.get(url).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['code'] == 'Ok' && data['routes'] != null) {
          final route = data['routes'][0] as Map<String, dynamic>;
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toInt();

          return (distance: distance, duration: duration);
        }
      }

      return null;
    } catch (e) {
      log('Error getting route estimate: $e');
      return null;
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _client.close();
  }
}

/// OSRM routing profiles
enum OsrmProfile {
  driving('driving', 'car'),
  walking('foot', 'walk'),
  cycling('bike', 'bicycle');

  final String value;
  final String transportMode;

  const OsrmProfile(this.value, this.transportMode);

  /// Display name for UI
  String get displayName {
    switch (this) {
      case OsrmProfile.driving:
        return 'Driving';
      case OsrmProfile.walking:
        return 'Walking';
      case OsrmProfile.cycling:
        return 'Cycling';
    }
  }
}
