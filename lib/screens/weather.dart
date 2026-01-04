import 'package:flutter/material.dart';
import 'dart:convert'; //for decoding and encoding JSON 
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utilites/weather_api_service.dart';
import '../models/weather_response_model.dart';
//Load configuration at runtime from a .env file which can be
// used throughout the application.


class Weather extends StatefulWidget {
  const Weather({super.key});

  @override
  State<Weather> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<Weather> {
  final weatherService = WeatherApiService();
  weather_response_model? weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final weather_response_model data = await weatherService.getCurrentWeather("Manama", false);

      setState(() {
        weatherData = data;
      }); //change it later to state management
    } catch (e) {
      print('Error loading weather data: $e');
      // You can also show an error message to the user here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            const Text('Hello, Weather!'),
            Text(weatherData != null
                ? 'Temperature: ${weatherData!.current.temp_c}°C'
                : 'Loading...'),
          ],
        ),
      ),
    );
  }
}
