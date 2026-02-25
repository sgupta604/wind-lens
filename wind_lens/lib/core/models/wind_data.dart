import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/altitude_level.dart';

part 'wind_data.freezed.dart';
part 'wind_data.g.dart';

/// Immutable data class representing wind vector data.
///
/// Stores u/v components as primary fields (not speed/direction) because:
/// - OGC EDR API returns u/v natively (no wasteful round-trip conversion)
/// - Particle physics uses u/v directly (no trig per particle per frame)
/// - Speed/direction are computed getters for UI display/debug only
///
/// The [altitude] field uses [AltitudeLevel] enum instead of raw meters,
/// reflecting that the app uses discrete altitude levels, not arbitrary values.
///
/// Uses the private constructor pattern (`const WindData._()`) to allow
/// custom computed getters on a Freezed class.
@freezed
class WindData with _$WindData {
  const WindData._();

  const factory WindData({
    /// Eastward wind component in m/s.
    /// Positive = wind blowing toward east.
    required double uComponent,

    /// Northward wind component in m/s.
    /// Positive = wind blowing toward north.
    required double vComponent,

    /// Gust speed in m/s. Defaults to 0.0.
    @Default(0.0) double gustSpeed,

    /// Altitude level for this wind data.
    required AltitudeLevel altitude,

    /// When this wind data was recorded.
    required DateTime timestamp,
  }) = _WindData;

  factory WindData.fromJson(Map<String, dynamic> json) =>
      _$WindDataFromJson(json);

  /// Wind speed in m/s (magnitude of the wind vector).
  double get speed =>
      sqrt(uComponent * uComponent + vComponent * vComponent);

  /// Wind direction in radians (meteorological: direction wind comes FROM).
  double get directionRadians => atan2(-uComponent, -vComponent);

  /// Wind direction in degrees (0-360, meteorological convention).
  double get directionDegrees =>
      (directionRadians * 180 / pi + 360) % 360;

  /// Creates a WindData from speed and direction (convenience factory).
  ///
  /// Converts speed/direction to u/v components internally.
  /// Useful for creating mock data with human-readable parameters.
  factory WindData.fromSpeedDirection({
    required double speed,
    required double directionDegrees,
    double gustSpeed = 0.0,
    required AltitudeLevel altitude,
    DateTime? timestamp,
  }) {
    final dirRad = directionDegrees * pi / 180;
    return WindData(
      uComponent: -speed * sin(dirRad),
      vComponent: -speed * cos(dirRad),
      gustSpeed: gustSpeed,
      altitude: altitude,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Creates a zero-wind instance at surface level.
  static WindData zero() => WindData(
        uComponent: 0,
        vComponent: 0,
        altitude: AltitudeLevel.surface,
        timestamp: DateTime.now(),
      );
}
