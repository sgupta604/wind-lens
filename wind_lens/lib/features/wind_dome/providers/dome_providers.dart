import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/location_override_provider.dart';
import '../../../services/wind/dome_wind_fetcher.dart';
import '../../../services/wind/wind_api_client.dart';
import '../models/dome_wind_field.dart';
import '../models/dome_wind_profile.dart';

/// DI swap-point for [DomeWindFetcher].
///
/// Override this provider in tests to inject a fake fetcher.
final domeWindFetcherProvider = Provider<DomeWindFetcher>((ref) {
  final apiClient = WindApiClient();
  ref.onDispose(() => apiClient.dispose());
  return DomeWindFetcher(apiClient: apiClient);
});

/// User-selected dome radius in meters.
///
/// Presets: 500, 1000, 2000, 5000, 15000, 50000. Default is 1000.0 (1km),
/// which matches the "1km" preset button exactly for clean UX.
///
/// Drives:
/// - Particle velocity scaling via renderScale (domeRRender / domeSizeMeters)
/// - DomeWindFetcher: grid vs point fetch based on gridFetchThresholdMeters
/// - DomeInfoBar size preset button highlighting
final domeSizeProvider = StateProvider<double>((ref) => 1000.0);

/// User-selected forecast hour offset (0 = live, 1-72 = forecast).
///
/// Defaults to 0 (live conditions). When changed, [currentDomeWindFieldProvider]
/// instantly selects a different hourly entry from the cached profile --
/// no network call required.
final hoursAheadProvider = StateProvider<int>((ref) => 0);

/// Fetches the dome wind profile for the effective position.
///
/// Watches [effectivePositionProvider] and [domeSizeProvider] so it
/// auto-refetches when the user moves >100m, sets a location override,
/// or changes the dome size. When dome size >= 15km, triggers grid-based
/// fetching with spatial wind variation.
///
/// The [DomeWindFetcher] caches results for 10 minutes and separates
/// grid vs point entries, so rapid provider rebuilds do not trigger
/// redundant API calls.
final domeWindProfileProvider =
    FutureProvider<DomeWindProfile?>((ref) async {
  final position = ref.watch(effectivePositionProvider);
  if (position == null) return null;

  final fetcher = ref.watch(domeWindFetcherProvider);
  final domeSize = ref.watch(domeSizeProvider);
  return fetcher.fetch(
    position.latitude,
    position.longitude,
    radiusMeters: domeSize,
  );
});

/// Selects the current hour's wind field from the cached profile.
///
/// Reads [domeWindProfileProvider] for the full 72-hour profile and
/// [hoursAheadProvider] for the selected hour offset. Returns null
/// while the profile is loading or if GPS is unavailable.
///
/// This is what the tick loop reads every frame -- no network, instant.
final currentDomeWindFieldProvider = Provider<DomeWindField?>((ref) {
  final profile = ref.watch(domeWindProfileProvider).valueOrNull;
  if (profile == null) return null;

  final hours = ref.watch(hoursAheadProvider);
  return profile.fieldAt(hours);
});
