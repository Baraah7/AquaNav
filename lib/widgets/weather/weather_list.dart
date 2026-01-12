import 'package:Bahaar/widgets/weather/weather_card.dart';
import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';

class WeatherList extends StatelessWidget {
  final weather_response_model weatherData;

  const WeatherList({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: GridView(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        children: [
          Image.network(
            'https:${weatherData.currentWeather.condition.icon}',
            width: 50,
          ),
          weather_card(
            'Location',
            '${weatherData.location.name}, ${weatherData.location.country}',
          ),
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
            '${weatherData.currentWeather.wind_dir}',
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
            '${weatherData.currentWeather.condition.text}',
          ),
          weather_card(
            'Last Updated',
            '${weatherData.currentWeather.last_updated}',
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
          const Text(" "),
          const Text("Forecast"),
          const Text(" "),
          ...weatherData.forecast != null
              ? [
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
                ]
              : [weather_card('Forecast', 'Not Available')],
        ],
      ),
    );
  }
}
