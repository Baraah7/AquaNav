import '../models/day_model.dart';
import '../models/astro_model.dart';
import '../models/hour_model.dart';

class forecast_day {
  final String date;
  final day_model day;
  final astro_model astro;
  final List<hour_model> hour;

  forecast_day({
    required this.date,
    required this.day,
    required this.astro,
    required this.hour,
  });

  factory forecast_day.fromJson(Map<String, dynamic> json) {
    var hourList = json['hour'] as List;
    List<hour_model> hourModels =
        hourList.map((i) => hour_model.fromJson(i)).toList();

    return forecast_day(
      date: json['date'] as String,
      day: day_model.fromJson(json['day']),
      astro: astro_model.fromJson(json['astro']),
      hour: hourModels,
    );
  }
}