// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PositionData _$PositionDataFromJson(Map<String, dynamic> json) {
  return _PositionData.fromJson(json);
}

/// @nodoc
mixin _$PositionData {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get altitude => throw _privateConstructorUsedError;
  double get accuracy => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this PositionData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PositionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PositionDataCopyWith<PositionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PositionDataCopyWith<$Res> {
  factory $PositionDataCopyWith(
    PositionData value,
    $Res Function(PositionData) then,
  ) = _$PositionDataCopyWithImpl<$Res, PositionData>;
  @useResult
  $Res call({
    double latitude,
    double longitude,
    double altitude,
    double accuracy,
    DateTime timestamp,
  });
}

/// @nodoc
class _$PositionDataCopyWithImpl<$Res, $Val extends PositionData>
    implements $PositionDataCopyWith<$Res> {
  _$PositionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PositionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? altitude = null,
    Object? accuracy = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            altitude: null == altitude
                ? _value.altitude
                : altitude // ignore: cast_nullable_to_non_nullable
                      as double,
            accuracy: null == accuracy
                ? _value.accuracy
                : accuracy // ignore: cast_nullable_to_non_nullable
                      as double,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PositionDataImplCopyWith<$Res>
    implements $PositionDataCopyWith<$Res> {
  factory _$$PositionDataImplCopyWith(
    _$PositionDataImpl value,
    $Res Function(_$PositionDataImpl) then,
  ) = __$$PositionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double latitude,
    double longitude,
    double altitude,
    double accuracy,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$PositionDataImplCopyWithImpl<$Res>
    extends _$PositionDataCopyWithImpl<$Res, _$PositionDataImpl>
    implements _$$PositionDataImplCopyWith<$Res> {
  __$$PositionDataImplCopyWithImpl(
    _$PositionDataImpl _value,
    $Res Function(_$PositionDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PositionData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? altitude = null,
    Object? accuracy = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$PositionDataImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        altitude: null == altitude
            ? _value.altitude
            : altitude // ignore: cast_nullable_to_non_nullable
                  as double,
        accuracy: null == accuracy
            ? _value.accuracy
            : accuracy // ignore: cast_nullable_to_non_nullable
                  as double,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PositionDataImpl implements _PositionData {
  const _$PositionDataImpl({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory _$PositionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$PositionDataImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double altitude;
  @override
  final double accuracy;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'PositionData(latitude: $latitude, longitude: $longitude, altitude: $altitude, accuracy: $accuracy, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PositionDataImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.altitude, altitude) ||
                other.altitude == altitude) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    latitude,
    longitude,
    altitude,
    accuracy,
    timestamp,
  );

  /// Create a copy of PositionData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PositionDataImplCopyWith<_$PositionDataImpl> get copyWith =>
      __$$PositionDataImplCopyWithImpl<_$PositionDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionDataImplToJson(this);
  }
}

abstract class _PositionData implements PositionData {
  const factory _PositionData({
    required final double latitude,
    required final double longitude,
    required final double altitude,
    required final double accuracy,
    required final DateTime timestamp,
  }) = _$PositionDataImpl;

  factory _PositionData.fromJson(Map<String, dynamic> json) =
      _$PositionDataImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get altitude;
  @override
  double get accuracy;
  @override
  DateTime get timestamp;

  /// Create a copy of PositionData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PositionDataImplCopyWith<_$PositionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
