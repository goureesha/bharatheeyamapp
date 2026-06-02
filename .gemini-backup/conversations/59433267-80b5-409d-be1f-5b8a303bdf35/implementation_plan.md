# Pre-compute 10 Years of Panchanga Data on First Launch

## Problem
Panchang screen recalculates heavy ephemeris data for each day on-the-fly, causing lag when switching months. No events/festivals needed — just core PanchangData.

## Proposed Changes

### 1. [MODIFY] [calculator.dart](file:///d:/bharatheeyamapp%20sample/lib/core/calculator.dart)
- Add `toJson()` and `PanchangData.fromJson()` to serialize/deserialize the ~40 fields

### 2. [NEW] [panchanga_cache_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/panchanga_cache_service.dart)
- `precompute()` — compute PanchangData for 10 years, save to SharedPreferences by year-month
- `getPanchang(DateTime)` — return cached PanchangData instantly
- `isReady` flag + progress callback for UI
- Uses `compute` isolate if possible for background processing

### 3. [MODIFY] [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart)
- On first launch (no cache), show a loading dialog: "ಲೆಕ್ಕಾಚಾರ ಮಾಡಲಾಗುತ್ತಿದೆ... / Calculating..."
- Show progress (e.g., "2026... 2027... 2028...")
- Subsequent launches skip dialog (data already cached)

### 4. [MODIFY] [panchanga_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/panchanga_screen.dart)
- `_calcPanchang()` → check cache first, if hit → instant, if miss → live compute
- Remove event calculation from panchanga flow

## Open Questions

> [!IMPORTANT]  
> **Year range:** Current year ± 5 years, or current year to +10 years?

> [!NOTE]
> ~3,650 days × ~50ms ≈ 3 min one-time computation on phone. Acceptable?

## Verification
- Clear app data → loading dialog appears → completes
- Open panchang → swipe months → no lag/spinner
