// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$horizonProfileHash() => r'05c3f2c5904d8a0a7a0054690ba54b57e2bf3a94';

/// Fetches the horizon profile for the effective position.
///
/// Returns [AsyncValue<HorizonProfile>] that auto-refetches when
/// [effectivePositionProvider] changes (i.e., user moves >100m or
/// sets a location override).
///
/// Throws [StateError] if no position is available yet.
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
String _$windDataHash() => r'1fe63a91e07a28a8059a7f79b3168758ce8324d6';

/// Fetches wind data for the effective position and selected altitude.
///
/// Returns [AsyncValue<WindData>] that auto-refetches when either
/// [effectivePositionProvider] or [selectedAltitudeProvider] changes.
///
/// Throws [StateError] if no position is available yet.
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
