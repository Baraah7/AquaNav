import 'forecast_day_model.dart';

class forecast_model {
  final forecast_day forecastDay;

  forecast_model({
    required this.forecastDay,
  });

  factory forecast_model.fromJson(Map<String, dynamic> json) {
    return forecast_model(
      forecastDay: forecast_day.fromJson(json['forecastDay']),
    );
  }
}