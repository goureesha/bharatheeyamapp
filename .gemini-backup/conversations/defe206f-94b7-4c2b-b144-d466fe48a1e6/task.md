# Language Integration - Remaining Kannada Text

## Priority 1: Chart/Core display files
- [ ] `kundali_chart.dart` — planet key lookups (`'ಲಗ್ನ'`), abbreviation maps
- [ ] `north_indian_chart.dart` — planet key lookups, color switch cases
- [ ] `shadbala_widget.dart` — planet key array `pKeysKn`

## Priority 2: Dashboard remaining
- [ ] `dashboard_screen.dart` — tab names (line 158), `'ರವಿ'` lookup (1581), planet abbreviations (1722), export count text (1383)

## Priority 3: Panchanga & Ashtamangala
- [ ] `panchanga_screen.dart` — weekday maps (141-142), choug/hora names, muhurta names
- [ ] `ashtamangala_screen.dart` — rashi/nak/tithi/vara name arrays

## Priority 4: Other screens
- [ ] `taranukoola_screen.dart` — tara group names (34-41)
- [ ] `vedic_clock_screen.dart` — `'ಲಗ್ನ'` lookup
- [ ] `match_making_tab.dart` — `'ರಾಶಿ'` label
- [ ] `settings_screen.dart` — hardcoded bilingual strings

## Notes
- DO NOT change calculator.dart or core engine files
- All planet key lookups (`planets['ಲಗ್ನ']`) are data keys, NOT display text — these stay as-is
- Only change text that's DISPLAYED to the user
