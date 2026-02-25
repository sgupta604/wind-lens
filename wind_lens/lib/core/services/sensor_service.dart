import '../models/position_data.dart';
import '../models/sensor_state.dart';

/// Abstract interface for unified sensor access.
///
/// Wraps platform-specific sensor APIs (compass, accelerometer, GPS)
/// behind a clean stream-based interface.
///
/// Implementations:
/// - `DeviceSensorService` -- wraps CompassService + LocationService
/// - `MockSensorService` -- emits controllable fake data for testing (future)
abstract class SensorService {
  /// Stream of compass heading and pitch sensor readings.
  ///
  /// Emits [SensorState] at the underlying sensor rate (typically 20Hz).
  Stream<SensorState> get sensorStream;

  /// Stream of GPS position readings.
  ///
  /// Emits [PositionData] when the device moves (distance-filtered).
  Stream<PositionData> get positionStream;

  /// Pauses sensor subscriptions to save battery.
  ///
  /// Call when the app is backgrounded or sensors are not needed.
  void pause();

  /// Resumes sensor subscriptions after a pause.
  ///
  /// Call when the app returns to the foreground.
  void resume();

  /// Disposes all resources and stops sensor subscriptions.
  ///
  /// Call when the service is no longer needed. After calling dispose(),
  /// the service cannot be resumed -- create a new instance instead.
  void dispose();
}
