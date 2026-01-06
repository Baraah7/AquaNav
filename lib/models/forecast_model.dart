import 'forecast_day_model.dart';

class forecast_model {
  final List<forecast_day> forecastday;

  forecast_model({
    required this.forecastday,
  });

  // Getter to access first day easily
  forecast_day get forecastDay => forecastday.first;

  factory forecast_model.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing forecast_model with keys: ${json.keys.toList()}');

      if (json['forecastday'] == null) {
        throw Exception('Missing "forecastday" field in forecast');
      }

      var forecastList = json['forecastday'] as List;
      print('Forecast list length: ${forecastList.length}');

      List<forecast_day> forecastDays = [];
      for (int i = 0; i < forecastList.length; i++) {
        print('Parsing forecast day $i...');
        forecastDays.add(forecast_day.fromJson(forecastList[i] as Map<String, dynamic>));
      }

      print('All forecast days parsed successfully');
      return forecast_model(
        forecastday: forecastDays,
      );
    } catch (e, stackTrace) {
      print('ERROR in forecast_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}