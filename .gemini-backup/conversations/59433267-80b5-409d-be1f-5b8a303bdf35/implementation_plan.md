# Move Google Login from Startup to Kundali & Taranukoola

Remove the login gate at app startup. Users open the app and land directly on HomeScreen. Google login is triggered only when needed — inside specific sections.

## Proposed Changes

### 1. Main Gate — Remove Login & Internet Checks

#### [MODIFY] [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart)

**Current gate flow** (line 382-388):
```
Not signed in → _OfflineVerifyScreen → _GmailRequiredScreen
Wrong device → _DeviceMismatchScreen
Needs internet → _InternetRequiredScreen  
Has access → HomeScreen
No access → SupportScreen
```

**New gate flow:**
```
Always → HomeScreen
```

Changes:
- Remove `_OfflineVerifyScreen`, `_InternetRequiredScreen` from the gate
- Keep `_GmailRequiredScreen` as a reusable widget (called from Kundali/Taranukoola)
- Remove `_verifyAccessOnResume()` internet checks
- Remove `needsInternetVerification` checks
- Keep device binding check but make it non-blocking

---

### 2. Kundali Section — Login on Calculate

#### [MODIFY] [input_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/input_screen.dart)

In `_calculate()` method (line 311):
- Before doing the calculation, check `GoogleAuthService.isSignedIn`
- If NOT signed in → show Google sign-in popup
- If sign-in succeeds → continue with calculation
- If sign-in fails/cancelled → show error, don't calculate

---

### 3. Taranukoola Section — Login on First Open

#### [MODIFY] [taranukoola_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/taranukoola_screen.dart)

In `initState()` or `build()`:
- Check `GoogleAuthService.isSignedIn`
- If NOT signed in → show login overlay/page
- If signed in → show normal Taranukoola content
- Once logged in, screen rebuilds and shows content

---

### 4. Remove Internet Checks

#### [MODIFY] [subscription_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/subscription_service.dart)

- Remove `needsInternetVerification` getter (or make it always return `false`)
- Simplify `hasAccess` — remove internet check dependency

#### [MODIFY] [network_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/network_service.dart)

- Keep the file but it won't be called from any gate flow

---

### 5. Optimize Startup (Fix Hanging)

#### [MODIFY] [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart)

- Move FCM `NotificationService.init()` to after user signs in (not at startup)
- Don't call `_initAuthAndBinding()` at startup if not signed in — defer it
- Remove `FirebaseMessaging.onBackgroundMessage` from startup if user never signed in

---

## Summary

| Screen | Before | After |
|---|---|---|
| App opens | Login gate → Gmail required | **HomeScreen directly** |
| Kundali → Calculate | Calculates immediately | **Login if not signed in → then calculate** |
| Taranukoola → Open | Opens immediately | **Login if not signed in → then show content** |
| Internet check | Multiple checks, blocks user | **No checks at all** |
| Startup speed | Slow (FCM + Firestore + ping) | **Fast (skip all if not signed in)** |

## Verification Plan

### Manual Verification
- Install APK → app opens to HomeScreen immediately (no login)
- Go to Kundali → fill inputs → click Calculate → login popup appears
- After login → calculation proceeds
- Go to Taranukoola → login page appears (if not logged in)
- After login → Taranukoola shows content
- Close and reopen app → no login prompts anywhere
