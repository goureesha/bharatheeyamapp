# Sync Original → Clone Tasks

## Phase 1: Copy new files
- [x] `core/transit_cache.dart`
- [x] `screens/panchanga_search_screen.dart`
- [x] `screens/pooja_lists_screen.dart`
- [x] `screens/support_screen.dart` (stripped security refs)
- [x] `screens/vastu_screen.dart`
- [x] `services/pooja_list_service.dart`

## Phase 2: Diff & merge shared files
- [x] Core logic files (8 files) — copied from original
- [x] Screen files — copied from original (skip appointment/prashna)
- [x] Service files — copied from original (skip security)
- [x] Widgets (7 files) — copied from original (including 326KB common.dart)
- [x] Constants, models — copied from original
- [x] main.dart — merged (sunrise widget, scaffoldMessengerKey, theme improvements)

## Phase 3: Update navigation
- [x] Wire new screens into home (Panchanga Search, Pooja Lists, Vastu)
- [x] Add ValueListenableBuilder for language in home_screen
- [x] Strip security references from support_screen

## Files kept as clone version (clone has custom improvements):
- [x] `services/calendar_service.dart` (clone has Google Calendar integration)
- [x] `services/firebase_service.dart` (clone uses secrets.dart)
- [x] `services/google_auth_service.dart` (clone has updated client ID)
- [x] `services/storage_service.dart` (clone may have differences)

## Verification
- [/] Flutter analyze — running
- [ ] Build APK
- [x] Verify Prashna/Appointment untouched
- [x] Verify no security code copied (scan passed ✅)
