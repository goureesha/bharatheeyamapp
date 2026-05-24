# Google Calendar 2-Way Sync for Appointments

Add bidirectional sync between the Bharatheeyam appointment system and Google Calendar, so appointments created in the app appear in Google Calendar and vice versa.

## Current State

- Appointments stored **locally only** in SharedPreferences
- `CalendarService` exists but is a **stub** (was disabled — comment says "sensitive scope removed")
- `GoogleAuthService` with `google_sign_in` is **already working** (used to gate appointment screen access)
- `googleapis` / `googleapis_auth` packages are **NOT installed**
- Firestore is used only for inbound web booking requests

---

## What YOU Need To Do (Google Cloud Console Setup)

> [!IMPORTANT]
> These steps **must be done by you** in the browser — I cannot do them for you. They take about 15-20 minutes.

### Step 1: Enable Google Calendar API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **`bharatheeyam-app`**
3. Go to **APIs & Services → Library**
4. Search for **"Google Calendar API"**
5. Click **Enable**

### Step 2: Configure OAuth Consent Screen

This is the critical step. Google Calendar uses a **"sensitive scope"** (`https://www.googleapis.com/auth/calendar`), which is why it was previously disabled.

1. Go to **APIs & Services → OAuth consent screen**
2. If not already set, choose **External** user type
3. Fill in the app info:
   - App name: `Bharatheeyam`
   - User support email: your email
   - Developer contact: your email
4. On the **Scopes** page, click **Add or remove scopes** and add:
   - `https://www.googleapis.com/auth/calendar` (read/write calendar)
   - `https://www.googleapis.com/auth/calendar.events` (read/write events)
5. Click **Save and Continue**

> [!WARNING]
> **Sensitive Scope Verification**: While in **Testing** mode, only users you add as **Test Users** can use the calendar sync (up to 100 users). This is fine for personal/small use. For a published Play Store app with many users, you'd need to submit for Google's verification (takes weeks). For now, **Testing mode is sufficient**.

6. On the **Test Users** page, add your own Google email
7. Click **Save and Continue**

### Step 3: Get Your OAuth Client IDs

You likely already have these (for Google Sign-In), but verify:

1. Go to **APIs & Services → Credentials**
2. You should see:
   - **Android OAuth Client** — linked to your app's package name & SHA-1
   - **Web OAuth Client** — needed for the `googleapis` package

> [!IMPORTANT]
> **I need from you**: Confirm that both Android and Web OAuth client IDs exist. If the Web client ID is missing, create one:
> - Click **Create Credentials → OAuth client ID**
> - Type: **Web application**
> - Name: `Bharatheeyam Web Client`
> - No redirect URIs needed
> - Copy the **Client ID** — I'll need it for the code

### Step 4: Get Android SHA-1 Fingerprint (if not already done)

If your Android OAuth client isn't set up yet:
```bash
cd android
./gradlew signingReport
```
Copy the **SHA-1** fingerprint and add it to the Android OAuth client in Cloud Console.

---

## Open Questions

> [!IMPORTANT]
> **Q1: Which Google Calendar should appointments sync to?**
> - **Option A**: The user's primary/default calendar (simplest)
> - **Option B**: A dedicated "Bharatheeyam Appointments" calendar (cleaner separation)
> - **Recommendation**: Option B — create a dedicated calendar so personal events don't mix with client appointments

> [!IMPORTANT]
> **Q2: What should happen on conflict?**
> When the same appointment is edited in both the app and Google Calendar:
> - **Option A**: App wins (app is source of truth)
> - **Option B**: Google Calendar wins
> - **Option C**: Last-edit wins (compare timestamps)
> - **Recommendation**: Option A — the app is the primary tool, Google Calendar is the mirror

> [!IMPORTANT]
> **Q3: Do you want automatic background sync or manual sync button?**
> - **Option A**: Auto-sync every time the appointment screen opens + manual sync button
> - **Option B**: Only sync when the user taps the sync button
> - **Recommendation**: Option A — auto on screen open + manual button for on-demand

---

## Proposed Changes

