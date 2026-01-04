import 'package:flutter/material.dart';
import '../utilites/weather_api_service.dart';
import '../models/weather_response_model.dart';

class WeatherList extends StatefulWidget {
  const WeatherList({super.key});

  @override
  State<WeatherList> createState() => _WeatherListState();
}

class _WeatherListState extends State<WeatherList> {
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
    return Container(
      color: Colors.blue,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network (
                'https:${weatherData?.currentWeather.condition.icon ?? ''}',
                width: 100,

              ),
              Text('Location: ${weatherData!.location.name}, ${weatherData!.location.country}'),
              SizedBox(height: 10),
              Text('Temperature: ${weatherData!.currentWeather.temp_c} °C'),
              SizedBox(height: 10),
              Text('Feels Like: ${weatherData!.currentWeather.feelslike_c} °C'),
              SizedBox(height: 10),
              Text('Wind Direction: ${weatherData!.currentWeather.wind_dir}'),
              SizedBox(height: 10),
              Text('Wind Degree: ${weatherData!.currentWeather.wind_degree}°'),
              SizedBox(height: 10),
              Text('Wind Gust: ${weatherData!.currentWeather.gust_kph} km/h'),
              SizedBox(height: 10),
              Text('Wind Speed: ${weatherData!.currentWeather.wind_kph} km/h'),
              SizedBox(height: 10),
              Text('Humidity: ${weatherData!.currentWeather.humidity}%'),
              SizedBox(height: 10),
              Text('Condition: ${weatherData!.currentWeather.condition.text}'),
              SizedBox(height: 10),
              Text('Last Updated: ${weatherData!.currentWeather.last_updated}'),
              SizedBox(height: 10),
              Text('Cloud Coverage: ${weatherData!.currentWeather.cloud}%'),
              SizedBox(height: 10),
              Text('UV Index: ${weatherData!.currentWeather.uv}'),
              SizedBox(height: 10),
              Text('Visibility: ${weatherData!.currentWeather.vis_km} km'),
              SizedBox(height: 10),
              Text('Pressure: ${weatherData!.currentWeather.pressure_mb} mb'),
              SizedBox(height: 10),
              Text('Dew Point: ${weatherData!.currentWeather.dewpoint_c} °C'),
              SizedBox(height: 10),
              Text('Heat Index: ${weatherData!.currentWeather.heatindex_c} °C'),
              SizedBox(height: 10),
              Text('Wind Chill: ${weatherData!.currentWeather.windchill_c} °C'),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
