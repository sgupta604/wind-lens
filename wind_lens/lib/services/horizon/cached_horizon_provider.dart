import 'dart:convert';

import 'package:wind_lens/core/models/horizon_profile.dart';
import 'package:wind_lens/core/services/horizon_provider.dart';

/// Decorator that adds memory + disk caching to any [HorizonProvider].
///
/// Cache key is built from lat/lng rounded to 3 decimal places (~111m resolution).
/// Terrain profiles don't change, so cached entries never expire.
///
/// Memory cache: in-process `Map<String, HorizonProfile>`.
/// Disk cache: JSON string that can be saved/loaded via [saveToDiskJson] and
/// [loadFromDiskJson]. The caller is responsible for persisting the JSON
/// (e.g., via SharedPreferences or a file). This avoids a hard dependency
/// on path_provider or SharedPreferences in this class.
///
/// Usage:
/// ```dart
/// final cached = CachedHorizonProvider(delegate: MockHorizonProvider());
/// // Optionally restore from disk:
/// cached.loadFromDiskJson(storedJson);
/// // Use like any HorizonProvider:
/// final profile = await cached.getHorizon(latitude: 37.77, longitude: -122.42);
/// // Optionally persist:
/// final json = cached.saveToDiskJson();
/// ```
class CachedHorizonProvider implements HorizonProvider {
  /// The wrapped provider to delegate to on cache miss.
  final HorizonProvider delegate;

  /// In-memory cache keyed by rounded lat/lng string.
  final Map<String, HorizonProfile> _memoryCache = {};

  /// Creates a [CachedHorizonProvider] wrapping the given [delegate].
  CachedHorizonProvider({required this.delegate});

  /// Builds a cache key from lat/lng rounded to 3 decimal places.
  ///
  /// 3 decimal places gives ~111m resolution at the equator, meaning
  /// any two positions within ~111m will share the same cache entry.
  /// This matches the requirement for ~100m GPS debounce threshold.
  static String _cacheKey(double latitude, double longitude) {
    final lat = latitude.toStringAsFixed(3);
    final lng = longitude.toStringAsFixed(3);
    return '${lat}_$lng';
  }

  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) async {
    final key = _cacheKey(latitude, longitude);

    // Check memory cache first
    final cached = _memoryCache[key];
    if (cached != null) {
      return cached;
    }

    // Cache miss: delegate to wrapped provider
    final profile = await delegate.getHorizon(
      latitude: latitude,
      longitude: longitude,
    );

    // Store in memory cache
    _memoryCache[key] = profile;

    return profile;
  }

  /// Serializes the entire memory cache to a JSON string for disk persistence.
  ///
  /// Each entry is keyed by the cache key (rounded lat/lng) and the value
  /// is the HorizonProfile's JSON representation (via Freezed's toJson).
  String saveToDiskJson() {
    final map = <String, dynamic>{};
    for (final entry in _memoryCache.entries) {
      map[entry.key] = entry.value.toJson();
    }
    return jsonEncode(map);
  }

  /// Restores the memory cache from a previously saved JSON string.
  ///
  /// If the JSON is invalid or cannot be parsed, the operation is silently
  /// skipped (the cache remains empty or unchanged). This prevents crashes
  /// from corrupt persisted data.
  void loadFromDiskJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        try {
          final profileJson = entry.value as Map<String, dynamic>;
          final profile = HorizonProfile.fromJson(profileJson);
          _memoryCache[entry.key] = profile;
        } catch (_) {
          // Skip invalid entries
        }
      }
    } catch (_) {
      // Invalid JSON -- silently ignore
    }
  }
}
