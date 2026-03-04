import 'dart:math';

import '../../../services/wind/wind_models.dart';
import 'dome_constants.dart';
import 'dome_wind_layer.dart';

/// One hour's 3D wind field for the dome visualization.
///
/// Contains multiple [DomeWindLayer]s sorted by altitude ascending.
/// The [sample] method performs vertical interpolation of u/v components
/// to produce smooth wind at any height within the dome.
///
/// When [centerLat] and [centerLng] are set and layers carry [WindField]
/// grids, [sample] also performs bilinear spatial interpolation using
/// x/z render-space coordinates. Otherwise x/z are ignored (backward
/// compatible with point-data fields).
///
/// Plain Dart class, NOT Freezed -- [sample] is a hot-path method called
/// per-particle per-frame (up to 2000x/frame at 60 FPS).
class DomeWindField {
  /// The forecast time this field represents.
  final DateTime validTime;

  /// Wind layers sorted by altitude ascending.
  /// Typically 3 entries: surface (10m), 850hPa (~1500m), 700hPa (~3000m).
  final List<DomeWindLayer> layers;

  /// Latitude of the dome center in degrees, or null for point-data fields.
  ///
  /// When set (together with [centerLng]), enables render-space to geographic
  /// coordinate conversion for spatial grid interpolation in [sample].
  final double? centerLat;

  /// Longitude of the dome center in degrees, or null for point-data fields.
  final double? centerLng;

  /// Meters per render unit for this field.
  ///
  /// Used to convert render-space x/z offsets to geographic offsets for
  /// grid interpolation. Defaults to [DomeConstants.metersPerRenderUnit].
  final double metersPerRenderUnit;

  /// Creates a wind field for a specific time with the given layers.
  DomeWindField({
    required this.validTime,
    required this.layers,
    this.centerLat,
    this.centerLng,
    double? metersPerRenderUnit,
  }) : metersPerRenderUnit =
            metersPerRenderUnit ?? DomeConstants.metersPerRenderUnit;

  /// Creates a zero-wind field (graceful degradation when API fails).
  factory DomeWindField.zero({DateTime? validTime}) {
    return DomeWindField(
      validTime: validTime ?? DateTime.now(),
      layers: [
        const DomeWindLayer(altitudeMeters: 10, u: 0, v: 0),
        const DomeWindLayer(altitudeMeters: 1500, u: 0, v: 0),
        const DomeWindLayer(altitudeMeters: 3000, u: 0, v: 0),
      ],
    );
  }

  /// Samples the wind field at a render-space position.
  ///
  /// [x] and [z] are used for spatial grid interpolation when grid data is
  /// available and [centerLat]/[centerLng] are set. Otherwise they are ignored
  /// (backward compatible with point-data fields).
  /// [y] is the render-space height [0, DOME_H_RENDER].
  ///
  /// Performs vertical interpolation of u/v components between layers.
  /// Returns [WindVector.zero] if layers is empty.
  ///
  /// IMPORTANT: Interpolates u/v components, NOT speed/direction.
  /// Lerping direction causes wrap-around artifacts at 0/360 boundary.
  WindVector sample(double x, double y, double z) {
    if (layers.isEmpty) return WindVector.zero;
    if (layers.length == 1) {
      return _sampleLayer(layers[0], x, z);
    }

    // Convert render-space y to real-world altitude in meters
    final altitudeMeters =
        (y / DomeConstants.domeH) * DomeConstants.maxAltitudeMeters;

    // Clamp to layer range
    final clampedAlt = altitudeMeters.clamp(
      layers.first.altitudeMeters,
      layers.last.altitudeMeters,
    );

    // Find bounding layers
    int lo = 0;
    for (int i = 0; i < layers.length - 1; i++) {
      if (layers[i + 1].altitudeMeters >= clampedAlt) {
        lo = i;
        break;
      }
      lo = i;
    }
    final hi = (lo + 1).clamp(0, layers.length - 1);

    // Handle exact match or same-altitude layers
    if (lo == hi) {
      return _sampleLayer(layers[lo], x, z);
    }

    final range =
        layers[hi].altitudeMeters - layers[lo].altitudeMeters;
    if (range <= 0) {
      return _sampleLayer(layers[lo], x, z);
    }

    // Linear interpolation of u/v components between bounding layers
    final frac =
        (clampedAlt - layers[lo].altitudeMeters) / range;

    final loWind = _sampleLayer(layers[lo], x, z);
    final hiWind = _sampleLayer(layers[hi], x, z);

    return WindVector(
      u: loWind.u * (1 - frac) + hiWind.u * frac,
      v: loWind.v * (1 - frac) + hiWind.v * frac,
    );
  }

  /// Samples a single layer at horizontal position (x, z).
  ///
  /// If the layer has a [WindField] grid AND center coordinates are set,
  /// converts render-space (x, z) to geographic offsets and performs bilinear
  /// interpolation on the grid. Otherwise returns the scalar u/v values.
  ///
  /// This is a private method (not a lambda) to avoid allocation in the
  /// hot path. ~30-40 FLOPs per call when grid is present.
  WindVector _sampleLayer(DomeWindLayer layer, double x, double z) {
    final grid = layer.grid;
    if (grid == null || centerLat == null || centerLng == null) {
      return WindVector(u: layer.u, v: layer.v);
    }

    // Convert render-space to geographic offset
    // +x = east = +longitude, -z = north = +latitude
    final cosLat = cos(centerLat! * pi / 180);
    final offsetLng = x * metersPerRenderUnit / (111320 * cosLat);
    final offsetLat = -z * metersPerRenderUnit / 111320;

    return grid.interpolateAtCoord(
      centerLng! + offsetLng,
      centerLat! + offsetLat,
    );
  }

  @override
  String toString() =>
      'DomeWindField(time=$validTime, layers=${layers.length}, '
      'grid=${centerLat != null ? 'yes' : 'no'})';
}
