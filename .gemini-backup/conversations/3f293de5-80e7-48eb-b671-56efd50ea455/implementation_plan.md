# Gmail-Based User Management + Admin Dashboard

## Goal
- Make Gmail login mandatory to use the app
- Track devices per Gmail account in Firestore
- Allow admin to block/unblock users by email
- Build an admin web dashboard to monitor all users

## Firestore Structure

```
users/
  {email}/
    name: "User Name"
    photoUrl: "..."
    status: "active" | "blocked"
    createdAt: timestamp
    lastLogin: timestamp
    deviceCount: 3
    devices/
      {deviceId}/
        model: "Samsung Galaxy S24"
        os: "Android 15"
        appVersion: "2.0.1"
        lastActive: timestamp
        firstLogin: timestamp
```

## Proposed Changes

### App Side (Flutter)

---

#### [NEW] `lib/services/user_session_service.dart`
- On login: register device info to Firestore `users/{email}/devices/{deviceId}`
- Check if user is blocked → show "Account blocked" screen
- Track device count
- Uses `device_info_plus` + `package_info_plus`

#### [MODIFY] `lib/main.dart`
- After auth: call `UserSessionService.registerDevice()`
- Check blocked status before showing home screen
- If blocked → show blocked message, sign out

#### [MODIFY] `lib/screens/home_screen.dart`
- If not signed in → redirect to sign-in screen
- Gmail login is mandatory gate

#### [MODIFY] `pubspec.yaml`
- Add `device_info_plus: ^11.0.0`

---

### Admin Website (Static HTML+JS)

#### [NEW] `web/admin/index.html`
- Single-page admin dashboard
- Firebase JS SDK (CDN)
- Shows all users table: email, name, device count, status, last login
- Click user → see all devices
- Block/unblock button per user
- Uses same Firestore project (clone app's Firebase)

---

## Verification Plan

### Automated Tests
- `flutter analyze` — zero errors

### Manual Verification
- Sign in with Gmail → device registered in Firestore
- Block user via admin dashboard → user sees blocked message
- Check device count updates correctly
