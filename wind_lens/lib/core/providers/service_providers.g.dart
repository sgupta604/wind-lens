// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sensorServiceHash() => r'98b7bfb432c4c545a31557020ca47e906ef37b3d';

/// Provides the [SensorService] implementation.
///
/// Currently returns [DeviceSensorService] which wraps the
/// native compass + GPS sensors. Also creates an [AppLifecycleObserver]
/// that pauses sensors when the app is backgrounded and resumes them
/// when the app returns to the foreground.
///
/// Both the service and the lifecycle observer are disposed when
/// the provider is no longer watched.
///
/// Copied from [sensorService].
@ProviderFor(sensorService)
final sensorServiceProvider = AutoDisposeProvider<SensorService>.internal(
  sensorService,
  name: r'sensorServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sensorServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SensorServiceRef = AutoDisposeProviderRef<SensorService>;
String _$windDataSourceHash() => r'3223725c059ab5acebca91a0163d2b3229bc8538';

/// Provides the [WindDataSource] implementation.
///
/// Currently returns [MockWindDataSource] which wraps [FakeWindService].
/// Swap this single line when OGC EDR is ready.
///
/// Copied from [windDataSource].
@ProviderFor(windDataSource)
final windDataSourceProvider = AutoDisposeProvider<WindDataSource>.internal(
  windDataSource,
  name: r'windDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$windDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WindDataSourceRef = AutoDisposeProviderRef<WindDataSource>;
String _$horizonProviderServiceHash() =>
    r'1f443851585f0528244abdf5685065fb76b7b63e';

/// Provides the [HorizonProvider] implementation.
///
/// Currently returns [MockHorizonProvider] which returns flat horizons.
/// Swap when HeyWhatsThat client is ready.
///
/// Copied from [horizonProviderService].
@ProviderFor(horizonProviderService)
final horizonProviderServiceProvider =
    AutoDisposeProvider<core.HorizonProvider>.internal(
      horizonProviderService,
      name: r'horizonProviderServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$horizonProviderServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HorizonProviderServiceRef =
    AutoDisposeProviderRef<core.HorizonProvider>;
String _$skyDetectorInstanceHash() =>
    r'040280fd567cba095da7275357ebdc7fa175123c';

/// Provides the [SkyDetector] implementation.
///
/// Currently returns [HsvSkyDetector] which wraps the existing
/// auto-calibrating HSV sky detection. Disposed when no longer watched.
///
/// Copied from [skyDetectorInstance].
@ProviderFor(skyDetectorInstance)
final skyDetectorInstanceProvider = AutoDisposeProvider<SkyDetector>.internal(
  skyDetectorInstance,
  name: r'skyDetectorInstanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$skyDetectorInstanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SkyDetectorInstanceRef = AutoDisposeProviderRef<SkyDetector>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
