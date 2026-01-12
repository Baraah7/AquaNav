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
    try {
      print('=== Parsing weather_response_model ===');
      print('JSON keys: ${json.keys.toList()}');

      // Parse location
      if (json['location'] == null) {
        throw Exception('Missing "location" field in API response');
      }
      print('Parsing location...');
      final location = location_model.fromJson(json['location']);
      print('Location parsed successfully: ${location.name}');

      // Parse current weather
      if (json['current'] == null) {
        throw Exception('Missing "current" field in API response');
      }
      print('Parsing current weather...');
      final currentWeather = current_weather_model.fromJson(json['current']);
      print('Current weather parsed successfully');

      // Parse forecast (optional)
      forecast_model? forecast;
      if (json['forecast'] != null) {
        print('Parsing forecast...');
        forecast = forecast_model.fromJson(json['forecast']);
        print('Forecast parsed successfully');
      } else {
        print('No forecast data in response');
      }

      print('=== weather_response_model parsed successfully ===');
      return weather_response_model(
        location: location,
        currentWeather: currentWeather,
        forecast: forecast,
      );
    } catch (e, stackTrace) {
      print('ERROR in weather_response_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}
