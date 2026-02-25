// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wind_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WindData _$WindDataFromJson(Map<String, dynamic> json) {
  return _WindData.fromJson(json);
}

/// @nodoc
mixin _$WindData {
  /// Eastward wind component in m/s.
  /// Positive = wind blowing toward east.
  double get uComponent => throw _privateConstructorUsedError;

  /// Northward wind component in m/s.
  /// Positive = wind blowing toward north.
  double get vComponent => throw _privateConstructorUsedError;

  /// Gust speed in m/s. Defaults to 0.0.
  double get gustSpeed => throw _privateConstructorUsedError;

  /// Altitude level for this wind data.
  AltitudeLevel get altitude => throw _privateConstructorUsedError;

  /// When this wind data was recorded.
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this WindData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WindData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WindDataCopyWith<WindData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WindDataCopyWith<$Res> {
  factory $WindDataCopyWith(WindData value, $Res Function(WindData) then) =
      _$WindDataCopyWithImpl<$Res, WindData>;
  @useResult
  $Res call({
    double uComponent,
    double vComponent,
    double gustSpeed,
    AltitudeLevel altitude,
    DateTime timestamp,
  });
}

/// @nodoc
class _$WindDataCopyWithImpl<$Res, $Val extends WindData>
    implements $WindDataCopyWith<$Res> {
  _$WindDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WindData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uComponent = null,
    Object? vComponent = null,
    Object? gustSpeed = null,
    Object? altitude = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            uComponent: null == uComponent
                ? _value.uComponent
                : uComponent // ignore: cast_nullable_to_non_nullable
                      as double,
            vComponent: null == vComponent
                ? _value.vComponent
                : vComponent // ignore: cast_nullable_to_non_nullable
                      as double,
            gustSpeed: null == gustSpeed
                ? _value.gustSpeed
                : gustSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
            altitude: null == altitude
                ? _value.altitude
                : altitude // ignore: cast_nullable_to_non_nullable
                      as AltitudeLevel,
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
abstract class _$$WindDataImplCopyWith<$Res>
    implements $WindDataCopyWith<$Res> {
  factory _$$WindDataImplCopyWith(
    _$WindDataImpl value,
    $Res Function(_$WindDataImpl) then,
  ) = __$$WindDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double uComponent,
    double vComponent,
    double gustSpeed,
    AltitudeLevel altitude,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$WindDataImplCopyWithImpl<$Res>
    extends _$WindDataCopyWithImpl<$Res, _$WindDataImpl>
    implements _$$WindDataImplCopyWith<$Res> {
  __$$WindDataImplCopyWithImpl(
    _$WindDataImpl _value,
    $Res Function(_$WindDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WindData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uComponent = null,
    Object? vComponent = null,
    Object? gustSpeed = null,
    Object? altitude = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$WindDataImpl(
        uComponent: null == uComponent
            ? _value.uComponent
            : uComponent // ignore: cast_nullable_to_non_nullable
                  as double,
        vComponent: null == vComponent
            ? _value.vComponent
            : vComponent // ignore: cast_nullable_to_non_nullable
                  as double,
        gustSpeed: null == gustSpeed
            ? _value.gustSpeed
            : gustSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
        altitude: null == altitude
            ? _value.altitude
            : altitude // ignore: cast_nullable_to_non_nullable
                  as AltitudeLevel,
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
class _$WindDataImpl extends _WindData {
  const _$WindDataImpl({
    required this.uComponent,
    required this.vComponent,
    this.gustSpeed = 0.0,
    required this.altitude,
    required this.timestamp,
  }) : super._();

  factory _$WindDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$WindDataImplFromJson(json);

  /// Eastward wind component in m/s.
  /// Positive = wind blowing toward east.
  @override
  final double uComponent;

  /// Northward wind component in m/s.
  /// Positive = wind blowing toward north.
  @override
  final double vComponent;

  /// Gust speed in m/s. Defaults to 0.0.
  @override
  @JsonKey()
  final double gustSpeed;

  /// Altitude level for this wind data.
  @override
  final AltitudeLevel altitude;

  /// When this wind data was recorded.
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'WindData(uComponent: $uComponent, vComponent: $vComponent, gustSpeed: $gustSpeed, altitude: $altitude, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WindDataImpl &&
            (identical(other.uComponent, uComponent) ||
                other.uComponent == uComponent) &&
            (identical(other.vComponent, vComponent) ||
                other.vComponent == vComponent) &&
            (identical(other.gustSpeed, gustSpeed) ||
                other.gustSpeed == gustSpeed) &&
            (identical(other.altitude, altitude) ||
                other.altitude == altitude) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uComponent,
    vComponent,
    gustSpeed,
    altitude,
    timestamp,
  );

  /// Create a copy of WindData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WindDataImplCopyWith<_$WindDataImpl> get copyWith =>
      __$$WindDataImplCopyWithImpl<_$WindDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WindDataImplToJson(this);
  }
}

abstract class _WindData extends WindData {
  const factory _WindData({
    required final double uComponent,
    required final double vComponent,
    final double gustSpeed,
    required final AltitudeLevel altitude,
    required final DateTime timestamp,
  }) = _$WindDataImpl;
  const _WindData._() : super._();

  factory _WindData.fromJson(Map<String, dynamic> json) =
      _$WindDataImpl.fromJson;

  /// Eastward wind component in m/s.
  /// Positive = wind blowing toward east.
  @override
  double get uComponent;

  /// Northward wind component in m/s.
  /// Positive = wind blowing toward north.
  @override
  double get vComponent;

  /// Gust speed in m/s. Defaults to 0.0.
  @override
  double get gustSpeed;

  /// Altitude level for this wind data.
  @override
  AltitudeLevel get altitude;

  /// When this wind data was recorded.
  @override
  DateTime get timestamp;

  /// Create a copy of WindData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WindDataImplCopyWith<_$WindDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
