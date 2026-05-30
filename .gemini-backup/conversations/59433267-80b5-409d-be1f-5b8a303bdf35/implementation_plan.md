# Panchanga Filter / Search Feature

Add a new main section to the app that lets users search for dates matching specific panchanga criteria and displays full panchanga details for matching dates.

## User Review Required

> [!IMPORTANT]
> This feature involves iterating through a date range and computing panchanga for each day. A 1-year range means ~365 calculations. Each takes ~50-100ms, so a full year scan may take 20-40 seconds. We should limit the range to something reasonable (e.g., max 1 year) and show a progress indicator.

## Open Questions

> [!IMPORTANT]
> 1. Should the date range default to "today → 1 year from now" or should the user always pick from/to dates?
> 2. Should all filters be required, or can the user search with just one filter (e.g., only Tithi)?
> 3. Should the place (lat/lon) be taken from the app's current saved location, or should the user input a place?

## Proposed Changes

### Home Screen Navigation

#### [MODIFY] [home_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/home_screen.dart)
- Add a new `_Section` card: "ಪಂಚಾಂಗ ಶೋಧನೆ" / "Panchanga Search" with `Icons.search` icon
- Place it after Panchanga and before Taranukoola

---

### New Screen

#### [NEW] [panchanga_search_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/panchanga_search_screen.dart)

**Filter inputs (dropdowns):**
- **Chandra Masa** — optional, 12 options from `knChandraMasa` list
- **Soura Masa** — optional, 12 options from `knSouraMasa` list  
- **Paksha** — required, 2 options: ಶುಕ್ಲ (Shukla) / ಕೃಷ್ಣ (Krishna)
- **Tithi** — required, 15 options per paksha (Pratipada to Chaturdashi + Purnima/Amavasya)
- **Date Range** — from/to date pickers (default: today → 6 months)

**Search logic:**
1. Loop through each day in the date range
2. Call `AstroCalculator.calculate()` at sunrise time (using saved lat/lon/tz from `LocationService`)
3. Compare `PanchangData.tithiIndex`, `chandraMasaRaw`, `souraMasa` against selected filters
4. Collect matching dates

**Result display (for each match):**
- Date and Vara (day)
- Tithi with end time
- Nakshatra with end time
- Karana with end time
- Yoga with end time
- Chandra Masa + Soura Masa

**UI design:**
- Material card-based results list
- Loading spinner with progress text ("Scanning day 45/180...")
- Empty state if no matches found
- Results styled consistently with existing panchanga display

---

### Localization

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)
- Add locale keys: `panchangaSearch`, `searchBtn`, `fromDate`, `toDate`, `pakshaLabel`, `scanning`, `noResults`, `resultsFound`

## Verification Plan

### Automated Tests
- Verify the app builds: `flutter build apk --debug`

### Manual Verification
- Test searching for known dates (e.g., next Ekadashi)
- Verify results match existing Panchanga screen output for those dates
