class hour_model{
  final int time_epoch;
  final String time;
  final double temp_c;
  final double temp_f;
  final int is_day;
  final String condition_text;
  final String condition_icon;
  final double wind_mph;
  final double wind_kph;
  final int wind_degree;
  final String wind_dir;
  final double pressure_mb;
  final double pressure_in;
  final double precip_mm;
  final double precip_in;
  final double snow_cm;
  final double humidity;
  final double cloud;
  final double feelslike_c;
  final double feelslike_f;
  final double windchill_c;
  final double windchill_f;
  final double heatindex_c;
  final double heatindex_f;
  final double dewpoint_c;
  final double dewpoint_f;
  final bool will_it_rain;
  final int chance_of_rain;
  final bool will_it_snow;
  final int chance_of_snow;
  final double vis_km;
  final double vis_miles;
  final double gust_mph;
  final double gust_kph;
  final double uv;
  // Solar radiation fields - optional (may not be in all API responses)
  final double? short_rad;
  final double? diff_rad;
  final double? dni;
  final double? gti;

  hour_model({
    required this.time_epoch,
    required this.time,
    required this.temp_c,
    required this.temp_f,
    required this.is_day,
    required this.condition_text,
    required this.condition_icon,
    required this.wind_mph,
    required this.wind_kph,
    required this.wind_degree,
    required this.wind_dir,
    required this.pressure_mb,
    required this.pressure_in,
    required this.precip_mm,
    required this.precip_in,
    required this.snow_cm,
    required this.humidity,
    required this.cloud,
    required this.feelslike_c,
    required this.feelslike_f,
    required this.windchill_c,
    required this.windchill_f,
    required this.heatindex_c,
    required this.heatindex_f,
    required this.dewpoint_c,
    required this.dewpoint_f,
    required this.will_it_rain,
    required this.chance_of_rain,
    required this.will_it_snow,
    required this.chance_of_snow,
    required this.vis_km,
    required this.vis_miles,
    required this.gust_mph,
    required this.gust_kph,
    required this.uv,
    this.short_rad,
    this.diff_rad,
    this.dni,
    this.gti,
  });

  factory hour_model.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing hour_model for time: ${json['time']}');

      if (json['condition'] == null) throw Exception('Missing "condition" field in hour');

      return hour_model(
        time_epoch: json['time_epoch'] as int,
        time: json['time'] is String ? json['time'] as String : json['time'].toString(),
        temp_c: (json['temp_c'] as num).toDouble(),
        temp_f: (json['temp_f'] as num).toDouble(),
        is_day: json['is_day'] as int,
        condition_text: json['condition']['text'] is String ? json['condition']['text'] as String : json['condition']['text'].toString(),
        condition_icon: json['condition']['icon'] is String ? json['condition']['icon'] as String : json['condition']['icon'].toString(),
        wind_mph: (json['wind_mph'] as num).toDouble(),
        wind_kph: (json['wind_kph'] as num).toDouble(),
        wind_degree: json['wind_degree'] as int,
        wind_dir: json['wind_dir'] is String ? json['wind_dir'] as String : json['wind_dir'].toString(),
        pressure_mb: (json['pressure_mb'] as num).toDouble(),
        pressure_in: (json['pressure_in'] as num).toDouble(),
        precip_mm: (json['precip_mm'] as num).toDouble(),
        precip_in: (json['precip_in'] as num).toDouble(),
        snow_cm: (json['snow_cm'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        cloud: (json['cloud'] as num).toDouble(),
        feelslike_c: (json['feelslike_c'] as num).toDouble(),
        feelslike_f: (json['feelslike_f'] as num).toDouble(),
        windchill_c: (json['windchill_c'] as num).toDouble(),
        windchill_f: (json['windchill_f'] as num).toDouble(),
        heatindex_c: (json['heatindex_c'] as num).toDouble(),
        heatindex_f: (json['heatindex_f'] as num).toDouble(),
        dewpoint_c: (json['dewpoint_c'] as num).toDouble(),
        dewpoint_f: (json['dewpoint_f'] as num).toDouble(),
        will_it_rain: (json['will_it_rain'] as int) == 1,
        chance_of_rain: json['chance_of_rain'] as int,
        will_it_snow: (json['will_it_snow'] as int) == 1,
        chance_of_snow: json['chance_of_snow'] as int,
        vis_km: (json['vis_km'] as num).toDouble(),
        vis_miles: (json['vis_miles'] as num).toDouble(),
        gust_mph: (json['gust_mph'] as num).toDouble(),
        gust_kph: (json['gust_kph'] as num).toDouble(),
        uv: (json['uv'] as num).toDouble(),
        // Solar radiation fields - optional, may be null in some API responses
        short_rad: json['short_rad'] != null ? (json['short_rad'] as num).toDouble() : null,
        diff_rad: json['diff_rad'] != null ? (json['diff_rad'] as num).toDouble() : null,
        dni: json['dni'] != null ? (json['dni'] as num).toDouble() : null,
        gti: json['gti'] != null ? (json['gti'] as num).toDouble() : null,
      );
    } catch (e, stackTrace) {
      print('ERROR in hour_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}