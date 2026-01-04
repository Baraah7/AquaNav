class current_weather_model {
  final int last_updated_epoch;
  final String last_updated;
  final double temp_c;
  final double temp_f;
  final int is_day;
  final condition_model condition;
  final double wind_mph;
  final double wind_kph;
  final int wind_degree;
  final String wind_dir;
  final double pressure_mb;
  final double pressure_in;
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
  final double vis_km;
  final double vis_miles;
  final double uv;
  final double gust_mph;
  final double gust_kph;
  final double short_rad;
  final double diff_rad;
  final double dni;
  final double gti;

  current_weather_model({
    required this.last_updated_epoch,
    required this.last_updated,
    required this.temp_c,
    required this.temp_f,
    required this.is_day,
    required this.condition,
    required this.wind_mph,
    required this.wind_kph,
    required this.wind_degree,
    required this.wind_dir,
    required this.pressure_mb,
    required this.pressure_in,
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
    required this.vis_km,
    required this.vis_miles,
    required this.uv,
    required this.gust_mph,
    required this.gust_kph,
    required this.short_rad,
    required this.diff_rad,
    required this.dni,
    required this.gti,
  });

  factory current_weather_model.fromJson(Map<String, dynamic> json) {
    return current_weather_model(
      last_updated_epoch: json['last_updated_epoch'] as int,
      last_updated: json['last_updated'] as String,
      temp_c: (json['temp_c'] as num).toDouble(),
      temp_f: (json['temp_f'] as num).toDouble(),
      is_day: json['is_day'] as int,
      condition: condition_model.fromJson(json['condition']),
      wind_mph: (json['wind_mph'] as num).toDouble(),
      wind_kph: (json['wind_kph'] as num).toDouble(),
      wind_degree: json['wind_degree'] as int,
      wind_dir: json['wind_dir'] as String,
      pressure_mb: (json['pressure_mb'] as num).toDouble(),
      pressure_in: (json['pressure_in'] as num).toDouble(),
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
      vis_km: (json['vis_km'] as num).toDouble(),
      vis_miles: (json['vis_miles'] as num).toDouble(),
      uv: (json['uv'] as num).toDouble(),
      gust_mph: (json['gust_mph'] as num).toDouble(),
      gust_kph: (json['gust_kph'] as num).toDouble(),
      short_rad: (json['short_rad'] as num).toDouble(),
      diff_rad: (json['diff_rad'] as num).toDouble(),
      dni: (json['dni'] as num).toDouble(),
      gti: (json['gti'] as num).toDouble(),
    );
  }
}

class condition_model{
  final String text;
  final String icon;
  final int code;

  condition_model({
    required this.text,
    required this.icon,
    required this.code,
  });

  factory condition_model.fromJson(Map<String, dynamic> json) {
    return condition_model(
      text: json['text'] as String,
      icon: json['icon'] as String,
      code: json['code'] as int,
    );
  }
}
