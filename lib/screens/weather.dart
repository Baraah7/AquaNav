import 'package:flutter/material.dart';
import '../utilites/weather_api_service.dart';
import '../models/weather_response_model.dart';
import '../widgets/weather_list.dart';
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
      }); 
    } catch (e) {
      // Handle error silently or show user-friendly message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Weather', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            if (weatherData != null) 
             const WeatherList()
            else 
             const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}