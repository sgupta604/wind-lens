// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sensor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SensorState {
  double get compassHeading => throw _privateConstructorUsedError;
  double get pitch => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Create a copy of SensorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SensorStateCopyWith<SensorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SensorStateCopyWith<$Res> {
  factory $SensorStateCopyWith(
    SensorState value,
    $Res Function(SensorState) then,
  ) = _$SensorStateCopyWithImpl<$Res, SensorState>;
  @useResult
  $Res call({double compassHeading, double pitch, DateTime timestamp});
}

/// @nodoc
class _$SensorStateCopyWithImpl<$Res, $Val extends SensorState>
    implements $SensorStateCopyWith<$Res> {
  _$SensorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SensorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compassHeading = null,
    Object? pitch = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            compassHeading: null == compassHeading
                ? _value.compassHeading
                : compassHeading // ignore: cast_nullable_to_non_nullable
                      as double,
            pitch: null == pitch
                ? _value.pitch
                : pitch // ignore: cast_nullable_to_non_nullable
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
abstract class _$$SensorStateImplCopyWith<$Res>
    implements $SensorStateCopyWith<$Res> {
  factory _$$SensorStateImplCopyWith(
    _$SensorStateImpl value,
    $Res Function(_$SensorStateImpl) then,
  ) = __$$SensorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double compassHeading, double pitch, DateTime timestamp});
}

/// @nodoc
class __$$SensorStateImplCopyWithImpl<$Res>
    extends _$SensorStateCopyWithImpl<$Res, _$SensorStateImpl>
    implements _$$SensorStateImplCopyWith<$Res> {
  __$$SensorStateImplCopyWithImpl(
    _$SensorStateImpl _value,
    $Res Function(_$SensorStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SensorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compassHeading = null,
    Object? pitch = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$SensorStateImpl(
        compassHeading: null == compassHeading
            ? _value.compassHeading
            : compassHeading // ignore: cast_nullable_to_non_nullable
                  as double,
        pitch: null == pitch
            ? _value.pitch
            : pitch // ignore: cast_nullable_to_non_nullable
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

class _$SensorStateImpl implements _SensorState {
  const _$SensorStateImpl({
    required this.compassHeading,
    required this.pitch,
    required this.timestamp,
  });

  @override
  final double compassHeading;
  @override
  final double pitch;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'SensorState(compassHeading: $compassHeading, pitch: $pitch, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SensorStateImpl &&
            (identical(other.compassHeading, compassHeading) ||
                other.compassHeading == compassHeading) &&
            (identical(other.pitch, pitch) || other.pitch == pitch) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, compassHeading, pitch, timestamp);

  /// Create a copy of SensorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SensorStateImplCopyWith<_$SensorStateImpl> get copyWith =>
      __$$SensorStateImplCopyWithImpl<_$SensorStateImpl>(this, _$identity);
}

abstract class _SensorState implements SensorState {
  const factory _SensorState({
    required final double compassHeading,
    required final double pitch,
    required final DateTime timestamp,
  }) = _$SensorStateImpl;

  @override
  double get compassHeading;
  @override
  double get pitch;
  @override
  DateTime get timestamp;

  /// Create a copy of SensorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SensorStateImplCopyWith<_$SensorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
