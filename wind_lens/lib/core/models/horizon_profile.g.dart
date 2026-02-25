// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horizon_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HorizonProfileImpl _$$HorizonProfileImplFromJson(Map<String, dynamic> json) =>
    _$HorizonProfileImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevationAngles: const DoubleMapConverter().fromJson(
        json['elevationAngles'] as Map<String, dynamic>,
      ),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );

Map<String, dynamic> _$$HorizonProfileImplToJson(
  _$HorizonProfileImpl instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'elevationAngles': const DoubleMapConverter().toJson(
    instance.elevationAngles,
  ),
  'fetchedAt': instance.fetchedAt.toIso8601String(),
};
