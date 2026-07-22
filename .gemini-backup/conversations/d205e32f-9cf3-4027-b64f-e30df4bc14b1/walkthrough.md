# Walkthrough — Target API 36 + Code Rename

## 1. Target API Updated to Android 16 (API 36)

Meets Google Play's **August 31, 2026** deadline.

| File | Change |
|---|---|
| [build.gradle (app)](file:///d:/bharatheeyamapp%20sample/android/app/build.gradle) | `compileSdk` 35→**36**, `targetSdk` set to **36** |
| [build.gradle (root)](file:///d:/bharatheeyamapp%20sample/android/build.gradle) | `afterEvaluate` block forces all plugins to SDK 36 |

---

## 2. Full "Premium/Subscription" Rename

Removed all "premium" and "subscription" terminology from Dart code to avoid any Google Play review concerns.

### Rename Mapping

| Old Name | New Name |
|---|---|
| `SubscriptionService` | `AppAccessService` |
| `subscription_service.dart` | `app_access_service.dart` |
| `manualPremium` (var) | `adminAccess` |
| `manualPremiumExpiry` (var) | `adminAccessExpiry` |
| `hasSubscription` (var) | `isActivated` |
| `hasAdFree` | `hasFullAccess` |
| `checkManualPremium()` | `checkAdminAccess()` |
| `_subStatusKey` | `_accessStatusKey` |

### Files Modified

| File | Changes |
|---|---|
| [app_access_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/app_access_service.dart) | **NEW** — renamed from `subscription_service.dart` |
| [main.dart](file:///d:/bharatheeyamapp%20sample/lib/main.dart) | Import + all references |
| [settings_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/settings_screen.dart) | Import + all references |
| [support_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/support_screen.dart) | Import + all references |
| [dashboard_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/dashboard_screen.dart) | Import + all references |
| [device_binding_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/device_binding_service.dart) | Import + all references |
| [offline_access_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/offline_access_service.dart) | Import + all references |
| `subscription_service.dart` | **DELETED** |

> [!IMPORTANT]
> **Firestore field names** (`manualPremium`, `manualPremiumExpiry` in `device_bindings` collection) are **unchanged** — only the Dart variable names were renamed. This preserves existing user data without requiring a migration.

## 3. Billing Library — Not Added

Per user confirmation, no Google Play Billing library was added. Access is controlled entirely via Firestore admin flags.

## Verification

| Check | Result |
|---|---|
| `flutter pub get` | ✅ Success |
| Old references remaining | ✅ Zero (`SubscriptionService`, `subscription_service` — none found) |
| `compileSdk` | 36 |
| `targetSdk` | 36 |
| Build | ⏳ Running... |
