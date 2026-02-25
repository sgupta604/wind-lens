import '../../core/models/horizon_profile.dart';
import '../../core/services/horizon_provider.dart';

/// Mock implementation of [HorizonProvider] that returns a flat horizon.
///
/// Returns a [HorizonProfile] with 0-degree elevation at all bearings,
/// meaning "the horizon is flat everywhere" (no terrain obstructions).
///
/// Useful for:
/// - Testing without a real terrain API
/// - Indoor use where terrain data is irrelevant
/// - Fallback when HeyWhatsThat API is unavailable
class MockHorizonProvider implements HorizonProvider {
  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) {
    return Future.value(HorizonProfile.flat(latitude, longitude));
  }
}
