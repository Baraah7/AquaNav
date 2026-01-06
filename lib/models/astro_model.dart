class astro_model{
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moon_phase;
  final String moon_illumination;
  final String is_moon_up;
  final String is_sun_up;

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
    return astro_model(
      sunrise: json['sunrise'] as String,
      sunset: json['sunset'] as String,
      moonrise: json['moonrise'] as String,
      moonset: json['moonset'] as String,
      moon_phase: json['moon_phase'] as String,
      moon_illumination: json['moon_illumination'] as String,
      is_moon_up: json['is_moon_up'].toString(),
      is_sun_up: json['is_sun_up'].toString(),
    );
  }
}