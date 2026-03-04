# OGC EDR Cube Queries & Resolution Control

## Source
Notes from senior developer consultation (2026-03-04).

## Current State
- We already use `/area` queries with bounding box polygons for grid fetch (≥25km domes)
- Each pressure level is fetched as a separate `/area` call (3 parallel requests)
- We accept whatever grid resolution the API returns (GFS ~25km, HRRR ~3km)
- Dual-API fallback: Shyft (GFS) primary, Folkweather (HRRR) fallback

## Proposed Improvements

### 1. Specify x/y resolution in area queries
- OGC EDR supports `resolution-x` and `resolution-y` params
- Request specific grid density (e.g., 128x128) instead of accepting API default
- Would give much denser data, especially useful for HRRR at 3km resolution
- Need to verify Shyft/Folkweather support these params

### 2. Switch to /cube queries
- `/cube` can fetch multiple pressure levels AND time steps in a single request
- Reduces 3 parallel API calls to 1
- More efficient, potentially more consistent data across levels
- Cube supports time dimension natively
- Reference: https://ogcie.iblsoft.com/swagger-ui/?url=https%3a//ogcie.iblsoft.com/edr/api%3ff%3dJSON#/Collection%20Data/get_area_data_from_collection

### 3. Prioritize HRRR (3km) over GFS (25km)
- HRRR is much better resolution for dome visualization
- We already route some pressure levels to HRRR via Folkweather
- Could lean harder into HRRR for all dome sizes, not just fallback
- Especially valuable for domes under ~50km

### 4. Fix 25km dome dead zone
- 25km preset was changed to 35km as a stopgap because GFS bbox at 25km only captures 1-2 grid points, causing 48-72s timeout cascades
- With resolution control (128x128 grid) or HRRR-first, 25km could work with real spatial variation
- Could restore 25km preset once this feature is implemented

## Research Needed
- [ ] Check if Shyft supports `resolution-x`/`resolution-y` params
- [ ] Check if Folkweather supports `resolution-x`/`resolution-y` params
- [ ] Check if either API supports `/cube` endpoint
- [ ] Test 128x128 grid request and measure response time/size
- [ ] Evaluate HRRR-first strategy vs current GFS-first approach
- [ ] Test whether HRRR area queries work reliably at 25km bbox
