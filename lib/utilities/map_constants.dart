class MapConstants {
  // Mapbox Configuration
  static const String mapboxPublicToken = 'YOUR_MAPBOX_PUBLIC_TOKEN';
  static const String mapboxStyleUrl = 'mapbox://styles/mapbox/satellite-streets-v12';
  
  // API Endpoints
  static const String globalFishingWatchApi = 'https://gateway.api.globalfishingwatch.org/v2';
  static const String copernicusMarineApi = 'https://marine.copernicus.eu/api';
  static const String openWeatherMarineApi = 'https://api.openweathermap.org/data/3.0';
  
  // API Keys (should be in environment variables)
  static const String gfwApiKey = 'YOUR_GFW_API_KEY';
  static const String copernicusApiKey = 'YOUR_COPERNICUS_API_KEY';
  static const String openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
  
  // Map Settings
  static const double defaultZoom = 10.0;
  static const double minZoom = 2.0;
  static const double maxZoom = 18.0;
  
  // Layer IDs
  static const String bathymetryLayerId = 'bathymetry-layer';
  static const String fishingActivityLayerId = 'fishing-activity-layer';
  static const String fishProbabilityLayerId = 'fish-probability-layer';
  static const String restrictedAreasLayerId = 'restricted-areas-layer';
  static const String weatherLayerId = 'weather-layer';
  
  // Colors
  static const String heatmapLowColor = '#00FF00';
  static const String heatmapMediumColor = '#FFFF00';
  static const String heatmapHighColor = '#FF0000';
  
  // Update Intervals (in seconds)
  static const int fishingActivityUpdateInterval = 300; // 5 minutes
  static const int weatherUpdateInterval = 600; // 10 minutes
  static const int fishProbabilityUpdateInterval = 1800; // 30 minutes
}