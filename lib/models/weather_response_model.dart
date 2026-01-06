import 'current_weather_model.dart';
import 'location_model.dart';
import 'forecast_model.dart';

class weather_response_model {
  final location_model location;
  final current_weather_model currentWeather;
  final forecast_model? forecast;

  // Getter to access currentWeather as 'current'
  current_weather_model get current => currentWeather;

  weather_response_model({
    required this.location,
    required this.currentWeather,
    this.forecast,
  });

  factory weather_response_model.fromJson(Map<String, dynamic> json) {
    return weather_response_model(
      location: location_model.fromJson(json['location']),
      currentWeather: current_weather_model.fromJson(json['current']),
      forecast: json['forecast'] != null ? forecast_model.fromJson(json['forecast']) : null,
    );
  }
}
