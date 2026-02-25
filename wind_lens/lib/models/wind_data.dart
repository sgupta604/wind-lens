// Backward compatibility -- re-export Freezed WindData from core/models.
//
// All consumers that import 'package:wind_lens/models/wind_data.dart'
// will now get the Freezed WindData with AltitudeLevel altitude field.
//
// The old WindData class (with double altitude) has been replaced.
// Key differences:
// - altitude is now AltitudeLevel enum (was double)
// - gustSpeed field added (defaults to 0.0)
// - Has Freezed equality, copyWith, and JSON serialization
// - WindData.zero() returns AltitudeLevel.surface (was altitude: 0)
export '../core/models/wind_data.dart';
