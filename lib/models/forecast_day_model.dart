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
    try {
      print('Parsing forecast_day with keys: ${json.keys.toList()}');

      if (json['date'] == null) throw Exception('Missing "date" field');
      if (json['day'] == null) throw Exception('Missing "day" field');
      if (json['astro'] == null) throw Exception('Missing "astro" field');
      if (json['hour'] == null) throw Exception('Missing "hour" field');

      print('Parsing day data...');
      final dayData = day_model.fromJson(json['day']);
      print('Day data parsed successfully');

      print('Parsing astro data...');
      final astroData = astro_model.fromJson(json['astro']);
      print('Astro data parsed successfully');

      print('Parsing hour data...');
      var hourList = json['hour'] as List;
      print('Hour list length: ${hourList.length}');
      List<hour_model> hourModels = [];
      for (int i = 0; i < hourList.length; i++) {
        try {
          hourModels.add(hour_model.fromJson(hourList[i]));
        } catch (e) {
          print('Error parsing hour $i: $e');
          rethrow;
        }
      }
      print('All hours parsed successfully');

      return forecast_day(
        date: json['date'] is String ? json['date'] as String : json['date'].toString(),
        day: dayData,
        astro: astroData,
        hour: hourModels,
      );
    } catch (e, stackTrace) {
      print('ERROR in forecast_day.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}