# P2B-006: OGC EDR Wind Data Service — Implementation Guide

> **Purpose:** This document contains everything needed to implement `OgcEdrWindDataSource implements WindDataSource` for Wind Lens. It was produced by live API exploration and testing on 2026-02-26. The companion file `wind_data_service.dart` contains a complete, tested Dart implementation ready to be adapted into the project's architecture.

---

## What This Feature Does

Replaces `MockWindDataSource` (which wraps `FakeWindService` with synthetic data) with a real wind data service that fetches U/V wind vectors from OGC EDR weather APIs. The app gets real wind at multiple altitudes for the user's GPS location, enabling the particle system to show actual atmospheric flow.

## Where It Plugs In

Per DECISIONS.md and CLAUDE.md, the wiring is a single swap in `service_providers.dart`:

```dart
// Before (mock):
final windDataSourceProvider = Provider<WindDataSource>((ref) {
  return MockWindDataSource();
});

// After (real, with cache):
final windDataSourceProvider = Provider<WindDataSource>((ref) {
  return CachedWindDataSource(
    delegate: OgcEdrWindDataSource(),
    ttl: const Duration(minutes: 10),
  );
});
```

`CachedWindDataSource` already exists and is tested (Phase 3b). It wraps any `WindDataSource` with a TTL-based memory cache. The only new code is `OgcEdrWindDataSource`.

## The WindDataSource Interface

From `lib/core/services/wind_data_source.dart`:

```dart
abstract class WindDataSource {
  Future<WindData> getWind(PositionData position, AltitudeLevel altitude);
  bool get isSimulated;
}
```

`OgcEdrWindDataSource.isSimulated` should return `false`.

## The WindData Model

From `lib/core/models/wind_data.dart`:

```dart
@freezed
class WindData with _$WindData {
  const factory WindData({
    required double uComponent,    // east/west (m/s), positive = eastward
    required double vComponent,    // north/south (m/s), positive = northward
    required AltitudeLevel altitude,
    required DateTime timestamp,
  }) = _WindData;
}
```

The APIs return U/V directly — no speed/direction conversion needed.

## AltitudeLevel → Pressure Level Mapping

From `lib/core/models/altitude_level.dart`:

| AltitudeLevel | Real Altitude | Pressure Level | Notes |
|---------------|---------------|----------------|-------|
| `surface`     | 10m AGL       | N/A (separate collection) | Uses `GFS_height-above-ground_10` on Shyft |
| `midLevel`    | ~1,500m       | 850 hPa        | Critical layer — Shyft has it, Folkweather only via HRRR |
| `jetStream`   | ~10,500m      | 250 hPa (or 300 hPa) | Use 300 hPa if 250 not available |

---

## API Architecture: Shyft Primary → Folkweather Fallback

### Why Two APIs

Neither API is perfect alone. Shyft requires an API key but has more reliable altitude coverage. Folkweather is free/no-auth but has quirks (0-360 longitude, GFS missing 850 hPa). Using both with fallback gives maximum reliability.

### API 1: Shyft EDR (Primary)

| Property | Value |
|----------|-------|
| Base URL | `https://ogc.shyftwx.com/ogc/edr/collections` |
| Auth | Query param: `apikey=owp_BARNLCP72sszCKXxNp6OCPEhdvmklVDt` |
| CORS | Returns proper `access-control-allow-origin` headers |
| Collections | `GFS_isobaric` (pressure levels), `GFS_height-above-ground_10` (surface) |
| U param | `u-component-of-wind` |
| V param | `v-component-of-wind` |
| Units | m/s |
| Available levels (isobaric) | 850, 700, 500, 300, 200, 100, 70, 20, 10 hPa |
| ⚠️ 1000 hPa | **Returns Internal Server Error** — do NOT use. Use surface collection instead. |
| Resolution | GFS 0.25° (~28km) |

### API 2: Folkweather EDR (Fallback)

| Property | Value |
|----------|-------|
| Base URL | `https://folkweather.com/edr/collections` |
| Auth | **None required** |
| CORS | `access-control-allow-origin: *` |
| Collections | `hrrr-isobaric` (3km!), `gfs-isobaric-latest` (25km), `hrrr-height-agl` (surface) |
| U param | `UGRD` |
| V param | `VGRD` |
| Units | m/s |
| HRRR levels | 1000, 925, **850**, 700, 500, 300, 250 hPa |
| GFS levels | 10, 20, 70, 100, 200, 300, 500, 700, 1000 hPa |
| ⚠️ GFS does NOT have 850 hPa | Route 850/925/1000 to `hrrr-isobaric`, everything else to `gfs-isobaric-latest` |
| ⚠️ Longitude format | **0–360**, not -180/180. Subtract 360 for western hemisphere. |

