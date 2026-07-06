# Single Letter Kundali View

Add a toggle on the input page to switch between the current view (abbreviation + degrees) and a "single letter" view (abbreviation only, no degrees) for Rashi and Bhava kundali charts.

## Reference Screenshots

The reference app shows:
- Planet abbreviations only (ಚ, ಶ, ಕು, ರ, etc.) — **NO degrees**
- Multiple planets in one house shown as individual letter chips
- Clean, minimal layout

## Proposed Changes

### Settings Model

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)

Add a `SingleLetterMode` class (similar to `SamshakaMode`):
- `static ValueNotifier<bool> notifier`
- `static bool get isActive`
- `static Future<void> load()` — reads from SharedPreferences
- `static Future<void> toggle()` — toggles and persists

---

### Chart Rendering

#### [MODIFY] [kundali_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/kundali_chart.dart)

In `_planetChip()` (line 513):
- When `SingleLetterMode.isActive` is true AND the chart is D1 (Rashi) or Bhava:
  - Show only `shortName` without degrees
  - Skip degree string entirely

#### [MODIFY] [north_indian_chart.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/north_indian_chart.dart)

Same change in the North Indian chart's planet chip rendering for consistency.

---

### Input Page Toggle

#### [MODIFY] [input_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/input_screen.dart)

Add a toggle/switch for "Single Letter View" in the input form, near the existing settings area. This will be a `SwitchListTile` that controls `SingleLetterMode`.

---

### Locale Strings

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)

Add locale key `singleLetterMode` with translations:
- Kannada: `ಏಕಾಕ್ಷರ ಕುಂಡಲಿ`
- Hindi: `एकाक्षर कुंडली`
- Tamil: `ஒற்றை எழுத்து குண்டலி`
- Telugu: `ఏకాక్షర కుండలి`
- Malayalam: `ഏകാക്ഷര കുണ്ഡലി`

---

### Initialization

#### [MODIFY] [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart)

Add `SingleLetterMode.load()` to the Phase 1 init (alongside `SamshakaMode.load()`).

## Verification Plan

### Manual Verification
- Toggle ON: Rashi and Bhava charts show only single letter abbreviations (no degrees)
- Toggle OFF: Charts show abbreviations + degrees as before
- Other charts (Navamsha, Hora, etc.) are unaffected
- Preference persists across app restarts
