/// View modes for particle rendering in the wind visualization.
///
/// The app supports two rendering styles:
/// - [dots]: Current behavior - short line segments (sprinkles/dots)
/// - [streamlines]: Flowing wind streamlines with trailing paths
///
/// Example:
/// ```dart
/// final mode = ViewMode.dots;
/// print(mode.displayName); // "Dots"
/// final toggled = mode.toggle(); // ViewMode.streamlines
/// ```
enum ViewMode {
  /// Current behavior - short line segments (sprinkles/dots).
  ///
  /// Renders particles as small glowing dots with short trails.
  /// More efficient rendering, suitable for all devices.
  dots,

  /// Flowing wind streamlines with trailing paths.
  ///
  /// Renders particles with longer curved trails showing wind flow.
  /// Creates a Windy.com-style visualization effect.
  /// May use fewer particles for performance.
  streamlines,
}

/// Extension providing additional properties and methods for [ViewMode].
extension ViewModeExtension on ViewMode {
  /// Human-readable display name for the view mode.
  ///
  /// - dots: "Dots"
  /// - streamlines: "Streamlines"
  String get displayName => switch (this) {
        ViewMode.dots => 'Dots',
        ViewMode.streamlines => 'Streamlines',
      };

  /// Toggles between view modes.
  ///
  /// Returns [ViewMode.streamlines] if current mode is [dots],
  /// and [ViewMode.dots] if current mode is [streamlines].
  ViewMode toggle() => switch (this) {
        ViewMode.dots => ViewMode.streamlines,
        ViewMode.streamlines => ViewMode.dots,
      };

  /// The default view mode for the app.
  ///
  /// Returns [ViewMode.dots] to maintain backward compatibility.
  static ViewMode get defaultMode => ViewMode.dots;
}
