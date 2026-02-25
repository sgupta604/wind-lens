// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$horizonProfileHash() => r'b4b212425a2ecae7a24802760c2633081904dd3b';

/// Fetches the horizon profile for the current stable position.
///
/// Returns [AsyncValue<HorizonProfile>] that auto-refetches when
/// [stablePositionProvider] changes (i.e., user moves >100m).
///
/// Throws [StateError] if no GPS fix is available yet.
///
/// Copied from [horizonProfile].
@ProviderFor(horizonProfile)
final horizonProfileProvider =
    AutoDisposeFutureProvider<HorizonProfile>.internal(
      horizonProfile,
      name: r'horizonProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$horizonProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HorizonProfileRef = AutoDisposeFutureProviderRef<HorizonProfile>;
String _$windDataHash() => r'2605f4d7ffbb584fe636fc889b559ca7da3fe1f2';

/// Fetches wind data for the current stable position and selected altitude.
///
/// Returns [AsyncValue<WindData>] that auto-refetches when either
/// [stablePositionProvider] or [selectedAltitudeProvider] changes.
///
/// Throws [StateError] if no GPS fix is available yet.
///
/// Copied from [windData].
@ProviderFor(windData)
final windDataProvider = AutoDisposeFutureProvider<WindData>.internal(
  windData,
  name: r'windDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$windDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WindDataRef = AutoDisposeFutureProviderRef<WindData>;
String _$selectedAltitudeHash() => r'654f2d23633082128f79a38e2eabb012a3ca8ee0';

/// User-selected altitude level for particle visualization.
///
/// Defaults to [AltitudeLevel.surface]. When changed, triggers
/// [windDataProvider] to refetch wind data for the new altitude.
///
/// Copied from [SelectedAltitude].
@ProviderFor(SelectedAltitude)
final selectedAltitudeProvider =
    AutoDisposeNotifierProvider<SelectedAltitude, AltitudeLevel>.internal(
      SelectedAltitude.new,
      name: r'selectedAltitudeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedAltitudeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedAltitude = AutoDisposeNotifier<AltitudeLevel>;
String _$detectionModeHash() => r'e80660da396737fa19364ba6379cc8e4bc28b93c';

/// User-selected sky detection mode.
///
/// Defaults to [SkyDetectionMethod.hsv]. When changed, the sky detector
/// provider will return the appropriate implementation.
///
/// Copied from [DetectionMode].
@ProviderFor(DetectionMode)
final detectionModeProvider =
    AutoDisposeNotifierProvider<DetectionMode, SkyDetectionMethod>.internal(
      DetectionMode.new,
      name: r'detectionModeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$detectionModeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DetectionMode = AutoDisposeNotifier<SkyDetectionMethod>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
