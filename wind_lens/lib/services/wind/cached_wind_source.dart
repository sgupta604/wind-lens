import 'package:wind_lens/core/models/position_data.dart';
import 'package:wind_lens/core/models/wind_data.dart';
import 'package:wind_lens/core/services/wind_data_source.dart';
import 'package:wind_lens/models/altitude_level.dart';

/// A cached entry storing wind data and its fetch timestamp.
class _CacheEntry {
  final WindData data;
  final DateTime fetchedAt;

  _CacheEntry(this.data) : fetchedAt = DateTime.now();
}

/// Decorator that adds TTL-based memory caching to any [WindDataSource].
///
/// Cache key is built from lat/lng (rounded to 2 decimal places, ~1.1km)
/// plus the altitude level. Wind data changes over time so entries expire
/// after [ttl] (default 10 minutes).
///
/// Unlike [CachedHorizonProvider], wind data is NOT persisted to disk
/// because it becomes stale quickly and the cache exists purely to
/// reduce redundant API calls during a single session.
///
/// Usage:
/// ```dart
/// final cached = CachedWindDataSource(
///   delegate: MockWindDataSource(),
///   ttl: Duration(minutes: 10),
/// );
/// final wind = await cached.getWind(position: pos, altitude: AltitudeLevel.surface);
/// ```
class CachedWindDataSource implements WindDataSource {
  /// The wrapped data source to delegate to on cache miss.
  final WindDataSource delegate;

  /// Time-to-live for cache entries.
  final Duration ttl;

  /// In-memory cache keyed by rounded position + altitude.
  final Map<String, _CacheEntry> _cache = {};

  /// Creates a [CachedWindDataSource] wrapping the given [delegate].
  ///
  /// [ttl] defaults to 10 minutes.
  CachedWindDataSource({
    required this.delegate,
    this.ttl = const Duration(minutes: 10),
  });

  /// Builds a cache key from position (2 decimal places) and altitude.
  static String _cacheKey(PositionData position, AltitudeLevel altitude) {
    final lat = position.latitude.toStringAsFixed(2);
    final lng = position.longitude.toStringAsFixed(2);
    return '${lat}_${lng}_${altitude.name}';
  }

  @override
  Future<WindData> getWind({
    required PositionData position,
    required AltitudeLevel altitude,
  }) async {
    final key = _cacheKey(position, altitude);

    // Check memory cache
    final entry = _cache[key];
    if (entry != null) {
      final age = DateTime.now().difference(entry.fetchedAt);
      if (age < ttl) {
        return entry.data;
      }
      // TTL expired, remove stale entry
      _cache.remove(key);
    }

    // Cache miss: delegate to wrapped source
    final result = await delegate.getWind(
      position: position,
      altitude: altitude,
    );

    // Store in cache
    _cache[key] = _CacheEntry(result);

    return result;
  }

  @override
  bool get isSimulated => delegate.isSimulated;

  /// Invalidates all cache entries for a specific altitude level.
  ///
  /// Use this when the user changes altitude and you want to force
  /// a fresh fetch even if the cached data hasn't expired.
  void invalidateForAltitude(AltitudeLevel altitude) {
    final keysToRemove = _cache.keys
        .where((key) => key.endsWith('_${altitude.name}'))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Clears the entire cache.
  void invalidateAll() {
    _cache.clear();
  }
}