---

## Critical API Gotchas (Discovered by Testing)

These are the things that will bite you if you don't know about them:

### 1. Shyft area queries require `f=CoverageJSON_MultiPointSeries`

**NOT** `f=CoverageJSON`. Plain `CoverageJSON` returns HTTP 400:

```
Unsupported output format 'CoverageJSON'. 
Supported: 'CoverageJSON_MultiPointSeries', 'CoverageJSON_Grid', 'GRIB2', ...
```

The `CoverageJSON_Grid` format works too but has a different structure (separate coverages per param, no coordinate arrays in each coverage). `CoverageJSON_MultiPointSeries` is easier to parse because it returns a single Coverage with a `composite` axis.

Shyft **position** queries DO accept `f=CoverageJSON` (they return a CoverageCollection with separate coverages per param per timestep). But for the area query, use `CoverageJSON_MultiPointSeries`.

### 2. Shyft MultiPointSeries uses a `composite` axis

The response does NOT have separate `x` and `y` axes. Instead:

```json
{
  "type": "Coverage",
  "domain": {
    "axes": {
      "composite": {
        "values": [
          [-122.75, 37.5, 850.0],
          [-122.5, 37.5, 850.0],
          [-122.25, 37.5, 850.0],
          ...
        ]
      },
      "t": { "values": ["2026-02-25T18:00:00Z"] }
    }
  },
  "ranges": {
    "u-component-of-wind": { "values": [3.38, 3.87, 3.87, ...] },
    "v-component-of-wind": { "values": [-0.28, 1.01, 1.65, ...] }
  }
}
```

Each composite value is `[longitude, latitude, pressure_level]`. The values array is in scan order but NOT necessarily in grid order. You must:

1. Extract unique sorted x values and unique sorted y values from the composites
2. Build a lookup: for each composite tuple, find its (row, col) in the sorted grid
3. Place U/V values at `row * width + col` in the output arrays

### 3. Shyft 1000 hPa returns Internal Server Error

