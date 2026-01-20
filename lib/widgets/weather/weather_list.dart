import 'package:Bahaar/widgets/weather/weather_card.dart';
import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';

class WeatherList extends StatelessWidget {
  final weather_response_model weatherData;

  const WeatherList({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F7FA),
            Color.fromARGB(255, 117, 183, 193),
          ],
        ),
      ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.network(
                'https:${weatherData.currentWeather.condition.icon}',
                width: 100,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    '${weatherData.location.name}, ${weatherData.location.country}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 1.8,
          ),
          children: [
            weather_card(
            'Temperature',
            '${weatherData.currentWeather.temp_c} °C',
          ),
          weather_card(
            'Feels Like',
            '${weatherData.currentWeather.feelslike_c} °C',
          ),
          weather_card(
            'Wind Direction',
            weatherData.currentWeather.wind_dir,
          ),
          weather_card(
            'Wind Degree',
            '${weatherData.currentWeather.wind_degree}°',
          ),
          weather_card(
            'Wind Gust',
            '${weatherData.currentWeather.gust_kph} km/h',
          ),
          weather_card(
            'Wind Speed',
            '${weatherData.currentWeather.wind_kph} km/h',
          ),
          weather_card('Humidity', '${weatherData.currentWeather.humidity}%'),
          weather_card(
            'Condition',
            weatherData.currentWeather.condition.text,
          ),
          weather_card(
            'Last Updated',
            weatherData.currentWeather.last_updated,
          ),
          weather_card(
            'Cloud Coverage',
            '${weatherData.currentWeather.cloud}%',
          ),
          weather_card('UV Index', '${weatherData.currentWeather.uv}'),
          weather_card('Visibility', '${weatherData.currentWeather.vis_km} km'),
          weather_card(
            'Pressure',
            '${weatherData.currentWeather.pressure_mb} mb',
          ),
          weather_card(
            'Dew Point',
            '${weatherData.currentWeather.dewpoint_c} °C',
          ),
          weather_card(
            'Heat Index',
            '${weatherData.currentWeather.heatindex_c} °C',
          ),
          weather_card(
            'Wind Chill',
            '${weatherData.currentWeather.windchill_c} °C',
          ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F7FA),
                Color.fromARGB(255, 117, 183, 193),
              ],
            ),
          ),
          child: const Text(
            'Forecast',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (weatherData.forecast != null)
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1.8,
            ),
            children: [
              weather_card(
                'Avg Temperature',
                '${weatherData.forecast!.forecastDay.day.avgtemp_c} °C',
              ),
              weather_card(
                'Max Temperature',
                '${weatherData.forecast!.forecastDay.day.maxtemp_c} °C',
              ),
              weather_card(
                'Min Temperature',
                '${weatherData.forecast!.forecastDay.day.mintemp_c} °C',
              ),
              weather_card(
                'Max Wind Speed',
                '${weatherData.forecast!.forecastDay.day.maxwind_kph} km/h',
              ),
              weather_card(
                'Total Precipitation',
                '${weatherData.forecast!.forecastDay.day.totalprecip_mm} mm',
              ),
              weather_card(
                'Average Humidity',
                '${weatherData.forecast!.forecastDay.day.avghumidity}%',
              ),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Forecast Not Available',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00695C),
              ),
            ),
          ),
      ],
    );
  }
}
