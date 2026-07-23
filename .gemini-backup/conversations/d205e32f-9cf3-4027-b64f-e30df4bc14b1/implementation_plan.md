# Quick Koota Match Tab in Matchmaking Screen

Add a new tab to the matchmaking screen that lets users quickly check koota compatibility by selecting rashi + nakshatra (without needing full birth details).

## Proposed Changes

### [MODIFY] [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)

Add a tab bar with 2 tabs:
- **Tab 1** (existing): Full kundali-based matchmaking with birth details
- **Tab 2** (new): Quick Koota Match — select bride/groom rashi + nakshatra only

#### Tab 2 UI:
1. **Bride Section**: Rashi dropdown + Nakshatra dropdown (filtered by rashi using `_naksForRashi`)
2. **Groom Section**: Same
3. **Calculate Button**
4. **Results**:
   - Ashta Koota table (reuse `_buildAshtaKootaTable`)
   - Dvadasha Koota table (reuse `_buildDvadashaKootaTable`)
   - **Guru Bala Section**: 
     - Current guru bala status for both bride & groom
     - Jupiter transit timeline showing:
       - If guru bala present: "ಗುರು ಬಲ ಇದೆ — [current rashi] — [end date] ವರೆಗೆ"
       - If guru bala absent: "ಗುರು ಬಲ ಇಲ್ಲ — [start date] ರಿಂದ [end date] ವರೆಗೆ ಬರುತ್ತದೆ"
       - Show next 3-4 guru bala windows with dates

### Jupiter Transit Calculation:
- Use `Ephemeris.calcAll()` to find Jupiter's sidereal longitude at monthly intervals
- Detect rashi transitions (when Jupiter crosses 30° boundaries)
- For each rashi, check `calculateGuruBala()` to determine if guru bala is present
- Scan next ~12 years (one full Jupiter cycle) to find all bala windows

## Verification Plan
- Build the app and test with different rashi/nakshatra combinations
- Verify koota points match existing full matchmaking results
- Verify guru bala transit dates are reasonable (~1 year per rashi)
