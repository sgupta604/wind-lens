import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/horizon_provider.dart' as core;
import '../services/sensor_service.dart';
import '../services/sky_detector.dart';
import '../services/wind_data_source.dart';
import '../../services/horizon/mock_horizon_provider.dart';
import '../../services/sensors/device_sensor_service.dart';
import '../../services/sky_detection/hsv_sky_detector.dart';
import '../../services/wind/mock_wind_source.dart';
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
/// Currently returns [MockWindDataSource] which wraps [FakeWindService].
/// Swap this single line when OGC EDR is ready.
@riverpod
WindDataSource windDataSource(WindDataSourceRef ref) {
  return MockWindDataSource();
}

/// Provides the [HorizonProvider] implementation.
///
/// Currently returns [MockHorizonProvider] which returns flat horizons.
/// Swap when HeyWhatsThat client is ready.
@riverpod
core.HorizonProvider horizonProviderService(HorizonProviderServiceRef ref) {
  return MockHorizonProvider();
}

/// Provides the [SkyDetector] implementation.
///
/// Currently returns [HsvSkyDetector] which wraps the existing
/// auto-calibrating HSV sky detection. Disposed when no longer watched.
@riverpod
SkyDetector skyDetectorInstance(SkyDetectorInstanceRef ref) {
  return HsvSkyDetector();
}
