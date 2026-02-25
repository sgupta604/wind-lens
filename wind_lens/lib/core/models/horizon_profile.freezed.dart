// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'horizon_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HorizonProfile _$HorizonProfileFromJson(Map<String, dynamic> json) {
  return _HorizonProfile.fromJson(json);
}

/// @nodoc
mixin _$HorizonProfile {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Map of bearing (0-360) to elevation angle in degrees.
  /// Elevation angle = how many degrees above horizontal the terrain reaches.
  @DoubleMapConverter()
  Map<double, double> get elevationAngles => throw _privateConstructorUsedError;
  DateTime get fetchedAt => throw _privateConstructorUsedError;

  /// Serializes this HorizonProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HorizonProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HorizonProfileCopyWith<HorizonProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HorizonProfileCopyWith<$Res> {
  factory $HorizonProfileCopyWith(
    HorizonProfile value,
    $Res Function(HorizonProfile) then,
  ) = _$HorizonProfileCopyWithImpl<$Res, HorizonProfile>;
  @useResult
  $Res call({
    double latitude,
    double longitude,
    @DoubleMapConverter() Map<double, double> elevationAngles,
    DateTime fetchedAt,
  });
}

/// @nodoc
class _$HorizonProfileCopyWithImpl<$Res, $Val extends HorizonProfile>
    implements $HorizonProfileCopyWith<$Res> {
  _$HorizonProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HorizonProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? elevationAngles = null,
    Object? fetchedAt = null,
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
            elevationAngles: null == elevationAngles
                ? _value.elevationAngles
                : elevationAngles // ignore: cast_nullable_to_non_nullable
                      as Map<double, double>,
            fetchedAt: null == fetchedAt
                ? _value.fetchedAt
                : fetchedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HorizonProfileImplCopyWith<$Res>
    implements $HorizonProfileCopyWith<$Res> {
  factory _$$HorizonProfileImplCopyWith(
    _$HorizonProfileImpl value,
    $Res Function(_$HorizonProfileImpl) then,
  ) = __$$HorizonProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double latitude,
    double longitude,
    @DoubleMapConverter() Map<double, double> elevationAngles,
    DateTime fetchedAt,
  });
}

/// @nodoc
class __$$HorizonProfileImplCopyWithImpl<$Res>
    extends _$HorizonProfileCopyWithImpl<$Res, _$HorizonProfileImpl>
    implements _$$HorizonProfileImplCopyWith<$Res> {
  __$$HorizonProfileImplCopyWithImpl(
    _$HorizonProfileImpl _value,
    $Res Function(_$HorizonProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HorizonProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? elevationAngles = null,
    Object? fetchedAt = null,
  }) {
    return _then(
      _$HorizonProfileImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        elevationAngles: null == elevationAngles
            ? _value._elevationAngles
            : elevationAngles // ignore: cast_nullable_to_non_nullable
                  as Map<double, double>,
        fetchedAt: null == fetchedAt
            ? _value.fetchedAt
            : fetchedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HorizonProfileImpl extends _HorizonProfile {
  const _$HorizonProfileImpl({
    required this.latitude,
    required this.longitude,
    @DoubleMapConverter() required final Map<double, double> elevationAngles,
    required this.fetchedAt,
  }) : _elevationAngles = elevationAngles,
       super._();

  factory _$HorizonProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$HorizonProfileImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  /// Map of bearing (0-360) to elevation angle in degrees.
  /// Elevation angle = how many degrees above horizontal the terrain reaches.
  final Map<double, double> _elevationAngles;

  /// Map of bearing (0-360) to elevation angle in degrees.
  /// Elevation angle = how many degrees above horizontal the terrain reaches.
  @override
  @DoubleMapConverter()
  Map<double, double> get elevationAngles {
    if (_elevationAngles is EqualUnmodifiableMapView) return _elevationAngles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_elevationAngles);
  }

  @override
  final DateTime fetchedAt;

  @override
  String toString() {
    return 'HorizonProfile(latitude: $latitude, longitude: $longitude, elevationAngles: $elevationAngles, fetchedAt: $fetchedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HorizonProfileImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            const DeepCollectionEquality().equals(
              other._elevationAngles,
              _elevationAngles,
            ) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    latitude,
    longitude,
    const DeepCollectionEquality().hash(_elevationAngles),
    fetchedAt,
  );

  /// Create a copy of HorizonProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HorizonProfileImplCopyWith<_$HorizonProfileImpl> get copyWith =>
      __$$HorizonProfileImplCopyWithImpl<_$HorizonProfileImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HorizonProfileImplToJson(this);
  }
}

abstract class _HorizonProfile extends HorizonProfile {
  const factory _HorizonProfile({
    required final double latitude,
    required final double longitude,
    @DoubleMapConverter() required final Map<double, double> elevationAngles,
    required final DateTime fetchedAt,
  }) = _$HorizonProfileImpl;
  const _HorizonProfile._() : super._();

  factory _HorizonProfile.fromJson(Map<String, dynamic> json) =
      _$HorizonProfileImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Map of bearing (0-360) to elevation angle in degrees.
  /// Elevation angle = how many degrees above horizontal the terrain reaches.
  @override
  @DoubleMapConverter()
  Map<double, double> get elevationAngles;
  @override
  DateTime get fetchedAt;

  /// Create a copy of HorizonProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HorizonProfileImplCopyWith<_$HorizonProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
