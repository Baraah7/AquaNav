class day_model{
  final double maxtemp_c;
  final double maxtemp_f;
  final double mintemp_c;
  final double mintemp_f;
  final double avgtemp_c;
  final double avgtemp_f;
  final double maxwind_mph;
  final double maxwind_kph;
  final double totalprecip_mm;
  final double totalprecip_in;
  final double totalsnow_cm;
  final double avgvis_km;
  final double avgvis_miles;
  final int avghumidity;
  final bool daily_will_it_rain;
  final int daily_chance_of_rain;
  final bool daily_will_it_snow;
  final int daily_chance_of_snow;
  final String condition_text;
  final String condition_icon;

  day_model({
    required this.maxtemp_c,
    required this.maxtemp_f,
    required this.mintemp_c,
    required this.mintemp_f,
    required this.avgtemp_c,
    required this.avgtemp_f,
    required this.maxwind_mph,
    required this.maxwind_kph,
    required this.totalprecip_mm,
    required this.totalprecip_in,
    required this.totalsnow_cm,
    required this.avgvis_km,
    required this.avgvis_miles,
    required this.avghumidity,
    required this.daily_will_it_rain,
    required this.daily_chance_of_rain,
    required this.daily_will_it_snow,
    required this.daily_chance_of_snow,
    required this.condition_text,
    required this.condition_icon,
  });

  factory day_model.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing day_model with keys: ${json.keys.toList()}');

      if (json['condition'] == null) throw Exception('Missing "condition" field in day');

      return day_model(
        maxtemp_c: (json['maxtemp_c'] as num).toDouble(),
        maxtemp_f: (json['maxtemp_f'] as num).toDouble(),
        mintemp_c: (json['mintemp_c'] as num).toDouble(),
        mintemp_f: (json['mintemp_f'] as num).toDouble(),
        avgtemp_c: (json['avgtemp_c'] as num).toDouble(),
        avgtemp_f: (json['avgtemp_f'] as num).toDouble(),
        maxwind_mph: (json['maxwind_mph'] as num).toDouble(),
        maxwind_kph: (json['maxwind_kph'] as num).toDouble(),
        totalprecip_mm: (json['totalprecip_mm'] as num).toDouble(),
        totalprecip_in: (json['totalprecip_in'] as num).toDouble(),
        totalsnow_cm: (json['totalsnow_cm'] as num).toDouble(),
        avgvis_km: (json['avgvis_km'] as num).toDouble(),
        avgvis_miles: (json['avgvis_miles'] as num).toDouble(),
        avghumidity: json['avghumidity'] is int ? json['avghumidity'] as int : (json['avghumidity'] as num).toInt(),
        daily_will_it_rain: json['daily_will_it_rain'] == 1,
        daily_chance_of_rain: json['daily_chance_of_rain'] is int ? json['daily_chance_of_rain'] as int : (json['daily_chance_of_rain'] as num).toInt(),
        daily_will_it_snow: json['daily_will_it_snow'] == 1,
        daily_chance_of_snow: json['daily_chance_of_snow'] is int ? json['daily_chance_of_snow'] as int : (json['daily_chance_of_snow'] as num).toInt(),
        condition_text: json['condition']['text'] is String ? json['condition']['text'] as String : json['condition']['text'].toString(),
        condition_icon: json['condition']['icon'] is String ? json['condition']['icon'] as String : json['condition']['icon'].toString(),
      );
    } catch (e, stackTrace) {
      print('ERROR in day_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}