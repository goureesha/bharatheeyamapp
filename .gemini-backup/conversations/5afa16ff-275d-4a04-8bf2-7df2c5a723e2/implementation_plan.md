# Cloud Sync for App Data

## Goal
Auto-sync app data (clients, appointments, profiles) to Firestore cloud once per day, with a manual "Sync Now" button in Settings.

## User Review Required

> [!IMPORTANT]
> This syncs **all** app data to Firestore under `user_data/{email}`. Data is tied to the signed-in Google account.
> - Only works when user is signed in with Google
> - Syncs: Clients, Family Members, Appointments, Kundali Profiles
> - Does NOT sync: settings, theme, history (those stay local)

## Proposed Changes

### Cloud Sync Service

#### [NEW] `lib/services/cloud_sync_service.dart`
- `syncToCloud()` — uploads all SharedPreferences backup keys to Firestore `user_data/{email}/backup`
- `syncFromCloud()` — downloads from Firestore and merges into local data
- `autoSyncIfNeeded()` — checks if 24h have passed since last sync, syncs if so
- Stores `last_cloud_sync_ms` in SharedPreferences for throttling
- Shows debug prints for sync status

### Main Initialization

#### [MODIFY] `lib/main.dart`
- Call `CloudSyncService.autoSyncIfNeeded()` in `_deferredInit()` (after first frame, non-blocking)

### Settings UI

#### [MODIFY] `lib/screens/settings_screen.dart`
- Add "Cloud Sync" button in the Google Account section (only when signed in)
- Shows last sync time
- Manual "Sync Now" button

## Verification Plan
- Build the app and verify no compile errors
- Check that auto-sync runs on launch when signed in
- Verify manual sync button works in Settings
