class location_model{
 final String name;
 final String region;
 final String country;
 final double lat;
 final double lon;
 final String tz_id;
 final int localtime_epoch;
 final String localtime;

  location_model({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    required this.tz_id,
    required this.localtime_epoch,
    required this.localtime,
  });
 
  factory location_model.fromJson(Map<String, dynamic> json) {
    return location_model(
      name: json['name'] as String,
      region: json['region'] as String,
      country: json['country'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      tz_id: json['tz_id'] as String,
      localtime_epoch: json['localtime_epoch'] as int,
      localtime: json['localtime'] as String,
    );
  }
}

