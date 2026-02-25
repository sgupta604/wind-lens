import '../../models/altitude_level.dart';
import '../models/position_data.dart';
import '../models/wind_data.dart';

/// Abstract interface for wind data providers.
///
/// Provides wind field data for a given location and altitude level.
///
/// Implementations:
/// - `MockWindDataSource` -- wraps existing FakeWindService (simulated wind)
/// - `OgcEdrWindDataSource` -- real wind from OGC EDR API (Phase 2b feature P2B-006)
abstract class WindDataSource {
  /// Gets wind data for the given position and altitude level.
  ///
  /// [position]: GPS location to query wind for.
  /// [altitude]: Altitude level to query wind at.
  ///
  /// Returns a [WindData] with u/v components, speed, and direction.
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  });

  /// Whether this source provides simulated (not real) data.
  bool get isSimulated;
}