Do not request `z=1000` on `GFS_isobaric`. For surface wind, use the separate collection `GFS_height-above-ground_10` (no `z` parameter needed — it's always 10m above ground).

### 4. Folkweather longitudes are 0–360

A response for San Francisco will have x values like `[237.25, 237.5, 237.75, 238.0]` instead of `[-122.75, -122.5, ...]`. Convert with: `x > 180 ? x - 360 : x`.

### 5. Folkweather GFS does not have 850 hPa

Requesting `z=850` on `gfs-isobaric-latest` returns:

```json
{"status": 400, "detail": "Z coordinate 850 is outside the collection's vertical extent. Must be one of: [10.0, 20.0, 70.0, 100.0, 200.0, 300.0, 500.0, 700.0, 1000.0]"}
```

Route 850 (and 925, 1000) to `hrrr-isobaric` which has those levels at 3km resolution. Route 700, 500, 300, etc. to `gfs-isobaric-latest`.

### 6. Folkweather area query returns a single Coverage (simple)

Much simpler than Shyft — standard `x`/`y` axes:

```json
{
  "type": "Coverage",
  "domain": {
    "axes": {
      "x": { "values": [237.25, 237.5, 237.75, 238.0] },
      "y": { "values": [37.5, 37.75, 38.0] },
      "z": { "values": [850.0] }
    }
  },
  "ranges": {
    "UGRD": { "values": [2.5, 2.3, 1.8, ...] },
    "VGRD": { "values": [-0.8, -1.0, -0.4, ...] }
  }
}
```

Values are row-major (y outer, x inner). Direct read into the grid.

### 7. Folkweather HRRR may return nulls for grid cells outside coverage

HRRR covers CONUS only. If the query bbox extends beyond HRRR's domain, some cells will be null. Replace nulls with 0.0.

### 8. Shyft returns forecast time series if you don't pin `datetime`

Without `&datetime=...`, the area query returns data for ALL forecast hours (180+), which means hundreds of coverages. Always include `&datetime=<nearest_hour_utc>` to get a single timestep.

---

## Query Construction

### Area Query (Recommended)

One HTTP request returns a grid of wind vectors. For a 40km radius around the user:

```
dLat = radiusKm / 111.32
dLng = radiusKm / (111.32 * cos(lat * π / 180))
bbox = [lng - dLng, lat - dLat, lng + dLng, lat + dLat]
polygon = "POLYGON((minLng minLat, minLng maxLat, maxLng maxLat, maxLng minLat, minLng minLat))"
```

**Shyft isobaric:**
```
GET {base}/GFS_isobaric/area
  ?coords={url_encode(polygon)}
  &parameter-name=u-component-of-wind,v-component-of-wind
  &z={level}
  &datetime={nearest_hour_utc}
  &apikey={key}
  &f=CoverageJSON_MultiPointSeries
```

**Shyft surface:**
```
GET {base}/GFS_height-above-ground_10/area
  ?coords={url_encode(polygon)}
  &parameter-name=u-component-of-wind,v-component-of-wind
  &apikey={key}
  &f=CoverageJSON_MultiPointSeries
```
(No `z` param, no `datetime` needed for surface)

**Folkweather isobaric:**
```
GET {base}/{collection}/area
  ?coords={url_encode(polygon)}
  &parameter-name=UGRD,VGRD
  &z={level}
  &f=CoverageJSON
```
Where collection = `hrrr-isobaric` for 850/925/1000, `gfs-isobaric-latest` for others.

**Folkweather surface:**
```
GET {base}/hrrr-height-agl/area
  ?coords={url_encode(polygon)}
  &parameter-name=UGRD,VGRD
  &z=10
  &f=CoverageJSON
```

### Grid Size You'll Get

| API | Resolution | Grid for 40km radius bbox |
|-----|-----------|--------------------------|
| Shyft GFS | 0.25° (~28km) | 4×3 = 12 points |
| Folkweather GFS | 0.25° (~28km) | 4×3 = 12 points |
| Folkweather HRRR | 3km | ~27×27 = ~729 points |

For Wind Lens, the GFS 4×3 grid is fine — bilinear interpolation smooths it. The HRRR grid is great if available but much more data to transfer.

---

## Mapping to WindDataSource Interface

The interface expects a single `WindData` point, not a grid. Two approaches:

### Approach A: Center-point query (Simple)

Use a position query instead of area query. Returns one U/V pair at the user's exact location. Simple, fast, one HTTP call per altitude.

```dart
@override
Future<WindData> getWind(PositionData position, AltitudeLevel altitude) async {
  final (u, v) = await _fetchPointWind(position.latitude, position.longitude, altitude);
  return WindData(
    uComponent: u,
    vComponent: v,
    altitude: altitude,
    timestamp: DateTime.now(),
  );
}
```

This is the minimal viable implementation.

### Approach B: Grid query (Future — for WindField integration)

Fetch an area grid, build a `WindField` with interpolation. This doesn't map to the current `WindDataSource` interface (which returns a single `WindData`), but would be needed for the full particle system with spatial variation.

**Recommendation:** Start with Approach A to get real data flowing through the existing architecture. The `WindField` + grid approach is a separate enhancement that would require changes to how `ParticleOverlay` consumes wind data (it currently gets a single `WindData` per altitude level, not a spatial grid).

The companion `wind_data_service.dart` file includes both approaches — the `fetchWindGrid()` with `WindField` for future use, and the simpler point-query path that maps directly to the interface.

---

## AltitudeLevel → API Mapping

```dart
(String collection, int? zLevel) _mapAltitude(AltitudeLevel altitude) {
  switch (altitude) {
    case AltitudeLevel.surface:
      // Shyft: GFS_height-above-ground_10, no z
      // Folk: hrrr-height-agl, z=10
      return ('surface', null);
    case AltitudeLevel.midLevel:
      // 850 hPa (~1,500m)
      return ('isobaric', 850);
    case AltitudeLevel.jetStream:
      // 300 hPa (~9,000m) — closest available to 250 hPa on both APIs
      return ('isobaric', 300);
  }
}
```

Note: The current `AltitudeLevel` enum has 3 values. If more levels are added later, the pressure level mapping should be extended accordingly.

---

## Implementation Checklist

1. **Create `lib/services/wind/ogc_edr_wind_source.dart`**
   - `class OgcEdrWindDataSource implements WindDataSource`
   - `isSimulated` returns `false`
   - `getWind()` tries Shyft point query first, falls back to Folkweather
   - Handle the AltitudeLevel → collection/z mapping
   - Parse both response formats (Shyft CoverageJSON position, Folkweather CoverageJSON position)
   - 12-second timeout on HTTP calls

2. **Wire into `service_providers.dart`**
   - Wrap in existing `CachedWindDataSource` (already built and tested)
   - Consider: should `isSimulated` check be available to UI? (e.g., show data source indicator)

3. **Tests**
   - Mock HTTP responses for both Shyft and Folkweather formats
   - Test fallback: Shyft 500 → Folkweather succeeds
   - Test both failure: throws meaningful error
   - Test AltitudeLevel mapping (surface → correct collection, midLevel → 850, jetStream → 300)
   - Test Folkweather longitude normalization (0-360 → -180/180)
   - Test null handling in Folkweather HRRR responses

4. **Integration considerations**
   - `PositionData.altitude` is now wired (Phase 3a) — available if needed for observer altitude calculations
   - `CachedWindDataSource` uses 2-decimal lat/lng key (~1.1km) + altitude name
   - `stablePositionProvider` debounces GPS at 100m — wind won't refetch on jitter

---

## Live Test Data (2026-02-26, San Francisco)

These are real values fetched during development. Useful for sanity-checking your implementation:

### 850 hPa (Shyft GFS, 4×3 grid)
```
Grid: [-122.75, -122.5, -122.25, -122.0] × [37.5, 37.75, 38.0]
U: [2.527, 2.377, 1.887, 1.027, 3.137, 3.057, 3.147, 2.907, 3.707, 3.827, 3.997, 4.237]
V: [-0.873, -1.043, -0.413, 0.447, -0.433, -0.433, -0.233, 0.697, -0.313, 0.047, 0.457, 0.577]
Center point: ~3.1 m/s, generally eastward with slight south component
```

### 500 hPa (Shyft GFS)
```
U: [30.129, 31.509, 32.129, 31.809, 24.039, 26.029, 27.469, 28.889, 20.319, 21.899, 23.429, 24.749]
V: [9.248, 8.528, 7.708, 6.798, 6.558, 6.218, 5.678, 4.978, 4.478, 4.358, 4.428, 4.318]
Center point: ~27 m/s, strong eastward jet stream flow
```

### Surface 10m AGL (Shyft GFS)
```
U: [2.069, 1.979, 1.589, 2.569, 3.289, 2.569, 2.079, 1.969, 2.509, 0.779, 1.279, 2.119]
V: [-2.847, -1.147, -1.767, -1.927, -3.077, -0.137, -1.237, -0.547, -1.627, 0.583, 0.813, -0.197]
Center point: ~2.6 m/s, light southeastward surface wind
```

Key observation: wind at 500 hPa is ~10x faster and in a completely different direction than surface wind. This is the depth effect that makes Wind Lens compelling.

---

## Shyft Position Query Response Format

For the simpler Approach A (single point), the Shyft position query returns:

```json
{
  "type": "CoverageCollection",
  "coverages": [
    {
      "type": "Coverage",
      "domain": {
        "axes": {
          "t": { "values": ["2026-02-25T18:00:00Z"] },
          "x": { "values": [-122.4194] },
          "y": { "values": [37.7749] },
          "z": { "values": [850.0] }
        }
      },
      "ranges": {
        "u-component-of-wind": {
          "values": [3.97]
        }
      }
    },
    {
      "type": "Coverage",
      "domain": { ... },
      "ranges": {
        "v-component-of-wind": {
          "values": [1.18]
        }
      }
    }
  ]
}
```

Note: U and V come in **separate coverages**. Iterate through `coverages` to find each parameter.

If `datetime` is omitted, you get 180+ coverages (one per forecast hour per parameter). Always include `&datetime=<nearest_hour>`.

## Folkweather Position Query Response Format

```json
{
  "type": "Coverage",
  "domain": {
    "axes": {
      "x": { "values": [237.5806] },
      "y": { "values": [37.7749] },
      "z": { "values": [850.0] }
    }
  },
  "ranges": {
    "UGRD": { "values": [1.65] },
    "VGRD": { "values": [-3.47] }
  }
}
```

Both U and V in the same Coverage. Simpler to parse. Remember to normalize longitude.

---

## Network and Error Considerations

- Both APIs are free-tier/open — no rate limit headers observed, but be conservative
- Shyft occasionally returns 500 errors (observed on 1000 hPa) — the fallback handles this
- Folkweather is behind Cloudflare — may get 429s under heavy use
- Both APIs respond in 200-800ms typically
- Use 12-second timeout (cellular networks can be slow)
- On both-APIs-fail: return `WindData.zero()` with the requested altitude rather than throwing — the app should degrade gracefully to zero-wind particles rather than crash or show an error screen

---

## API Key Note

The Shyft API key (`owp_BARNLCP72sszCKXxNp6OCPEhdvmklVDt`) was obtained during development. It should be:
- Stored as a build-time constant or environment variable, not hardcoded in source
- Rotated periodically (it's been shared in chat history)
- The key is a query parameter, not a header — works with simple GET requests
