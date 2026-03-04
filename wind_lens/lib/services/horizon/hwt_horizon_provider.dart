import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/models/horizon_profile.dart';
import '../../core/services/horizon_provider.dart';
import 'hwt_api_constants.dart';

/// Fetches real terrain horizon profiles from the HeyWhatsThat API.
///
/// Implements the 3-step API flow:
/// 1. Submit a panorama computation request ([_submitPanorama])
/// 2. Poll until the computation is complete ([_waitForCompletion])
/// 3. Fetch and parse the result ([_fetchProfile])
///
/// On any failure (network, timeout, parse error), returns
/// [HorizonProfile.flat] as a graceful fallback. Never throws to the caller.
///
/// Constructor accepts an optional [http.Client] for testability (same
/// pattern as [WindApiClient]). Tests inject a [MockClient] from
/// `http/testing.dart`.
///
/// The polling delay is controlled by [pollInterval] (default 10 seconds).
/// Tests pass [Duration.zero] for instant polling.
class HwtHorizonProvider implements HorizonProvider {
  final http.Client _client;
  final Duration _pollInterval;
  final Duration _timeout;

  /// Creates a [HwtHorizonProvider].
  ///
  /// [client]: HTTP client for making requests. If null, creates a default
  /// [http.Client]. The caller should call [dispose] to close it.
  ///
  /// [pollInterval]: Delay between poll requests. Default is 10 seconds.
  /// Tests should pass [Duration.zero] to avoid real delays.
  ///
  /// [timeout]: Maximum time to wait for panorama computation. Default is
  /// 5 minutes.
  HwtHorizonProvider({
    http.Client? client,
    Duration pollInterval = const Duration(seconds: 10),
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _pollInterval = pollInterval,
        _timeout = timeout ?? HwtApiConstants.timeout;

  @override
  Future<HorizonProfile> getHorizon({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final id = await _submitPanorama(latitude, longitude);
      await _waitForCompletion(id);
      return await _fetchProfile(id, latitude, longitude);
    } catch (_) {
      // Any failure -> flat horizon fallback, never crash.
      return HorizonProfile.flat(latitude, longitude);
    }
  }

  /// Step 1: Submit a panorama computation request.
  ///
  /// Sends a GET request to `query.cgi` with lat/lon/elevation parameters.
  /// Parses the panorama ID from the **first** space-delimited token in
  /// the response body.
  ///
  /// Response format: `PANORAMA_ID queued lat lon ...`
  ///
  /// Throws on non-200 status or empty/invalid response.
  Future<String> _submitPanorama(double lat, double lng) async {
    final uri = Uri.parse(
      '${HwtApiConstants.baseUrl}${HwtApiConstants.submitPath}'
      '?lat=$lat&lon=$lng'
      '&elev=${HwtApiConstants.elevation}'
      '&elev_is_absolute=${HwtApiConstants.elevIsAbsolute}'
      '&name=${HwtApiConstants.name}'
      '&public=${HwtApiConstants.isPublic}'
      '&return_data=${HwtApiConstants.returnData}',
    );

    final response = await _client.get(uri).timeout(HwtApiConstants.httpTimeout);

    if (response.statusCode != 200) {
      throw Exception('HWT submit failed: HTTP ${response.statusCode}');
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw Exception('HWT submit returned empty response');
    }

    // Panorama ID is the FIRST token (corrected from spec which said second).
    final id = body.split(' ')[0];
    if (id.isEmpty) {
      throw Exception('HWT returned empty panorama ID');
    }

    return id;
  }

  /// Step 2: Poll until panorama computation is complete.
  ///
  /// Polls `results/{id}/data` at [_pollInterval] intervals until the
  /// response body starts with `ok`. Other responses (e.g. starting with
  /// `running`) mean computation is still in progress.
  ///
  /// Throws [TimeoutException] if [_timeout] elapses before completion.
  /// Throws on non-200 HTTP status (e.g. 404 for invalid panorama ID).
  Future<void> _waitForCompletion(String id) async {
    final deadline = DateTime.now().add(_timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);

      final uri = Uri.parse(
        '${HwtApiConstants.baseUrl}${HwtApiConstants.pollPath(id)}',
      );

      final response =
          await _client.get(uri).timeout(HwtApiConstants.httpTimeout);

      if (response.statusCode != 200) {
        throw Exception('HWT poll failed: HTTP ${response.statusCode}');
      }

      if (response.body.trim().startsWith('ok')) {
        return;
      }
    }

    throw TimeoutException(
      'HWT panorama timed out after ${_timeout.inSeconds} seconds',
    );
  }

  /// Step 3: Fetch and parse the computed panorama result.
  ///
  /// Fetches `result.json?id={id}` and parses:
  /// - `limits` array (360 entries): each entry is `[lat, lon, elevation_angle]`
  /// - `declination`: magnetic declination in degrees
  ///
  /// Guards against empty response body (HTTP 200 with empty body indicates
  /// an invalid panorama ID, per API behavior).
  ///
  /// Returns a [HorizonProfile] populated with all parsed data.
  Future<HorizonProfile> _fetchProfile(
    String id,
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse(
      '${HwtApiConstants.baseUrl}${HwtApiConstants.resultPath}?id=$id',
    );

    final response =
        await _client.get(uri).timeout(HwtApiConstants.httpTimeout);

    if (response.statusCode != 200) {
      throw Exception('HWT result fetch failed: HTTP ${response.statusCode}');
    }

    // Guard: invalid panorama IDs return HTTP 200 with empty body
    // (with X-App-Status: 460 header). Must check before jsonDecode.
    if (response.body.isEmpty) {
      throw Exception('HWT result returned empty body (invalid panorama ID)');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final limits = json['limits'] as List<dynamic>;

    final angles = <double, double>{};
    for (int i = 0; i < limits.length; i++) {
      final entry = limits[i] as List<dynamic>;
      angles[i.toDouble()] = (entry[2] as num).toDouble();
    }

    final declination = (json['declination'] as num?)?.toDouble() ?? 0.0;

    return HorizonProfile(
      latitude: lat,
      longitude: lng,
      elevationAngles: angles,
      fetchedAt: DateTime.now(),
      declination: declination,
      panoramaId: id,
    );
  }

  /// Closes the underlying HTTP client.
  ///
  /// Should be called when the provider is no longer needed (e.g., via
  /// `ref.onDispose()` in the Riverpod provider).
  void dispose() {
    _client.close();
  }
}
