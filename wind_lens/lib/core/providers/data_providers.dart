import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/horizon_profile.dart';
import '../models/wind_data.dart';
import '../models/sky_mask_data.dart';
import '../../models/altitude_level.dart';
import 'sensor_providers.dart';
import 'service_providers.dart';

part 'data_providers.g.dart';

/// Fetches the horizon profile for the current stable position.
///
/// Returns [AsyncValue<HorizonProfile>] that auto-refetches when
/// [stablePositionProvider] changes (i.e., user moves >100m).
///
/// Throws [StateError] if no GPS fix is available yet.
@riverpod
Future<HorizonProfile> horizonProfile(HorizonProfileRef ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) throw StateError('No GPS fix yet');

  final provider = ref.watch(horizonProviderServiceProvider);
  return provider.getHorizon(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}

/// Fetches wind data for the current stable position and selected altitude.
///
/// Returns [AsyncValue<WindData>] that auto-refetches when either
/// [stablePositionProvider] or [selectedAltitudeProvider] changes.
///
/// Throws [StateError] if no GPS fix is available yet.
@riverpod
Future<WindData> windData(WindDataRef ref) async {
  final position = ref.watch(stablePositionProvider);
  if (position == null) throw StateError('No GPS fix yet');

  final altitude = ref.watch(selectedAltitudeProvider);
  final source = ref.watch(windDataSourceProvider);
  return source.getWind(position: position, altitude: altitude);
}

/// User-selected altitude level for particle visualization.
///
/// Defaults to [AltitudeLevel.surface]. When changed, triggers
/// [windDataProvider] to refetch wind data for the new altitude.
@riverpod
class SelectedAltitude extends _$SelectedAltitude {
  @override
  AltitudeLevel build() => AltitudeLevel.surface;

  void select(AltitudeLevel level) {
    state = level;
  }
}

/// User-selected sky detection mode.
///
/// Defaults to [SkyDetectionMethod.hsv]. When changed, the sky detector
/// provider will return the appropriate implementation.
@riverpod
class DetectionMode extends _$DetectionMode {
  @override
  SkyDetectionMethod build() => SkyDetectionMethod.hsv;

  void select(SkyDetectionMethod mode) {
    state = mode;
  }
}
