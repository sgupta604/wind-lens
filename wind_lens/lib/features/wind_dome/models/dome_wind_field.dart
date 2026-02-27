import '../../../services/wind/wind_models.dart';
import 'dome_constants.dart';
import 'dome_wind_layer.dart';

/// One hour's 3D wind field for the dome visualization.
///
/// Contains multiple [DomeWindLayer]s sorted by altitude ascending.
/// The [sample] method performs vertical interpolation of u/v components
/// to produce smooth wind at any height within the dome.
///
/// Plain Dart class, NOT Freezed -- [sample] is a hot-path method called
/// per-particle per-frame (up to 2000x/frame at 60 FPS).
class DomeWindField {
  /// The forecast time this field represents.
  final DateTime validTime;

  /// Wind layers sorted by altitude ascending.
  /// Typically 3 entries: surface (10m), 850hPa (~1500m), 700hPa (~3000m).
  final List<DomeWindLayer> layers;

  /// Creates a wind field for a specific time with the given layers.
  DomeWindField({
    required this.validTime,
    required this.layers,
  });

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
  /// [x] and [z] are unused in MVP (uniform horizontal wind within dome).
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
      return WindVector(u: layers[0].u, v: layers[0].v);
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
      return WindVector(u: layers[lo].u, v: layers[lo].v);
    }

    final range =
        layers[hi].altitudeMeters - layers[lo].altitudeMeters;
    if (range <= 0) {
      return WindVector(u: layers[lo].u, v: layers[lo].v);
    }

    // Linear interpolation of u/v components
    final frac =
        (clampedAlt - layers[lo].altitudeMeters) / range;

    return WindVector(
      u: layers[lo].u * (1 - frac) + layers[hi].u * frac,
      v: layers[lo].v * (1 - frac) + layers[hi].v * frac,
    );
  }

  @override
  String toString() =>
      'DomeWindField(time=$validTime, layers=${layers.length})';
}
