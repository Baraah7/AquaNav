import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_response_model.dart';

final apiKey = dotenv.env['weatherAPI'];
String city = "Manama";
String airQuality = "&aqi=no";
String url = "http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city$airQuality";

Future<http.Response> fetchWeather() {
  return http.get(Uri.parse(url)); 
}

class WeatherApiService {
  late final http.Client client;

  WeatherApiService({http.Client? client}) {
    if (client != null) {
      this.client = client;
    } else {
      this.client = http.Client();
    }
  }

  Future<weather_response_model> getCurrentWeather(
    String city,
    bool airQuality,
  ) async {
    final apiKey = dotenv.env['weatherAPI'];
    String aqi;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("nooo api key in the env FILE!!!");
    }

    if (airQuality == true) {
      aqi = "yes";
    } else {
      aqi = "no";
    }

    try {
      final uri = Uri.parse(
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&aqi=$aqi',
      );

      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return weather_response_model.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'City not found';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Invalid API key. Please check your WEATHER_API_KEY in .env file',
        );
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("CHECK YOUR NETWORK!");
    }
  }
}
