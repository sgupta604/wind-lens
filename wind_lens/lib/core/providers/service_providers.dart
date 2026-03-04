import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/horizon_provider.dart' as core;
import '../services/sensor_service.dart';
import '../services/sky_detector.dart';
import '../services/wind_data_source.dart';
import '../../services/horizon/cached_horizon_provider.dart';
import '../../services/horizon/hwt_horizon_provider.dart';
import '../../services/sensors/device_sensor_service.dart';
import '../../services/sky_detection/hsv_sky_detector.dart';
import '../../services/wind/cached_wind_source.dart';
import '../../services/wind/ogc_edr_wind_source.dart';
import '../../services/wind/wind_api_client.dart';
import 'lifecycle_provider.dart';

part 'service_providers.g.dart';

/// Provides the [SensorService] implementation.
///
/// Currently returns [DeviceSensorService] which wraps the
/// native compass + GPS sensors. Also creates an [AppLifecycleObserver]
/// that pauses sensors when the app is backgrounded and resumes them
/// when the app returns to the foreground.
///
/// Both the service and the lifecycle observer are disposed when
/// the provider is no longer watched.
@riverpod
SensorService sensorService(SensorServiceRef ref) {
  final service = DeviceSensorService();
  final lifecycleObserver = AppLifecycleObserver(sensorService: service);
  ref.onDispose(() {
    lifecycleObserver.dispose();
    service.dispose();
  });
  return service;
}

/// Provides the [WindDataSource] implementation.
///
/// Returns [CachedWindDataSource] wrapping [OgcEdrWindDataSource] which
/// fetches real wind data from OGC EDR APIs (Shyft primary, Folkweather
/// fallback). The cache uses a 10-minute TTL keyed by rounded lat/lng
/// plus altitude level.
///
/// The [WindApiClient] HTTP client is disposed when this provider is
/// no longer watched.
@riverpod
WindDataSource windDataSource(WindDataSourceRef ref) {
  final apiClient = WindApiClient();
  ref.onDispose(() => apiClient.dispose());
  return CachedWindDataSource(
    delegate: OgcEdrWindDataSource(apiClient: apiClient),
    ttl: const Duration(minutes: 10),
  );
}

/// Provides the [HorizonProvider] implementation.
///
/// Returns [CachedHorizonProvider] wrapping [HwtHorizonProvider] which
/// fetches real terrain horizon profiles from the HeyWhatsThat API.
/// The cache uses 3-decimal-place lat/lng keys (~111m resolution) with
/// no expiry (terrain does not change).
///
/// The [HwtHorizonProvider] HTTP client is disposed when this provider
/// is no longer watched.
@riverpod
core.HorizonProvider horizonProviderService(HorizonProviderServiceRef ref) {
  final hwt = HwtHorizonProvider();
  ref.onDispose(() => hwt.dispose());
  return CachedHorizonProvider(delegate: hwt);
}

/// Provides the [SkyDetector] implementation.
///
/// Currently returns [HsvSkyDetector] which wraps the existing
/// auto-calibrating HSV sky detection. Disposed when no longer watched.
@riverpod
SkyDetector skyDetectorInstance(SkyDetectorInstanceRef ref) {
  return HsvSkyDetector();
}