### Data Mapping: Appointment → Google Calendar Event

| Appointment Field | Google Calendar Event Field |
|---|---|
| `clientName` | Event **title** → `"🔮 {clientName}"` |
| `date` + `startTime` | Event **start** (dateTime with timezone) |
| `date` + `endTime` | Event **end** (dateTime with timezone) |
| `notes` | Event **description** |
| `clientPhone` | Event description (appended) |
| `status` | `cancelled` → delete from GCal; `completed` → update color |
| `id` (local) | Stored in event **extendedProperties.private["bharatheeyam_id"]** |
| — | Event **id** stored locally as `googleEventId` field on Appointment |

---

### Flutter Packages (New Dependencies)

#### [MODIFY] [pubspec.yaml](file:///d:/bharatheeyamapp%20clone/pubspec.yaml)
Add these packages:
```yaml
googleapis: ^13.2.0                          # Google Calendar API client
googleapis_auth: ^1.6.0                      # OAuth2 for googleapis
extension_google_sign_in_as_googleapis_auth: ^2.0.12  # Bridge google_sign_in → googleapis auth
```

---

### Service Layer

#### [MODIFY] [calendar_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/calendar_service.dart)
Replace the current stub (17 lines) with a full implementation (~250 lines):

- **`initialize()`** — Get authenticated `CalendarApi` client using the existing Google Sign-In session
- **`getOrCreateCalendar()`** — Find or create a "Bharatheeyam Appointments" calendar
- **`pushAppointment(Appointment)`** — Create/update a Google Calendar event from a local appointment
- **`pullEvents(DateTime start, DateTime end)`** — Fetch events from Google Calendar → convert to Appointment objects
- **`deleteEvent(String googleEventId)`** — Remove event from Google Calendar
- **`fullSync(List<Appointment> local)`** — Bidirectional sync:
  1. Push all local appointments that don't have a `googleEventId`
  2. Pull all GCal events and create/update local appointments
  3. Handle deletions (cancelled locally → delete from GCal; deleted from GCal → mark cancelled locally)
- **`_toEvent(Appointment)`** — Convert Appointment → Google Calendar Event
- **`_toAppointment(Event)`** — Convert Google Calendar Event → Appointment

---

#### [MODIFY] [appointment_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/appointment_service.dart)
- Add `googleEventId` field to the `Appointment` model (nullable String)
- Update `toTabSeparated()` / `fromTabSeparated()` to include the new field
- Add `updateAppointment(Appointment)` method for full field updates (currently only status can be updated)
- Hook calendar sync into `addAppointment()`, `updateStatus()`, and `deleteAppointment()`

---

#### [MODIFY] [google_auth_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/google_auth_service.dart)
- Add `calendar` scope to the Google Sign-In scopes list
- Add method `getAuthenticatedClient()` that returns an `AuthClient` for `googleapis`
- Users may need to re-sign-in to grant the new calendar scope

---

### UI Layer

#### [MODIFY] [appointment_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/appointment_screen.dart)
- Update the **sync button** (currently just reloads cache) to trigger `CalendarService.fullSync()`
- Show sync status indicator (syncing spinner, last synced timestamp, error messages)
- Show a small Google Calendar icon on appointments that are synced
- Update the existing `CalendarService.createAppointment()` call (line ~1035) to use the real implementation
- Add a **"Sync Now"** floating action option or toolbar button

---

## Verification Plan

### Automated Tests
```bash
# Build check — ensure no compilation errors
cd "d:\bharatheeyamapp clone"
flutter analyze
flutter build apk --debug
```

### Manual Verification
1. **Sign in** → verify calendar scope is requested
2. **Create appointment** in app → verify it appears in Google Calendar
3. **Create event** in Google Calendar → tap sync → verify it appears in app
4. **Cancel appointment** in app → verify it disappears from Google Calendar
5. **Delete event** in Google Calendar → tap sync → verify appointment is marked cancelled
6. **Edit appointment time** in app → verify Google Calendar event updates
7. **Offline resilience** → create appointment without internet → verify it syncs when back online
