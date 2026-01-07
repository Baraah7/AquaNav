import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/map/map_entities.dart';

/// Fishing Activity Model
@JsonSerializable()
class FishingActivityModel {
  final String id;
  final double lat;
  final double lon;
  @JsonKey(name: 'vessel_name')
  final String vesselName;
  @JsonKey(name: 'vessel_type')
  final String vesselType;
  final double speed;
  final String timestamp;
  @JsonKey(name: 'activity_score')
  final double activityScore;

  FishingActivityModel({
    required this.id,
    required this.lat,
    required this.lon,
    required this.vesselName,
    required this.vesselType,
    required this.speed,
    required this.timestamp,
    required this.activityScore,
  });

  factory FishingActivityModel.fromJson(Map<String, dynamic> json) =>
      _$FishingActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$FishingActivityModelToJson(this);

  FishingActivity toEntity() {
    return FishingActivity(
      id: id,
      position: LatLng(lat, lon),
      vesselName: vesselName,
      vesselType: vesselType,
      speed: speed,
      timestamp: DateTime.parse(timestamp),
      activityScore: activityScore,
    );
  }
}
