/// API configuration constants for OGC EDR wind data services.
///
/// Centralizes all API URLs, keys, parameter names, and timeout values
/// used by [WindApiClient] for both Shyft (primary) and Folkweather
/// (fallback) wind data APIs.
///
/// Usage:
/// ```dart
/// final url = '${WindApiConstants.shyftBaseUrl}/${WindApiConstants.shyftIsobaricCollection}/position';
/// ```
class WindApiConstants {
  // ─── Shyft (Primary API) ───────────────────────────────────

  /// Base URL for Shyft OGC EDR collections.
  static const shyftBaseUrl = 'https://ogc.shyftwx.com/ogc/edr/collections';

  /// Shyft API key (query parameter authentication).
  static const shyftApiKey = 'owp_BARNLCP72sszCKXxNp6OCPEhdvmklVDt';

  /// Shyft collection for isobaric (pressure level) wind data.
  /// Available levels: 850, 700, 500, 300, 200, 100, 70, 20, 10 hPa.
  /// WARNING: 1000 hPa returns Internal Server Error -- do NOT use.
  static const shyftIsobaricCollection = 'GFS_isobaric';

  /// Shyft collection for surface (10m above ground) wind data.
  /// No z parameter needed -- always returns 10m AGL data.
  static const shyftSurfaceCollection = 'GFS_height-above-ground_10';

  /// Shyft parameter name for U (eastward) wind component.
  static const shyftUParam = 'u-component-of-wind';

  /// Shyft parameter name for V (northward) wind component.
  static const shyftVParam = 'v-component-of-wind';

  /// Format for Shyft position queries (returns CoverageCollection).
  static const shyftPositionFormat = 'CoverageJSON';

  /// Format for Shyft area queries (returns MultiPointSeries).
  static const shyftAreaFormat = 'CoverageJSON_MultiPointSeries';

  // ─── Folkweather (Fallback API) ────────────────────────────

  /// Base URL for Folkweather OGC EDR collections.
  static const folkBaseUrl = 'https://folkweather.com/edr/collections';

  /// Folkweather HRRR isobaric collection (3km resolution).
  /// Available levels: 1000, 925, 850, 700, 500, 300, 250 hPa.
  static const folkHrrrIsobaricCollection = 'hrrr-isobaric';

  /// Folkweather GFS isobaric collection (25km resolution).
  /// Available levels: 10, 20, 70, 100, 200, 300, 500, 700, 1000 hPa.
  /// WARNING: Does NOT have 850 hPa -- use HRRR for that.
  static const folkGfsIsobaricCollection = 'gfs-isobaric-latest';

  /// Folkweather surface (height above ground level) collection.
  static const folkSurfaceCollection = 'hrrr-height-agl';

  /// Folkweather parameter name for U (eastward) wind component.
  static const folkUParam = 'UGRD';

  /// Folkweather parameter name for V (northward) wind component.
  static const folkVParam = 'VGRD';

  /// Format for Folkweather queries (all query types use CoverageJSON).
  static const folkFormat = 'CoverageJSON';

  // ─── Shared ────────────────────────────────────────────────

  /// HTTP request timeout. Generous for cellular networks.
  static const timeout = Duration(seconds: 12);

  /// Folkweather pressure levels available on HRRR (not on GFS).
  /// Route these levels to [folkHrrrIsobaricCollection].
  /// All other levels route to [folkGfsIsobaricCollection].
  static const folkHrrrLevels = {250, 300, 500, 700, 850, 925, 1000};

  /// Private constructor to prevent instantiation.
  WindApiConstants._();
}
