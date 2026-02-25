// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SceneState {
  PositionData get position => throw _privateConstructorUsedError;
  HorizonProfile get horizon => throw _privateConstructorUsedError;
  WindData get wind => throw _privateConstructorUsedError;
  double get compassHeading => throw _privateConstructorUsedError;
  double get pitch => throw _privateConstructorUsedError;
  SkyMaskData get skyMask => throw _privateConstructorUsedError;
  AltitudeLevel get selectedAltitude => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SceneStateCopyWith<SceneState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SceneStateCopyWith<$Res> {
  factory $SceneStateCopyWith(
    SceneState value,
    $Res Function(SceneState) then,
  ) = _$SceneStateCopyWithImpl<$Res, SceneState>;
  @useResult
  $Res call({
    PositionData position,
    HorizonProfile horizon,
    WindData wind,
    double compassHeading,
    double pitch,
    SkyMaskData skyMask,
    AltitudeLevel selectedAltitude,
    DateTime timestamp,
  });

  $PositionDataCopyWith<$Res> get position;
  $HorizonProfileCopyWith<$Res> get horizon;
  $WindDataCopyWith<$Res> get wind;
}

/// @nodoc
class _$SceneStateCopyWithImpl<$Res, $Val extends SceneState>
    implements $SceneStateCopyWith<$Res> {
  _$SceneStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? position = null,
    Object? horizon = null,
    Object? wind = null,
    Object? compassHeading = null,
    Object? pitch = null,
    Object? skyMask = null,
    Object? selectedAltitude = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as PositionData,
            horizon: null == horizon
                ? _value.horizon
                : horizon // ignore: cast_nullable_to_non_nullable
                      as HorizonProfile,
            wind: null == wind
                ? _value.wind
                : wind // ignore: cast_nullable_to_non_nullable
                      as WindData,
            compassHeading: null == compassHeading
                ? _value.compassHeading
                : compassHeading // ignore: cast_nullable_to_non_nullable
                      as double,
            pitch: null == pitch
                ? _value.pitch
                : pitch // ignore: cast_nullable_to_non_nullable
                      as double,
            skyMask: null == skyMask
                ? _value.skyMask
                : skyMask // ignore: cast_nullable_to_non_nullable
                      as SkyMaskData,
            selectedAltitude: null == selectedAltitude
                ? _value.selectedAltitude
                : selectedAltitude // ignore: cast_nullable_to_non_nullable
                      as AltitudeLevel,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PositionDataCopyWith<$Res> get position {
    return $PositionDataCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HorizonProfileCopyWith<$Res> get horizon {
    return $HorizonProfileCopyWith<$Res>(_value.horizon, (value) {
      return _then(_value.copyWith(horizon: value) as $Val);
    });
  }

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WindDataCopyWith<$Res> get wind {
    return $WindDataCopyWith<$Res>(_value.wind, (value) {
      return _then(_value.copyWith(wind: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SceneStateImplCopyWith<$Res>
    implements $SceneStateCopyWith<$Res> {
  factory _$$SceneStateImplCopyWith(
    _$SceneStateImpl value,
    $Res Function(_$SceneStateImpl) then,
  ) = __$$SceneStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PositionData position,
    HorizonProfile horizon,
    WindData wind,
    double compassHeading,
    double pitch,
    SkyMaskData skyMask,
    AltitudeLevel selectedAltitude,
    DateTime timestamp,
  });

  @override
  $PositionDataCopyWith<$Res> get position;
  @override
  $HorizonProfileCopyWith<$Res> get horizon;
  @override
  $WindDataCopyWith<$Res> get wind;
}

/// @nodoc
class __$$SceneStateImplCopyWithImpl<$Res>
    extends _$SceneStateCopyWithImpl<$Res, _$SceneStateImpl>
    implements _$$SceneStateImplCopyWith<$Res> {
  __$$SceneStateImplCopyWithImpl(
    _$SceneStateImpl _value,
    $Res Function(_$SceneStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? position = null,
    Object? horizon = null,
    Object? wind = null,
    Object? compassHeading = null,
    Object? pitch = null,
    Object? skyMask = null,
    Object? selectedAltitude = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$SceneStateImpl(
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as PositionData,
        horizon: null == horizon
            ? _value.horizon
            : horizon // ignore: cast_nullable_to_non_nullable
                  as HorizonProfile,
        wind: null == wind
            ? _value.wind
            : wind // ignore: cast_nullable_to_non_nullable
                  as WindData,
        compassHeading: null == compassHeading
            ? _value.compassHeading
            : compassHeading // ignore: cast_nullable_to_non_nullable
                  as double,
        pitch: null == pitch
            ? _value.pitch
            : pitch // ignore: cast_nullable_to_non_nullable
                  as double,
        skyMask: null == skyMask
            ? _value.skyMask
            : skyMask // ignore: cast_nullable_to_non_nullable
                  as SkyMaskData,
        selectedAltitude: null == selectedAltitude
            ? _value.selectedAltitude
            : selectedAltitude // ignore: cast_nullable_to_non_nullable
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

class _$SceneStateImpl implements _SceneState {
  const _$SceneStateImpl({
    required this.position,
    required this.horizon,
    required this.wind,
    required this.compassHeading,
    required this.pitch,
    required this.skyMask,
    required this.selectedAltitude,
    required this.timestamp,
  });

  @override
  final PositionData position;
  @override
  final HorizonProfile horizon;
  @override
  final WindData wind;
  @override
  final double compassHeading;
  @override
  final double pitch;
  @override
  final SkyMaskData skyMask;
  @override
  final AltitudeLevel selectedAltitude;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'SceneState(position: $position, horizon: $horizon, wind: $wind, compassHeading: $compassHeading, pitch: $pitch, skyMask: $skyMask, selectedAltitude: $selectedAltitude, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SceneStateImpl &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.horizon, horizon) || other.horizon == horizon) &&
            (identical(other.wind, wind) || other.wind == wind) &&
            (identical(other.compassHeading, compassHeading) ||
                other.compassHeading == compassHeading) &&
            (identical(other.pitch, pitch) || other.pitch == pitch) &&
            (identical(other.skyMask, skyMask) || other.skyMask == skyMask) &&
            (identical(other.selectedAltitude, selectedAltitude) ||
                other.selectedAltitude == selectedAltitude) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    position,
    horizon,
    wind,
    compassHeading,
    pitch,
    skyMask,
    selectedAltitude,
    timestamp,
  );

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SceneStateImplCopyWith<_$SceneStateImpl> get copyWith =>
      __$$SceneStateImplCopyWithImpl<_$SceneStateImpl>(this, _$identity);
}

abstract class _SceneState implements SceneState {
  const factory _SceneState({
    required final PositionData position,
    required final HorizonProfile horizon,
    required final WindData wind,
    required final double compassHeading,
    required final double pitch,
    required final SkyMaskData skyMask,
    required final AltitudeLevel selectedAltitude,
    required final DateTime timestamp,
  }) = _$SceneStateImpl;

  @override
  PositionData get position;
  @override
  HorizonProfile get horizon;
  @override
  WindData get wind;
  @override
  double get compassHeading;
  @override
  double get pitch;
  @override
  SkyMaskData get skyMask;
  @override
  AltitudeLevel get selectedAltitude;
  @override
  DateTime get timestamp;

  /// Create a copy of SceneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SceneStateImplCopyWith<_$SceneStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
