import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather/weather_response_model.dart';

// final apiKey = dotenv.env['weatherAPI'];
// String city = "Manama";
// String airQuality = "no";
// int days = 1; //optinonal
// String alerts = "no"; //optional
// String url =
//     "http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$city&days=$days&aqi=$airQuality&alerts=$alerts";

// Future<http.Response> fetchWeather() {
//   return http.get(Uri.parse(url));
// }

//here

class WeatherApiService {
  late final http.Client client;

  WeatherApiService({http.Client? client}) {
    if (client != null) {
      this.client = client;
    } else {
      this.client = http.Client();
    }
  }

  Future<weather_response_model> getWeather(
    String city,
    bool airQuality,
    int days,
    bool alert,
  ) async {
    final apiKey = dotenv.env['weatherAPI'];
    String aqi;
    String type;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("nooo api key in the env FILE!!!");
    }

    // bulid query parameters : old vesrion

    // if (airQuality == true) {
    //   aqi = "yes";
    // } else {
    //   aqi = "no";
    // }
    // if (alert == true) {
    //     alerts = "yes";
    //   } else {
    //     alerts = "no";
    //   }

    //new version

    final Map<String, String> queryParams = {
      'key': apiKey,
      'q': city,
      'aqi': airQuality ? 'yes' : 'no',
    };

    queryParams['days'] = days.toString();
  
    queryParams['alerts'] = alert ? 'yes' : 'no';
      //days and alerts are optional parameters
    // but both must be both either null or both not
    if (alert == null && days == null) {
       type = "current";
    } else    type = "forecast";
  
    try {
      print('=== Building API Request ===');
      print('Type: $type');
      print('City: $city');
      print('Query params: $queryParams');

      final uri = Uri.parse(
        'http://api.weatherapi.com/v1/$type.json'
      ).replace(queryParameters: queryParams);

      print('API Request URI: $uri');

      final response = await client.get(uri);

      print('=== API Response Received ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Length: ${response.body.length}');
      print('Response Body (first 1000 chars): ${response.body.substring(0, response.body.length > 1000 ? 1000 : response.body.length)}');

      if (response.statusCode == 200) {
        print('=== Parsing JSON Response ===');
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('JSON decoded successfully');
        print('Top-level keys: ${data.keys.toList()}');

        print('=== Creating weather_response_model ===');
        final weatherResponse = weather_response_model.fromJson(data);
        print('=== Weather data parsed successfully ===');
        return weatherResponse;
      } else if (response.statusCode == 400) {
        print('=== Bad Request (400) ===');
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']['message'] ?? 'City not found';
          print('API Error: $errorMessage');
          throw Exception('API Error: $errorMessage');
        } catch (e) {
          print('Failed to parse error response: $e');
          throw Exception('Bad request: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('=== Authentication Error (${response.statusCode}) ===');
        throw Exception(
          'Invalid API key. Please check your WEATHER_API_KEY in .env file',
        );
      } else {
        print('=== Server Error (${response.statusCode}) ===');
        print('Error body: ${response.body}');
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('=== EXCEPTION CAUGHT in getWeather ===');
      print('Exception: $e');
      print('Exception Type: ${e.runtimeType}');
      print('Stack Trace: $stackTrace');

      if (e is Exception) rethrow;
      throw Exception("Network or parsing error: $e");
    }
  }
}
