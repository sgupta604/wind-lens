// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gpsPositionHash() => r'bf224ab71eb6c99b84c0161f8a3af7c917a5313d';

/// Provides the raw GPS position stream from the sensor service.
///
/// Copied from [gpsPosition].
@ProviderFor(gpsPosition)
final gpsPositionProvider = AutoDisposeStreamProvider<PositionData>.internal(
  gpsPosition,
  name: r'gpsPositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gpsPositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GpsPositionRef = AutoDisposeStreamProviderRef<PositionData>;
String _$rawSensorHash() => r'a9414705671af2158f0c42a02083e5da81dc7850';

/// Provides the raw sensor (compass/pitch) stream from the sensor service.
///
/// Copied from [rawSensor].
@ProviderFor(rawSensor)
final rawSensorProvider = AutoDisposeStreamProvider<SensorState>.internal(
  rawSensor,
  name: r'rawSensorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rawSensorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RawSensorRef = AutoDisposeStreamProviderRef<SensorState>;
String _$sensorNotifiersHash() => r'5816cabfbc1affcc97781c53f0ba673ba7515567';

/// Provides [SensorNotifiers] that pipe high-frequency sensor data
/// to [ValueNotifier]s for direct consumption by CustomPainters.
///
/// This avoids Riverpod rebuilds at sensor rate (20-50Hz).
///
/// Copied from [sensorNotifiers].
@ProviderFor(sensorNotifiers)
final sensorNotifiersProvider = AutoDisposeProvider<SensorNotifiers>.internal(
  sensorNotifiers,
  name: r'sensorNotifiersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sensorNotifiersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SensorNotifiersRef = AutoDisposeProviderRef<SensorNotifiers>;
String _$stablePositionHash() => r'e4a3f4698fe7acfc5a445599070c07f5975a4502';

/// Debounced GPS position that only updates when the user moves >100m.
///
/// This prevents thrashing downstream providers (horizon, wind) on GPS jitter.
/// Returns null until the first GPS fix is received.
///
/// Copied from [StablePosition].
@ProviderFor(StablePosition)
final stablePositionProvider =
    AutoDisposeNotifierProvider<StablePosition, PositionData?>.internal(
      StablePosition.new,
      name: r'stablePositionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stablePositionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StablePosition = AutoDisposeNotifier<PositionData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
