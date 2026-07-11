# Fix Localization Issues Across the App

## Problem
When the app is set to Hindi (or other non-Kannada languages), several UI elements still display in Kannada.

## Issues Found

### 1. Matchmaking — Hardcoded Kannada Strings
**File**: [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)
- Line 878: `'ಇಬ್ಬರಿಗೂ ಕುಜ ದೋಷ ✅'` and `'ಇಬ್ಬರಿಗೂ ಕುಜ ದೋಷ ಇಲ್ಲ ✅'` — hardcoded Kannada
- **Fix**: Replace with `AppLocale.l()` locale keys for all Kuja Dosha verdict strings

### 2. Kundali Chart — Planet Names Stay in Kannada
**File**: [kundali_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/kundali_chart.dart)
- The `_shortNames` maps (line 517) ARE locale-aware, but the **degree display** path (line 570) uses `shortName` which falls back to the raw Kannada `name` if the map lookup fails
- Need to verify all keys in `_shortNamesHi/Ta/Te/Ml` match exactly with engine output keys
- **Fix**: Add `translateKn(name)` fallback when `_shortNames[name]` returns null

### 3. Panchanga Search — Dropdown Values
**File**: [panchanga_search_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/panchanga_search_screen.dart)
- Dropdown items use Kannada source strings (line 17-38) passed through `trAll()` (line 379)
- The `trAll()` chain should translate via `translateKn()`, but some masa/tithi names may not be in the translation map
- **Fix**: Verify all Chandra Masa, Soura Masa, and Tithi names are covered by `translateKn()` mapping

### 4. North Indian Chart
**File**: [north_indian_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/north_indian_chart.dart)
- Same issue as kundali_chart — no `translateKn()` usage
- **Fix**: Apply same planet name translation fix

## Proposed Changes

### Matchmaking Tab
#### [MODIFY] [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)
- Add locale keys for Kuja Dosha verdict strings
- Add locale keys for "वर के विवरण" / "वधू के विवरण" labels if hardcoded
- Search for all remaining hardcoded Kannada strings and replace with `AppLocale.l()` calls

---

### Kundali Chart  
#### [MODIFY] [kundali_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/kundali_chart.dart)
- In `_planetChip()`, use `translateKn(name)` as fallback when `_shortNames[name]` returns null
- Ensure all display paths use locale-aware names

#### [MODIFY] [north_indian_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/north_indian_chart.dart)
- Apply same translation fix for planet names

---

### Panchanga Search
#### [MODIFY] [panchanga_search_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/panchanga_search_screen.dart)
- Verify `trAll()` correctly translates all dropdown items
- If needed, use `AppLocale.l('cm$i')` directly for Chandra Masa items instead of hardcoded Kannada

---

### Locale Strings
#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)
- Add any missing locale keys for matchmaking verdict strings

## Verification Plan
- Switch app to Hindi and verify all tabs display correctly
- Test matchmaking Kuja Dosha section
- Test panchanga search dropdowns
- Test kundali chart planet names in all 5 languages
