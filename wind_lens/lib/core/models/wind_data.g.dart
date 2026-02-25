// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wind_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WindDataImpl _$$WindDataImplFromJson(Map<String, dynamic> json) =>
    _$WindDataImpl(
      uComponent: (json['uComponent'] as num).toDouble(),
      vComponent: (json['vComponent'] as num).toDouble(),
      gustSpeed: (json['gustSpeed'] as num?)?.toDouble() ?? 0.0,
      altitude: $enumDecode(_$AltitudeLevelEnumMap, json['altitude']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$WindDataImplToJson(_$WindDataImpl instance) =>
    <String, dynamic>{
      'uComponent': instance.uComponent,
      'vComponent': instance.vComponent,
      'gustSpeed': instance.gustSpeed,
      'altitude': _$AltitudeLevelEnumMap[instance.altitude]!,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$AltitudeLevelEnumMap = {
  AltitudeLevel.surface: 'surface',
  AltitudeLevel.midLevel: 'midLevel',
  AltitudeLevel.jetStream: 'jetStream',
};
