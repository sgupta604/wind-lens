// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_override_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$effectivePositionHash() => r'a7f93c1d911f73c3cef70f246daff1f3c5fea5cc';

/// Returns the effective position for data providers.
///
/// If a [locationOverrideProvider] is set, returns it.
/// Otherwise, falls through to [stablePositionProvider] (debounced GPS).
///
/// All position-dependent data providers (wind, horizon, scene, dome)
/// should watch this provider instead of [stablePositionProvider] directly.
///
/// Copied from [effectivePosition].
@ProviderFor(effectivePosition)
final effectivePositionProvider = AutoDisposeProvider<PositionData?>.internal(
  effectivePosition,
  name: r'effectivePositionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$effectivePositionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectivePositionRef = AutoDisposeProviderRef<PositionData?>;
String _$locationOverrideHash() => r'1a71392a96d44772293784deb66d2d36d2cbf760';

/// User-set location override for fetching wind/horizon data from a
/// different position than the device's GPS.
///
/// Defaults to `null` (use GPS). Session-only: resets on app restart.
///
/// When set, [effectivePositionProvider] returns this override instead
/// of [stablePositionProvider], causing all data providers (wind, horizon,
/// scene, dome) to refetch for the overridden location.
///
/// Sensor data (compass heading, pitch) is NOT affected.
///
/// Copied from [LocationOverride].
@ProviderFor(LocationOverride)
final locationOverrideProvider =
    AutoDisposeNotifierProvider<LocationOverride, PositionData?>.internal(
      LocationOverride.new,
      name: r'locationOverrideProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationOverrideHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocationOverride = AutoDisposeNotifier<PositionData?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
