import '../models/horizon_profile.dart';

/// Abstract interface for terrain horizon profile providers.
///
/// Fetches terrain horizon profiles for a given location. A horizon profile
/// maps compass bearings to elevation angles where terrain meets the sky.
///
/// Implementations:
/// - `MockHorizonProvider` -- returns flat horizon (0 degrees at all bearings)
/// - `HeyWhatsThatHorizonProvider` -- calls HWT API (Phase 2b feature P2B-002)
/// - `CachedHorizonProvider` -- decorator that wraps any HorizonProvider with
///   local caching (Phase 2b feature P2B-003)
abstract class HorizonProvider {
  /// Gets the terrain horizon profile for the given coordinates.
  ///
  /// [latitude]: Latitude in degrees (-90 to 90).
  /// [longitude]: Longitude in degrees (-180 to 180).
  ///
  /// Returns a [HorizonProfile] with bearing->elevation angle mappings.
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  });
}
