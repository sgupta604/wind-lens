import 'package:flutter/widgets.dart';

import '../services/sensor_service.dart';

/// Observes app lifecycle changes and pauses/resumes a [SensorService].
///
/// When the app goes to background (paused, inactive, hidden, or detached),
/// the sensor service is paused to save battery. When the app returns to
/// the foreground (resumed), the sensor service is resumed.
///
/// Usage:
/// ```dart
/// final observer = AppLifecycleObserver(sensorService: myService);
/// // Observer automatically registers with WidgetsBinding.
/// // Call dispose() when done.
/// observer.dispose();
/// ```
///
/// This class is designed to be testable: the [didChangeAppLifecycleState]
/// method can be called directly in unit tests without platform channels.
class AppLifecycleObserver with WidgetsBindingObserver {
  /// The sensor service to pause/resume on lifecycle changes.
  final SensorService sensorService;

  /// Whether the sensor service is currently paused by this observer.
  ///
  /// Prevents double-pause and double-resume calls.
  bool _isPaused = false;

  /// Creates an [AppLifecycleObserver] and registers it with [WidgetsBinding].
  ///
  /// The observer will immediately start watching lifecycle events.
  /// Pass an already-started [SensorService].
  AppLifecycleObserver({required this.sensorService}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPaused) {
          _isPaused = false;
          sensorService.resume();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (!_isPaused) {
          _isPaused = true;
          sensorService.pause();
        }
    }
  }

  /// Removes this observer from [WidgetsBinding].
  ///
  /// Call this when the lifecycle observer is no longer needed.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
