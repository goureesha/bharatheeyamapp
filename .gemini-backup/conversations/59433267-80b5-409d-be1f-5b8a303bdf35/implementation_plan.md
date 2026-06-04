# Block/Unblock Mechanism — Safe Implementation

Add an admin-controlled block/unblock system that **won't cause app hangs**.

## Why It Hung Before

The previous implementation likely hung because:
1. **Firestore calls without timeouts** — `TesterService`, `DeviceBindingService` writes have NO timeout guards
2. **Blocking the UI thread** — `SubscriptionService.initialize()` runs BEFORE `runApp()`, so any slow/stuck Firestore call freezes the splash screen indefinitely
3. **No fail-safe defaults** — if Firestore is unreachable, the app waits forever instead of falling back

## Anti-Hang Strategy

| Protection | How |
|-----------|-----|
| **All Firestore reads have timeouts** | Already 8s timeout in `checkManualPremium()` — we piggyback on this |
| **Fail-OPEN for block check** | If Firestore is unreachable, default to **NOT blocked** (user keeps working offline) |
| **Cache locally** | Store last known block status in SharedPreferences — only update when Firestore is reachable |
| **Never add new awaits before runApp** | Block check runs AFTER first frame, not during splash |
| **Block enforcement is UI-only** | Show a blocking screen overlay — no synchronous network call needed |

## Proposed Changes

### 1. Firestore Document

No new collection needed. Add a `blocked` boolean field to the existing `device_bindings/{email}` document:

```
device_bindings/{email} {
  deviceId: "...",
  manualPremium: true/false,
  manualPremiumExpiry: Timestamp,
  blocked: true/false,        // ← NEW
  blockedReason: "..."        // ← NEW (optional message to show user)
}
```

---

### 2. SubscriptionService Changes

#### [MODIFY] [subscription_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/subscription_service.dart)

- Add `static bool isBlocked = false;` and `static String blockedReason = '';`
- In `checkManualPremium()` (which already reads `device_bindings/{email}` with 8s timeout):
  - Read `blocked` and `blockedReason` fields from the same document
  - Cache to SharedPreferences
  - If Firestore fails → fall back to cached value (default: not blocked)
- In `hasAccess` getter: add `if (isBlocked) return false;` at the top

---

### 3. Main.dart Screen Gate

#### [MODIFY] [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart)

- Add a `_BlockedScreen` widget showing the block reason with a "Retry" button
- In screen selection logic (line ~344), add blocked check:
  ```dart
  home: SubscriptionService.isBlocked
      ? _BlockedScreen()
      : !GoogleAuthService.isSignedIn && !kIsWeb
          ? ...existing logic...
  ```
- On app resume (`_verifyAccessOnResume`): also refresh block status

---

### 4. Admin Script Update

#### [MODIFY] [unlock_user.py](file:///d:/bharatheeyamapp%20sample/unlock_user.py)

- Add `--block` and `--unblock` flags alongside existing `--premium` functionality

---

## Open Questions

> [!IMPORTANT]
> **What should happen when a blocked user opens the app offline?**
> - Option A: Show blocked screen (using cached status) — stricter but could lock out user who was blocked by mistake
> - Option B: Allow offline access, only enforce block when online — more forgiving
> 
> Current plan: **Option A** — use cached status, but with a "Contact Support" button

> [!IMPORTANT]
> **Should blocked users still see the app UI behind the block screen, or a completely separate screen?**
> Current plan: Full-screen replacement (like `_DeviceMismatchScreen`)

## Verification Plan

### Manual Verification
1. Set `blocked: true` in Firestore → app shows blocked screen
2. Set `blocked: false` → app resumes normally
3. Kill internet → app uses cached status, no hang
4. Slow network → app loads within 8s timeout, no hang
5. Test `unlock_user.py --block` and `--unblock` commands
