# Google Calendar 2-Way Sync — Tasks

## Package Setup
- [x] Add `googleapis`, `googleapis_auth`, `extension_google_sign_in_as_googleapis_auth` to pubspec.yaml
- [/] Run `flutter pub get` (running...)

## Model Changes
- [x] Add `googleEventId` field to `Appointment` class
- [x] Update `Appointment.fromRow()` and `toRow()` for the new field
- [x] Add `Appointment.copyWith()` method
- [x] Update `loadFromCache()` parsing (handles 10th field gracefully)

## Auth Service
- [x] Add calendar scopes to `GoogleAuthService` (`calendar`, `calendar.events`)
- [x] Add `ensureCalendarScope()` method
- [x] Add `getAuthenticatedClient()` method via `extension_google_sign_in_as_googleapis_auth`

## Calendar Service (Full Rewrite)
- [x] Initialize CalendarApi from GoogleSignIn auth
- [x] `getOrCreateCalendar()` — find/create "ಭಾರತೀಯಮ್ Appointments" calendar
- [x] `pushAppointment()` — create/update event from local appointment
- [x] `pullEvents()` — fetch events from GCal (30 days back, 90 days forward)
- [x] `deleteEvent()` — remove event
- [x] `fullSync()` — bidirectional sync logic with app-as-source-of-truth
- [x] `_toEvent()` / `_toAppointment()` converters
- [x] Legacy `createAppointment()` method (backward compatible)
- [x] `loadLastSyncTime()` / `reset()` helpers

## Appointment Service Integration
- [x] Hook `CalendarService.pushAppointment()` into booking flow
- [x] Preserve `googleEventId` in `updateStatus()`
- [x] Add `updateAppointment()` method for full field updates
- [x] Add `setGoogleEventId()` method
- [x] Add `addAppointmentDirect()` for pulled events

## UI Updates (appointment_screen.dart)
- [x] Update `_syncInBackground` to trigger `CalendarService.fullSync()`
- [x] Update `_syncData` to show sync results (pushed/pulled/deleted counts)
- [x] Update sync button tooltip with last sync time
- [x] Replace old `CalendarService.createAppointment()` call with 2-way sync

## Verification
- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` passes
- [ ] `flutter build apk --debug` succeeds
