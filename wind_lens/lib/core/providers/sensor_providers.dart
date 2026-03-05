import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/position_data.dart';
import '../models/sensor_state.dart';
import 'service_providers.dart';

part 'sensor_providers.g.dart';

/// Provides the raw GPS position stream from the sensor service.
@riverpod
Stream<PositionData> gpsPosition(GpsPositionRef ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.positionStream;
}

/// Provides the raw sensor (compass/pitch) stream from the sensor service.
@riverpod
Stream<SensorState> rawSensor(RawSensorRef ref) {
  final service = ref.watch(sensorServiceProvider);
  return service.sensorStream;
}

/// Debounced GPS position that only updates when the user moves >100m.
///
/// This prevents thrashing downstream providers (horizon, wind) on GPS jitter.
/// Returns null until the first GPS fix is received.
@riverpod
class StablePosition extends _$StablePosition {
  PositionData? _lastEmitted;

  @override
  PositionData? build() {
    final asyncValue = ref.watch(gpsPositionProvider);
    final raw = asyncValue.valueOrNull;
    if (raw == null) return _lastEmitted;

    if (_lastEmitted == null || _distanceMeters(_lastEmitted!, raw) > 100) {
      _lastEmitted = raw;
      return raw;
    }
    return _lastEmitted;
  }

  /// Haversine distance in meters between two positions.
  /// Exposed for testing via [distanceMetersForTest].
  static double _distanceMeters(PositionData a, PositionData b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final h = sinDLat * sinDLat +
        cos(_toRadians(a.latitude)) *
            cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;
    return 2 * earthRadius * asin(sqrt(h));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Exposed for unit testing the haversine calculation.
  @visibleForTesting
  static double distanceMetersForTest(PositionData a, PositionData b) =>
      _distanceMeters(a, b);
}

/// Sidecar for high-frequency sensor data (heading/pitch).
///
/// These are [ValueNotifier]s rather than Riverpod state because
/// compass/pitch updates at 20-50Hz. Pushing every reading through
/// Riverpod rebuilds would kill frame rate.
///
/// The [ParticleOverlay] CustomPainter listens to these directly
/// via `super(repaint: Listenable.merge([heading, pitch]))`.
class SensorNotifiers {
  /// Current compass heading in degrees (0-360).
  final ValueNotifier<double> heading = ValueNotifier(0.0);

  /// Current device pitch in degrees.
  final ValueNotifier<double> pitch = ValueNotifier(0.0);

  /// Disposes both notifiers.
  void dispose() {
    heading.dispose();
    pitch.dispose();
  }
}

/// Provides [SensorNotifiers] that pipe high-frequency sensor data
/// to [ValueNotifier]s for direct consumption by CustomPainters.
///
/// This avoids Riverpod rebuilds at sensor rate (20-50Hz).
@Riverpod(keepAlive: true)
SensorNotifiers sensorNotifiers(SensorNotifiersRef ref) {
  final notifiers = SensorNotifiers();

  final asyncStream = ref.watch(rawSensorProvider);

  asyncStream.whenData((state) {
    notifiers.heading.value = state.compassHeading;
    notifiers.pitch.value = state.pitch;
  });

  ref.onDispose(() {
    notifiers.dispose();
  });

  return notifiers;
}
