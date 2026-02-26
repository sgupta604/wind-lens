/// Converts a compass bearing in degrees to a 16-point cardinal direction.
///
/// The 16-point compass rose includes: N, NNE, NE, ENE, E, ESE, SE, SSE,
/// S, SSW, SW, WSW, W, WNW, NW, NNW.
///
/// Handles negative and overflow degrees via modulo normalization.
///
/// Example:
/// ```dart
/// degreesToCardinal(0);    // "N"
/// degreesToCardinal(90);   // "E"
/// degreesToCardinal(202);  // "SSW"
/// degreesToCardinal(-10);  // "N" (wraps around)
/// degreesToCardinal(361);  // "N" (wraps around)
/// ```
String degreesToCardinal(double degrees) {
  const directions = [
    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
  ];
  final index = ((degrees % 360 + 360) % 360 / 22.5).round() % 16;
  return directions[index];
}
