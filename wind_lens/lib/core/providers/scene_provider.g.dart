// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sceneStateHash() => r'a7948ccc5f45c483b7be2dde170a8619889935ba';

/// Composes all data sources into a single [SceneState] snapshot.
///
/// Returns `null` while critical data is still loading:
/// - **Blocks on:** position, wind, sensor data (cannot render without these)
/// - **Falls back for:** horizon (uses flat), sky mask (uses full sky)
///
/// This means the camera feed appears immediately, and particles appear
/// as soon as wind data resolves. Particles refine to sky-only regions
/// once sky detection kicks in.
///
/// Copied from [sceneState].
@ProviderFor(sceneState)
final sceneStateProvider = AutoDisposeProvider<SceneState?>.internal(
  sceneState,
  name: r'sceneStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sceneStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SceneStateRef = AutoDisposeProviderRef<SceneState?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
