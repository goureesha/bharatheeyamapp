# Pre-calculate Planets Data for 200 Years

## Problem
The Planets screen lags when opened because it calculates transit, vakri, and asta data on-the-fly using Swiss Ephemeris (FFI). Each year requires ~365 ephemeris calculations × 9 planets = ~3,285 calculations. Switching years causes another loading delay.

## Proposed Approach: In-Memory Cache + Background Pre-computation

> [!IMPORTANT]
> Pre-computing 200 years of data and bundling it as a static JSON asset would add **~5-10 MB** to the app size and require a build-time script. Instead, I recommend a **smarter caching approach** that gives instant results after first load.

### Strategy

1. **LRU Memory Cache** — Keep the last 5 years of computed data in memory
2. **Disk Cache** — Save each year's computed data as a JSON file so it loads instantly on next app open
3. **Background Pre-fetch** — When user views year X, pre-compute X-1 and X+1 in the background
4. **Compute Isolate** — Move the heavy calculation to a Dart `Isolate` so UI never freezes

### Why this is better than bundling 200 years:
- No extra app size (data is computed once, cached locally)
- No build-time script needed
- Data is always accurate (computed from ephemeris, not stale)
- Adjacent years pre-fetched = instant navigation

## Open Questions

> [!IMPORTANT]
> Do you want the full 200-year pre-computation (generating a JSON asset at build time), or is the **cache + background pre-fetch** approach acceptable? The cache approach means first-time load for a year takes ~1-2 seconds, but every subsequent load is instant.

## Proposed Changes

### Transit Calculator Cache

#### [NEW] [transit_cache.dart](file:///d:/bharatheeyamapp%20sample/lib/core/transit_cache.dart)
- LRU in-memory cache (5 years)
- Disk cache using JSON files in app's documents directory
- `getYear(year)` → returns cached data instantly or computes + caches
- `prefetch(year)` → background computation of adjacent years

---

#### [MODIFY] [transit_calculator.dart](file:///d:/bharatheeyamapp%20sample/lib/core/transit_calculator.dart)
- Move `calculateAnnualEvents` to run in a Dart `Isolate` for true parallelism
- Add serialization (toJson/fromJson) to `TransitData`, `TransitEvent`, `VakriPeriod`, `AstaPeriod`

---

#### [MODIFY] [planets_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/planets_screen.dart)
- Use `TransitCache.getYear()` instead of direct `TransitCalculator.calculateAnnualEvents()`
- On year change, trigger `prefetch` for adjacent years
- Show cached data instantly, no spinner for cached years

## Verification Plan

### Manual Verification
- Open planets screen → first load shows spinner briefly
- Navigate to next/previous year → should be instant (pre-fetched)
- Close and reopen app → same year loads instantly from disk cache
- Verify transit/vakri/asta data matches the current non-cached version
