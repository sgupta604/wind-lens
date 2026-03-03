import '../../core/models/position_data.dart';
import '../../core/models/wind_data.dart';
import '../../core/services/wind_data_source.dart';
import '../../models/altitude_level.dart';
import 'wind_api_client.dart';

/// Real wind data source using OGC EDR weather APIs.
///
/// Implements [WindDataSource] by delegating HTTP calls to [WindApiClient],
/// which handles the Shyft/Folkweather dual-API fallback strategy.
///
/// Maps [AltitudeLevel] to API pressure levels:
/// - [AltitudeLevel.surface] -> 0 (uses surface collection, not isobaric)
/// - [AltitudeLevel.midLevel] -> 850 hPa (~1,500m)
/// - [AltitudeLevel.jetStream] -> 250 hPa (~10,500m)
///
/// On API failure, returns valid [WindData] with zero components (particles
/// render but don't move) rather than throwing. This provides graceful
/// degradation -- the camera feed and sky detection continue working.
///
/// Usage:
/// ```dart
/// final source = OgcEdrWindDataSource();
/// final wind = await source.getWind(
///   position: gpsPosition,
///   altitude: AltitudeLevel.midLevel,
/// );
/// ```
class OgcEdrWindDataSource implements WindDataSource {
  /// The shared API client for HTTP requests and response parsing.
  final WindApiClient _apiClient;

  /// Creates an OgcEdrWindDataSource.
  ///
  /// Optionally accepts a [WindApiClient] for testing. If not provided,
  /// creates a default client with a real [http.Client].
  OgcEdrWindDataSource({WindApiClient? apiClient})
      : _apiClient = apiClient ?? WindApiClient();

  @override
  bool get isSimulated => false;

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    final pressureLevel = _altitudeToPressure(altitude);
    final (u, v, _) = await _apiClient.fetchPointWind(
      lat: position.latitude,
      lng: position.longitude,
      pressureLevel: pressureLevel,
    );
    return WindData(
      uComponent: u,
      vComponent: v,
      altitude: altitude,
      timestamp: DateTime.now(),
    );
  }

  /// Maps [AltitudeLevel] enum to API pressure level.
  ///
  /// Returns 0 for surface (special collection on Shyft, z=10 on
  /// Folkweather), otherwise the pressure in hPa.
  static int _altitudeToPressure(AltitudeLevel altitude) {
    return switch (altitude) {
      AltitudeLevel.surface => 0,
      AltitudeLevel.midLevel => 850,
      AltitudeLevel.jetStream => 250,
    };
  }
}
