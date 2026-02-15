import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_data.dart';

/// Service for managing GPS location data.
///
/// Wraps the `geolocator` package behind a clean interface, following the
/// same pattern as [CompassService]: broadcast StreamController, lifecycle
/// methods (`start()`/`dispose()`), direct getters for current values, and
/// `@visibleForTesting` helpers for unit testing without platform channels.
///
/// Key difference from CompassService: `start()` is `Future<void>` because
/// it must request GPS permission before accessing position data.
///
/// Usage:
/// ```dart
/// final locationService = LocationService();
/// await locationService.start();
/// locationService.stream.listen((data) {
///   print('Lat: ${data.latitude}, Lon: ${data.longitude}');
/// });
/// // When done:
/// locationService.dispose();
/// ```
class LocationService {
  // --- Internal state ---

  /// Current latitude in degrees.
  double _latitude = 0;

  /// Current longitude in degrees.
  double _longitude = 0;

  /// Whether location permission has been granted.
  bool _hasPermission = false;

  /// Subscription to geolocator position stream.
  StreamSubscription<Position>? _positionSub;

  /// Stream controller for broadcasting location updates.
  final _controller = StreamController<LocationData>.broadcast();

  // --- Public API ---

  /// Stream of [LocationData] updates.
  ///
  /// This is a broadcast stream, allowing multiple listeners.
  /// Emits when the device moves more than [_distanceFilter] meters.
  Stream<LocationData> get stream => _controller.stream;

  /// Current latitude in degrees (-90 to 90).
  double get latitude => _latitude;

  /// Current longitude in degrees (-180 to 180).
  double get longitude => _longitude;

  /// Whether location permission has been granted.
  ///
  /// Returns `false` until permission is successfully obtained via [start].
  /// Downstream features should check this before using GPS data.
  bool get hasPermission => _hasPermission;

  /// Distance filter in meters for position updates.
  ///
  /// Only triggers an update when the device moves more than this distance.
  /// 50 meters is battery-friendly and sufficient for terrain detection.
  static const int _distanceFilter = 50;

  // --- Lifecycle ---

  /// Starts the location service.
  ///
  /// Checks if location services are enabled, requests permission if needed,
  /// gets an initial position, and starts listening to position updates.
  ///
  /// If permission is denied or location services are disabled, sets
  /// [hasPermission] to `false` and returns without crashing. The stream
  /// will simply never emit in that case.
  Future<void> start() async {
    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        _hasPermission = false;
        return;
      }

      // 2. Check current permission status
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permission denied');
          _hasPermission = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            'LocationService: Location permission denied permanently');
        _hasPermission = false;
        return;
      }

      // 3. Permission granted -- get initial position
      _hasPermission = true;
      try {
        final position = await Geolocator.getCurrentPosition();
        _onPosition(position);
      } catch (e) {
        debugPrint('LocationService: Failed to get initial position: $e');
      }

      // 4. Start listening for position updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: _distanceFilter,
      );

      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPosition,
        onError: (e) =>
            debugPrint('LocationService: Position stream error: $e'),
      );
    } catch (e) {
      debugPrint('LocationService: Failed to start: $e');
      _hasPermission = false;
    }
  }

  /// Handles a new position from geolocator.
  void _onPosition(Position position) {
    _latitude = position.latitude;
    _longitude = position.longitude;

    if (!_controller.isClosed) {
      _controller.add(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      ));
    }
  }

  // --- Test helpers ---

  /// Directly sets the position for unit testing.
  ///
  /// Sets latitude, longitude, marks permission as granted, and emits
  /// a [LocationData] event to the stream. Use this to test downstream
  /// consumers without requiring real GPS hardware.
  @visibleForTesting
  void setPosition(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
    _hasPermission = true;

    if (!_controller.isClosed) {
      _controller.add(LocationData(
        latitude: lat,
        longitude: lon,
        accuracy: 0,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Releases resources and stops listening to position updates.
  ///
  /// Cancels the position subscription and closes the stream controller.
  /// Always call this method when the service is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _positionSub?.cancel();
    _controller.close();
  }
}
