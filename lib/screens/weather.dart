import 'package:flutter/material.dart';
import '../utilities/weather_api_service.dart';
import '../models/weather/weather_response_model.dart';
import '../widgets/weather/weather_list.dart';
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
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Starting to fetch weather data...');
      final weather_response_model data = await weatherService.getWeather(
        "Manama",
        false,
        1,
        false,
      );
      print('Weather data received successfully');

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Weather',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator()
            else if (errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    'Error: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadWeatherData,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (weatherData != null)
              WeatherList(weatherData: weatherData!)
            else
              const Text('No data available'),
          ],
        ),
      ),
    );
  }
}

