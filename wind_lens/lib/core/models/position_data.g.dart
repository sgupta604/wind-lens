// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PositionDataImpl _$$PositionDataImplFromJson(Map<String, dynamic> json) =>
    _$PositionDataImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$PositionDataImplToJson(_$PositionDataImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'altitude': instance.altitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp.toIso8601String(),
    };
