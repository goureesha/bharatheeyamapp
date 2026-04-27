# Localization Task Progress

## Phase 1: Taranukoola Screen
- [x] Add night muhurta keys (nmuh0-nmuh14) to common.dart for all 5 languages
- [x] Replace hardcoded _dayMuhurtaNames array with AppLocale.l() lookups
- [x] Replace hardcoded _nightMuhurtaNames array with AppLocale.l() lookups
- [x] Engine data keys (ಚಂದ್ರ, ಗುರು, etc.) — intentionally left alone

## Phase 2: Appointment Screen (~36 UI strings)
- [x] Add appointment keys to common.dart (all 5 languages)
- [x] Replace hardcoded Kannada strings in appointment_screen.dart
- [x] Month and day name arrays at bottom of file

## Phase 3: Dashboard Screen
- [x] Audit and classify engine vs UI strings
- [x] Add `kundaliCount` key to common.dart (all 5 languages)
- [x] Replace `ಕುಂಡಲಿ` with AppLocale.l('kundaliCount')
- [x] Engine keys (ಸೂರ್ಯ, ಲಗ್ನ, etc.) — intentionally left alone
- [x] Tab names, month abbrevs, dasha suffixes — already multi-language inline

## Phase 4: Settings Screen
- [x] Add keys to common.dart (clockTampered, aboutUsLink, privacyLink, driveBackupDesc)
- [x] Replace 4 hardcoded strings

## Phase 5: Match Making Tab
- [x] Replace 2 dropdown labels ('ರಾಶಿ' → rashiLabel)

## Phase 6: Privacy Policy Screen
- [x] Localize AppBar title (reused privacyLink key)
- [x] Body content kept bilingual (Kannada + English) — legal document, not suitable for per-paragraph localization

## Skipped (per user request)
- Ashtamangala screen
- About Us screen
