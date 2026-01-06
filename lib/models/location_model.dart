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
    try {
      print('Parsing location_model with keys: ${json.keys.toList()}');

      if (json['name'] == null) throw Exception('Missing "name" field');
      if (json['region'] == null) throw Exception('Missing "region" field');
      if (json['country'] == null) throw Exception('Missing "country" field');
      if (json['lat'] == null) throw Exception('Missing "lat" field');
      if (json['lon'] == null) throw Exception('Missing "lon" field');
      if (json['tz_id'] == null) throw Exception('Missing "tz_id" field');
      if (json['localtime_epoch'] == null) throw Exception('Missing "localtime_epoch" field');
      if (json['localtime'] == null) throw Exception('Missing "localtime" field');

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
    } catch (e, stackTrace) {
      print('ERROR in location_model.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}

