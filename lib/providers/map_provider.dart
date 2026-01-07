import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/map/map_model.dart';
import '../services/map_api_service.dart';
import '../services/location_service.dart';
import '../utilities/map_constants.dart';

final mapApiServiceProvider = Provider((ref) => MapApiService());
final locationServiceProvider = Provider((ref) => LocationService());

class MapState {
  final MapPosition? currentLocation;
  final double zoom;
  final List<FishingActivity> fishingActivities;
  final List<FishProbability> fishProbabilities;
  final List<RestrictedArea> restrictedAreas;
  final List<WeatherData> weatherData;
  final bool isLoading;
  final String? error;
  final Set<String> visibleLayers;

  MapState({
    this.currentLocation,
    this.zoom = MapConstants.defaultZoom,
    this.fishingActivities = const [],
    this.fishProbabilities = const [],
    this.restrictedAreas = const [],
    this.weatherData = const [],
    this.isLoading = false,
    this.error,
    this.visibleLayers = const {
      MapConstants.osmLayerId,
      MapConstants.seaMarksLayerId,
      MapConstants.fishingActivityLayerId,
      MapConstants.fishProbabilityLayerId,
      MapConstants.restrictedAreasLayerId,
      MapConstants.weatherLayerId,
    },
  });

  MapState copyWith({
    MapPosition? currentLocation,
    double? zoom,
    List<FishingActivity>? fishingActivities,
    List<FishProbability>? fishProbabilities,
    List<RestrictedArea>? restrictedAreas,
    List<WeatherData>? weatherData,
    bool? isLoading,
    String? error,
    Set<String>? visibleLayers,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      zoom: zoom ?? this.zoom,
      fishingActivities: fishingActivities ?? this.fishingActivities,
      fishProbabilities: fishProbabilities ?? this.fishProbabilities,
      restrictedAreas: restrictedAreas ?? this.restrictedAreas,
      weatherData: weatherData ?? this.weatherData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      visibleLayers: visibleLayers ?? this.visibleLayers,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final MapApiService apiService;
  final LocationService locationService;

  MapNotifier(this.apiService, this.locationService) : super(MapState());

  void setCurrentLocation(MapPosition location) {
    state = state.copyWith(currentLocation: location);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void toggleLayer(String layerId) {
    final newLayers = Set<String>.from(state.visibleLayers);
    if (newLayers.contains(layerId)) {
      newLayers.remove(layerId);
    } else {
      newLayers.add(layerId);
    }
    state = state.copyWith(visibleLayers: newLayers);
  }

  Future<void> loadCurrentLocation() async {
    try {
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        state = state.copyWith(currentLocation: location);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadFishingActivities() async {
    if (state.currentLocation == null) return;
    try {
      state = state.copyWith(isLoading: true, error: null);
      final activities = await apiService.getFishingActivities(
        lat: state.currentLocation!.latitude,
        lon: state.currentLocation!.longitude,
        radius: 50.0,
      );
      state = state.copyWith(fishingActivities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadFishProbabilities() async {
    if (state.currentLocation == null) return;
    try {
      state = state.copyWith(isLoading: true, error: null);
      final probabilities = await apiService.getFishProbabilityData(
        lat: state.currentLocation!.latitude,
        lon: state.currentLocation!.longitude,
        radius: 50.0,
      );
      state = state.copyWith(fishProbabilities: probabilities, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadWeatherData() async {
    if (state.currentLocation == null) return;
    try {
      state = state.copyWith(isLoading: true, error: null);
      final weather = await apiService.getWeatherData(
        lat: state.currentLocation!.latitude,
        lon: state.currentLocation!.longitude,
      );
      state = state.copyWith(weatherData: weather, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadRestrictedAreas() async {
    if (state.currentLocation == null) return;
    try {
      state = state.copyWith(isLoading: true, error: null);
      final areas = await apiService.getRestrictedAreas(
        lat: state.currentLocation!.latitude,
        lon: state.currentLocation!.longitude,
        radius: 100.0,
      );
      state = state.copyWith(restrictedAreas: areas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAllLayers() async {
    await Future.wait([
      loadFishingActivities(),
      loadFishProbabilities(),
      loadWeatherData(),
      loadRestrictedAreas(),
    ]);
  }

  void checkRestrictedAreaViolations() {
    if (state.currentLocation == null) return;
    final violatedAreas = locationService.checkRestrictedAreas(
      state.currentLocation!,
      state.restrictedAreas,
    );
    if (violatedAreas.isNotEmpty) {
      state = state.copyWith(
        error: 'You are in a restricted area: ${violatedAreas.first.name}',
      );
    }
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final apiService = ref.watch(mapApiServiceProvider);
  final locationService = ref.watch(locationServiceProvider);
  return MapNotifier(apiService, locationService);
});
