class astro_model{
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moon_phase;
  final String moon_illumination;
  final int is_moon_up;
  final int is_sun_up;

  astro_model({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moon_phase,
    required this.moon_illumination,
    required this.is_moon_up,
    required this.is_sun_up,
  });

  factory astro_model.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing astro_model with keys: ${json.keys.toList()}');

      return astro_model(
        sunrise: json['sunrise'] is String ? json['sunrise'] as String : json['sunrise'].toString(),
        sunset: json['sunset'] is String ? json['sunset'] as String : json['sunset'].toString(),
        moonrise: json['moonrise'] is String ? json['moonrise'] as String : json['moonrise'].toString(),
        moonset: json['moonset'] is String ? json['moonset'] as String : json['moonset'].toString(),
        moon_phase: json['moon_phase'] is String ? json['moon_phase'] as String : json['moon_phase'].toString(),
        moon_illumination: json['moon_illumination'] is String ? json['moon_illumination'] as String : json['moon_illumination'].toString(),
        is_moon_up: json['is_moon_up'] is int ? json['is_moon_up'] as int : (json['is_moon_up'] as num).toInt(),
        is_sun_up: json['is_sun_up'] is int ? json['is_sun_up'] as int : (json['is_sun_up'] as num).toInt(),
      );
    } catch (e, stackTrace) {
      print('ERROR in astro_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}