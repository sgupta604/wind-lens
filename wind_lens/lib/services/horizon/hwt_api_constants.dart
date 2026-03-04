/// API configuration constants for the HeyWhatsThat terrain horizon service.
///
/// Centralizes all API URLs, query parameters, and timeout values used by
/// [HwtHorizonProvider] for fetching terrain horizon profiles.
///
/// The HeyWhatsThat API computes 360-degree panoramic horizon profiles from
/// SRTM terrain data. The 3-step flow is:
/// 1. Submit a panorama request via [submitPath]
/// 2. Poll [pollPath] until computation is complete
/// 3. Fetch the result from [resultPath]
///
/// Usage:
/// ```dart
/// final submitUrl = '${HwtApiConstants.baseUrl}${HwtApiConstants.submitPath}';
/// final pollUrl = '${HwtApiConstants.baseUrl}${HwtApiConstants.pollPath(id)}';
/// ```
class HwtApiConstants {
  // ─── URLs ───────────────────────────────────────────────────

  /// Base URL for the HeyWhatsThat API.
  static const baseUrl = 'https://www.heywhatsthat.com';

  /// Path for submitting a new panorama computation request.
  ///
  /// Response format: `PANORAMA_ID queued lat lon ...`
  /// The panorama ID is the **first** space-delimited token.
  static const submitPath = '/bin/query.cgi';

  /// Path for fetching the computed panorama result as JSON.
  ///
  /// Usage: `$baseUrl$resultPath?id=$panoramaId`
  static const resultPath = '/bin/result.json';

  /// Returns the poll path for a given panorama ID.
  ///
  /// Poll responses:
  /// - Not ready: body starts with `running`
  /// - Ready: body starts with `ok`
  /// - Invalid ID: HTTP 404
  static String pollPath(String id) => '/results/$id/data';

  // ─── Query Parameters ───────────────────────────────────────

  /// Observer elevation above ground in metres (phone held at eye level).
  static const elevation = '2';

  /// Whether [elevation] is absolute (above sea level) or relative to ground.
  /// `0` = relative to ground.
  static const elevIsAbsolute = '0';

  /// Name tag for the panorama request.
  static const name = 'windlens';

  /// Whether the panorama should be publicly listed. `0` = private.
  static const isPublic = '0';

  /// Whether to return data inline with the submit response. `1` = yes.
  static const returnData = '1';

  // ─── Timeouts ───────────────────────────────────────────────

  /// Interval between poll requests while waiting for panorama computation.
  ///
  /// HeyWhatsThat's own frontend uses 10-second intervals. Typical
  /// computation takes 5-15 seconds, so 2-3 polls are usually sufficient.
  static const pollInterval = Duration(seconds: 10);

  /// Maximum time to wait for panorama computation before giving up.
  ///
  /// If the panorama is not ready after this duration, the provider
  /// returns a flat horizon profile as a graceful fallback.
  static const timeout = Duration(minutes: 5);

  /// HTTP request timeout for individual API calls (submit, poll, result).
  ///
  /// Generous for cellular networks.
  static const httpTimeout = Duration(seconds: 15);

  /// Private constructor to prevent instantiation.
  HwtApiConstants._();
}
