# Muhurta Finder Tab in Taranukoola Screen

Add a second tab to the existing Taranukoola screen that acts as a Muhurta Finder — user picks rashi, nakshatra, month, and event, and the app scans for valid daytime muhurta dates.

## Proposed Changes

### [MODIFY] [taranukoola_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/taranukoola_screen.dart)

#### 1. Convert to TabBar layout
- Add `SingleTickerProviderStateMixin` and a `TabController(length: 2)`
- Tab 1: **ತಾರಾನುಕೂಲ** (current calendar view — no changes to existing code)
- Tab 2: **ಮುಹೂರ್ತ ಶೋಧನೆ** (Muhurta Finder — new)

#### 2. Tab 2 — Muhurta Finder UI

**Inputs:**
| Input | Widget | Source |
|---|---|---|
| ರಾಶಿ (Rashi) | Dropdown (12 rashis) | Hardcoded list |
| ನಕ್ಷತ್ರ (Nakshatra) | Dropdown (27 nakshatras) | Hardcoded list |
| ತಿಂಗಳು (Month) | Month picker | Current + next 3 months |
| ಕಾರ್ಯ (Event) | Dropdown | 19 `MuhurtaEvent` values from `muhurta_rules.dart` |

**Search Button:** Scans every day in the selected month

**For each day, the engine checks:**
1. ✅ Tithi matches event's `allowedTithis`
2. ✅ Nakshatra matches event's `allowedNakshatras`
3. ✅ Vara matches event's `allowedVaras`
4. ✅ Karana not Vishti (if `avoidVishti`)
5. ✅ Paksha is Shukla (if `requireShukla`)
6. ✅ Uttarayana (if `requireUttarayana`)
7. ✅ Tara Bala good (from user's birth nakshatra)
8. ✅ Guru Bala good (Jupiter transit from user's rashi)
9. ✅ No Dagdha Yoga
10. ❌ Skip Visha Ghati windows
11. ❌ Skip Rahu Kala windows
12. ✅ Day muhurtas only (sunrise to sunset)

**Result Cards (sorted by score):**
Each valid date shows:
- **Date & Vara** (e.g., 15/08/2026 ಗುರುವಾರ)
- **Tithi** with end time
- **Nakshatra** with pada & end time
- **Tara Bala** result (ಸಂಪತ್, ಕ್ಷೇಮ, etc.)
- **Guru Bala** result (ಶುಭ/ಪೂಜ್ಯ)
- **Score badge** (ಶ್ರೇಷ್ಠ/ಮಧ್ಯಮ)
- **Avoidance note**: Visha Ghati time, Rahu Kala time to avoid

**No results state:** "ಈ ತಿಂಗಳಲ್ಲಿ ಯೋಗ್ಯ ಮುಹೂರ್ತ ಕಂಡುಬಂದಿಲ್ಲ"

#### 3. Engine: `_scanMonthMuhurtas()` method
- Loop through each day of selected month
- Calculate panchanga using existing `AstroCalculator.calculate()`
- Call existing `MuhurtaRules.evaluateMuhurta()` with the event + person's rashi/nak
- Filter results: score >= 60 (ಮಧ್ಯಮ or better)
- For each passing day, compute Rahu Kala and Visha Ghati windows and attach as avoidance times
- Sort by score descending
- Return List of result maps

---

### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)

Add locale strings for all 5 languages:
- `muhurtaShodhane`: ಮುಹೂರ್ತ ಶೋಧನೆ / मुहूर्त खोज / முகூர்த்த தேடல் / ముహూర్త శోధన / മുഹൂർത്ത ശോധന
- `selectRashi`, `selectNakshatra`, `selectMonth`, `selectEvent`
- `searchMuhurta`: ಮುಹೂರ್ತ ಹುಡುಕಿ
- `noMuhurtaFound`: ಈ ತಿಂಗಳಲ್ಲಿ ಯೋಗ್ಯ ಮುಹೂರ್ತ ಕಂಡುಬಂದಿಲ್ಲ
- `avoidTime`: ವರ್ಜ್ಯ ಸಮಯ
- `rahuKala`: ರಾಹು ಕಾಲ
- `vishaGhati`: ವಿಷ ಘಟಿ

## Verification Plan

### Manual Verification
- Select a rashi, nakshatra, month, and event → verify results appear
- Confirm visha ghati and rahu kala times are shown as avoidance
- Check all 5 languages render properly
- Verify only daytime muhurtas are shown
