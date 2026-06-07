# Sync Original App Features into Clone

Bring features from the **original app** (`D:\bharatheeyamapp sample`) into the **clone** (`D:\bharatheeyamapp clone`), while preserving clone-only features and excluding security.

## User Rules
- ❌ **Do NOT touch** Prashna section (clone-only: `prashna_dashboard_screen.dart`, `prashna_input_screen.dart`, `prashna_chart.dart`)
- ❌ **Do NOT touch** Appointment section (`appointment_screen.dart`, `appointment_service.dart`)
- ❌ **Do NOT copy** security features from original (`offline_access_service.dart`, `subscription_service.dart`, `trusted_time_service.dart`, `device_binding_service.dart`)
- ✅ **Keep** clone-only files: `secrets.dart`, `ad_service.dart`, `ashtamangala_screen.dart`, `graha_phala.dart`

## File Analysis

### Files to ADD (in original, missing from clone)

| File | Purpose | Security? |
|------|---------|-----------|
| `core/transit_cache.dart` | Transit calculation caching | No ✅ COPY |
| `screens/panchanga_search_screen.dart` | Search panchanga by date | No ✅ COPY |
| `screens/pooja_lists_screen.dart` | Pooja/ritual lists | No ✅ COPY |
| `screens/support_screen.dart` | Support/help page | No ✅ COPY |
| `screens/vastu_screen.dart` | Vastu analysis | No ✅ COPY |
| `services/pooja_list_service.dart` | Pooja list data service | No ✅ COPY |
| `services/offline_access_service.dart` | Offline license checking | **Yes ❌ SKIP** |
| `services/subscription_service.dart` | Subscription/payment | **Yes ❌ SKIP** |
| `services/trusted_time_service.dart` | Tamper-proof time for licenses | **Yes ❌ SKIP** |

### Files in BOTH (need diff to check for updates)

These exist in both repos but may have improvements in the original. Need to diff each one and selectively merge non-security updates:

**Core logic** (likely has improvements):
- `core/ashtakavarga.dart`
- `core/calculator.dart`
- `core/ephemeris.dart`
- `core/events.dart`
- `core/match_making.dart`
- `core/muhurta_rules.dart`
- `core/shadbala.dart`
- `core/transit_calculator.dart`

**Screens** (may have UI improvements — exclude appointment/prashna):
- `screens/about_screen.dart`
- `screens/client_detail_screen.dart`
- `screens/dashboard_screen.dart`
- `screens/home_screen.dart`
- `screens/input_screen.dart`
- `screens/match_making_tab.dart`
- `screens/panchanga_screen.dart`
- `screens/planets_screen.dart`
- `screens/settings_screen.dart`
- `screens/taranukoola_screen.dart`
- `screens/vedic_clock_screen.dart`

**Services** (may have improvements — exclude security):
- `services/backup_service.dart` (and mobile/web/stub)
- `services/calendar_service.dart`
- `services/client_service.dart`
- `services/docs_service.dart`
- `services/drive_backup_service.dart`
- `services/export_service.dart` (and mobile/web)
- `services/festival_cache_service.dart`
- `services/firebase_service.dart`
- `services/google_auth_service.dart`
- `services/history_service.dart`
- `services/janma_patrike_service.dart`
- `services/location_service.dart`
- `services/network_service.dart`
- `services/pdf_service.dart`
- `services/pdf_theme.dart`
- `services/sheets_service.dart`
- `services/storage_service.dart`

**Other:**
- `main.dart`
- `constants/places.dart`
- `constants/strings.dart`
- `models/library_models.dart`
- `widgets/*`

## Open Questions

> [!IMPORTANT]
> The original has **9 new features** to potentially copy and **~60 shared files** to diff. This is a large merge.

> [!WARNING]
> Some shared files (e.g., `main.dart`, `home_screen.dart`, `dashboard_screen.dart`) likely reference security services from the original. We'll need to carefully strip those references when merging.

1. Should I copy ALL non-security improvements from the original, or only specific features?
2. For shared files with small differences — should I prefer the original's version or just add missing features?

## Proposed Changes

### Phase 1: Copy new files from original
- Copy `transit_cache.dart`, `panchanga_search_screen.dart`, `pooja_lists_screen.dart`, `support_screen.dart`, `vastu_screen.dart`, `pooja_list_service.dart`
- Wire them into navigation (home_screen, dashboard)

### Phase 2: Diff and merge shared files
- Diff each shared file, identify non-security improvements
- Apply improvements to clone versions
- Strip any references to `offline_access_service`, `subscription_service`, `trusted_time_service`

### Phase 3: Update navigation
- Add new screens to home/dashboard navigation
- Update `main.dart` with any new routes (excluding security)

## Verification Plan

### Manual Verification
- Build APK and test all screens
- Verify Prashna and Appointment sections unchanged
- Verify no security/subscription code was copied
