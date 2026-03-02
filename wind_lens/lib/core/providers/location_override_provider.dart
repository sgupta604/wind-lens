import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/position_data.dart';
import 'sensor_providers.dart';

part 'location_override_provider.g.dart';

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
@riverpod
class LocationOverride extends _$LocationOverride {
  @override
  PositionData? build() => null;

  /// Sets the location override to the given position.
  void set(PositionData position) {
    state = position;
  }

  /// Clears the location override, reverting to GPS.
  void clear() {
    state = null;
  }
}

/// Returns the effective position for data providers.
///
/// If a [locationOverrideProvider] is set, returns it.
/// Otherwise, falls through to [stablePositionProvider] (debounced GPS).
///
/// All position-dependent data providers (wind, horizon, scene, dome)
/// should watch this provider instead of [stablePositionProvider] directly.
@riverpod
PositionData? effectivePosition(EffectivePositionRef ref) {
  final override = ref.watch(locationOverrideProvider);
  final gpsPosition = ref.watch(stablePositionProvider);
  return override ?? gpsPosition;
}
