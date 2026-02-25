import 'dart:async';

import '../../core/models/position_data.dart';
import '../../core/models/sensor_state.dart';
import '../../core/services/sensor_service.dart';
import '../compass_service.dart';
import '../location_service.dart';

/// Implementation of [SensorService] that wraps real device sensors.
///
/// Owns a [CompassService] (compass heading + pitch) and [LocationService]
/// (GPS position) internally. Maps their streams to the new Freezed model
/// types ([SensorState] and [PositionData]).
///
/// ## Usage
/// ```dart
/// final service = DeviceSensorService();
/// service.start(); // Starts platform sensors + stream mapping
/// ```
///
/// For testing, construct with injected services and call
/// [wireStreams] instead of [start] to skip platform channel access:
/// ```dart
/// final compass = CompassService();
/// final location = LocationService();
/// final service = DeviceSensorService(
///   compassService: compass,
///   locationService: location,
///   autoStart: false,
/// );
/// service.wireStreams(); // Only maps streams, no platform channels
/// compass.setRawHeading(127.3);
/// compass.tick();
/// ```
///
/// ## Altitude
/// The [PositionData.altitude] field comes from [LocationData.altitude],
/// which is populated from geolocator's `Position.altitude` (meters above
/// sea level). This is needed for OGC EDR wind queries (P2B-006) which
/// use observer altitude for surface vs. pressure level distinction.
///
/// ## Pause/Resume Limitations
/// The underlying CompassService and LocationService do not support
/// pause/resume natively. [pause] disposes both services. [resume] creates
/// new instances and restarts them. This is functional but not ideal --
/// Phase 2 may improve this.
class DeviceSensorService implements SensorService {
  CompassService _compassService;
  LocationService _locationService;

  final _sensorController = StreamController<SensorState>.broadcast();
  final _positionController = StreamController<PositionData>.broadcast();

  StreamSubscription? _compassSub;
  StreamSubscription? _locationSub;

  bool _isPaused = false;

  /// Creates a DeviceSensorService.
  ///
  /// By default, auto-starts both platform services and stream mapping.
  /// Pass [autoStart] = false to defer starting (useful for testing).
  /// Optionally accepts pre-created services for testing.
  DeviceSensorService({
    CompassService? compassService,
    LocationService? locationService,
    bool autoStart = true,
  })  : _compassService = compassService ?? CompassService(),
        _locationService = locationService ?? LocationService() {
    if (autoStart) {
      start();
    }
  }

  /// Starts the platform sensors and sets up stream mapping.
  ///
  /// Calls [CompassService.start] and [LocationService.start] (which access
  /// platform channels), then subscribes to their streams.
  ///
  /// For testing without platform channels, use [wireStreams] instead.
  void start() {
    // Start the compass service (synchronous)
    _compassService.start();

    // Start the location service (async, fire-and-forget)
    _locationService.start();

    // Set up stream mapping
    wireStreams();
  }

  /// Sets up stream subscriptions without starting platform services.
  ///
  /// This wires [CompassService.stream] -> [sensorStream] and
  /// [LocationService.stream] -> [positionStream] without touching
  /// platform channels. Useful for unit testing with `@visibleForTesting`
  /// helpers like [CompassService.tick] and [LocationService.setPosition].
  void wireStreams() {
    // Map CompassData -> SensorState
    _compassSub = _compassService.stream.listen((data) {
      if (!_sensorController.isClosed) {
        _sensorController.add(SensorState(
          compassHeading: data.heading,
          pitch: data.pitch,
          timestamp: DateTime.now(),
        ));
      }
    });

    // Map LocationData -> PositionData
    _locationSub = _locationService.stream.listen((data) {
      if (!_positionController.isClosed) {
        _positionController.add(PositionData(
          latitude: data.latitude,
          longitude: data.longitude,
          altitude: data.altitude, // From geolocator's Position.altitude
          accuracy: data.accuracy,
          timestamp: data.timestamp,
        ));
      }
    });
  }

  @override
  Stream<SensorState> get sensorStream => _sensorController.stream;

  @override
  Stream<PositionData> get positionStream => _positionController.stream;

  @override
  void pause() {
    if (_isPaused) return;
    _isPaused = true;

    _compassSub?.cancel();
    _compassSub = null;
    _locationSub?.cancel();
    _locationSub = null;

    _compassService.dispose();
    _locationService.dispose();
  }

  @override
  void resume() {
    if (!_isPaused) return;
    _isPaused = false;

    // Re-create services since dispose() closes their stream controllers
    _compassService = CompassService();
    _locationService = LocationService();
    start();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _locationSub?.cancel();
    _compassService.dispose();
    _locationService.dispose();
    _sensorController.close();
    _positionController.close();
  }
}
