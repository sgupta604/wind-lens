import '../../core/models/position_data.dart';
import '../../core/models/wind_data.dart';
import '../../core/services/wind_data_source.dart';
import '../../models/altitude_level.dart';
import '../fake_wind_service.dart';

/// Mock implementation of [WindDataSource] that wraps [FakeWindService].
///
/// Delegates wind data generation to the existing FakeWindService,
/// which produces time-varying sinusoidal wind patterns. This wrapper
/// adapts the old synchronous API to the async [WindDataSource] interface.
///
/// The [position] parameter is currently ignored by the underlying
/// FakeWindService (wind varies by time only, not location). When
/// OGC EDR wind data (P2B-006) is implemented, the real WindDataSource
/// will use position for spatial queries.
class MockWindDataSource implements WindDataSource {
  /// The underlying fake wind service.
  final FakeWindService _fakeService;

  /// Creates a MockWindDataSource.
  ///
  /// Optionally accepts a [FakeWindService] instance for testing.
  /// If not provided, creates a new instance internally.
  MockWindDataSource({FakeWindService? fakeService})
      : _fakeService = fakeService ?? FakeWindService();

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) {
    return Future.value(_fakeService.getWindForAltitude(altitude));
  }

  @override
  bool get isSimulated => true;
}
