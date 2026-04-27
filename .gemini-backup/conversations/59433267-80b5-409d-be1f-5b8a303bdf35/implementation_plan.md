# Continuing Multi-Language Localization — Remaining Screens

## Current Status

The following screens have already been localized:
- ✅ `panchanga_screen.dart` (mostly complete — 2 residual lines are data keys)
- ✅ `taranukoola_screen.dart` (mostly complete — still has muhurta deity names and a few display strings)

## Remaining Work Summary

| File | Kannada Lines | Type |
|------|:---:|------|
| `taranukoola_screen.dart` | 14 | Night muhurta names, 2 display `knNak[]` wraps, engine data keys (leave alone) |
| `ashtamangala_screen.dart` | 223 | **Largest** — rashi/nak/planet arrays and UI labels |
| `about_screen.dart` | 39 | Bilingual section headers and descriptions |
| `appointment_screen.dart` | 36 | UI labels, dialog text, snackbar messages |
| `privacy_policy_screen.dart` | 28 | Full privacy policy text |
| `dashboard_screen.dart` | 16 | Month names, Kannada numeral map, misc UI |
| `settings_screen.dart` | 8 | Language label, NTP text, About Us label |
| `match_making_tab.dart` | 2 | Dropdown labels ("ರಾಶಿ") |
| `input_screen.dart` | 1 | Sample name filter string |
| `vedic_clock_screen.dart` | 2 | Engine data key (ಲಗ್ನ) — leave alone |
| `kundali_chart.dart` | 59 | Engine data keys — **must NOT change** |
| `north_indian_chart.dart` | 68 | Engine data keys — **must NOT change** |
| `planet_detail_sheet.dart` | 1 | Already localized |
| `shadbala_widget.dart` | 1 | Engine planet key array |

> [!IMPORTANT]
> **Chart files** (`kundali_chart.dart`, `north_indian_chart.dart`) and engine-facing Kannada strings (planet names used as map keys like `'ಚಂದ್ರ'`, `'ಗುರು'`, `'ಲಗ್ನ'`) **must NOT be changed**. They are used for data lookups.

## Proposed Changes

### Phase 1: Taranukoola Screen — Night Muhurta Names

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)
- Add `nmuh0`–`nmuh14` keys for all 5 languages (night muhurta deity names: ಗಿರೀಶ, ಅಜಿಪಾದ, ಅಹಿರ್ಬುಧ್ನ, ಪೂಷಾ, ಅಶ್ವಿನೀ, ಯಮ, ಅಗ್ನಿ, ವಿಧಾತೃ, ಚಂಡ, ಅದಿತಿ, ಜೀವ, ವಿಷ್ಣು, ದ್ಯುಮದ್ಗದ್ಯುತಿ, ತ್ವಷ್ಟೃ, ವಾಯು)

#### [MODIFY] [taranukoola_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/taranukoola_screen.dart)
- Replace hardcoded `_dayMuhurtaNames` → use `AppLocale.l('muh0')` through `muh14`
- Replace hardcoded `_nightMuhurtaNames` → use `AppLocale.l('nmuh0')` through `nmuh14`
- Wrap 2 instances of raw `knNak[dinaIdx]` with `trAll()` (lines 539, 562)

---

### Phase 2: Ashtamangala Screen (223 lines)

#### [MODIFY] [ashtamangala_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/ashtamangala_screen.dart)
- Audit all 223 Kannada lines; classify engine keys vs display text
- Replace display labels/headers with `AppLocale.l()` keys
- Add any missing keys to `common.dart` for all 5 languages

---

### Phase 3: Appointment, Dashboard, Settings Screens

#### [MODIFY] [appointment_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/appointment_screen.dart)
- Replace 36 lines of hardcoded Kannada UI labels

#### [MODIFY] [dashboard_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/dashboard_screen.dart)
- Replace month name arrays with `AppLocale.l()` calls
- Localize the Kannada numeral map lookup

#### [MODIFY] [settings_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/settings_screen.dart)
- 8 remaining hardcoded Kannada strings

#### [MODIFY] [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)
- 2 dropdown label references

---

### Phase 4: About & Privacy Screens

#### [MODIFY] [about_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/about_screen.dart)
- 39 lines of bilingual section headers

#### [MODIFY] [privacy_policy_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/privacy_policy_screen.dart)
- 28 lines of full Kannada privacy text

---

## Open Questions

> [!IMPORTANT]
> 1. **Ashtamangala screen**: This has 223 Kannada lines — it's the largest remaining screen. Should I proceed with full localization, or is this screen lower priority?
> 2. **Privacy Policy / About Us**: These are large blocks of prose text. Should I localize them fully into all 5 languages, or keep them as bilingual Kannada+English?
> 3. **Dashboard Kannada numerals**: The dashboard has a Kannada numeral conversion map. Should numerals remain Kannada across all languages, or use each language's native numerals?

## Verification Plan

### Automated
- Run `flutter analyze` after each phase to verify compilation
- Grep scan for remaining Kannada characters outside `common.dart` and engine files

### Manual
- UI review in all 5 languages for layout overflow
