# Add Google Play Billing & Update Target API to 36

Your app currently has **no Google Play Billing integration** — the subscription is managed entirely via Firestore (`manualPremium` flag set by admin). This plan adds the official Flutter `in_app_purchase` plugin and updates the Android target to API 36 (Android 16).

## User Review Required

> [!IMPORTANT]
> Your current `SubscriptionService` is **Firestore-only** (admin manually grants premium). Adding Google Play Billing means users can purchase subscriptions directly through the Play Store. The existing Firestore-based premium will continue to work alongside Play Store purchases.

> [!WARNING]
> **Google Play deadline**: By **August 31, 2026**, all app updates must target **API 36**. Your current `compileSdk = 35` and `targetSdk = flutter.targetSdkVersion` need to be updated.

## Open Questions

> [!IMPORTANT]
> 1. **What products do you want to sell?** Do you want a monthly subscription, yearly subscription, one-time purchase, or a combination? I need the **product IDs** you've configured (or will configure) in the Google Play Console.
> 2. **Should Play Store purchases replace the Firestore manual premium**, or should both coexist (i.e., admin can still grant free premium via Firestore, AND users can buy via Play Store)?
> 3. **Do you want to keep the 30-minute trial** as-is, or should it change now that billing is being added?

## Current State

| Setting | Current Value | Target Value |
|---|---|---|
| `compileSdk` | 35 | **36** |
| `targetSdk` | `flutter.targetSdkVersion` | **36** (explicit) |
| AGP | 8.7.3 | 8.7.3 (compatible with SDK 36) |
| Gradle | 8.9 | 8.9 (no change needed) |
| Kotlin | 2.0.0 | 2.0.0 (no change needed) |
| Billing plugin | ❌ None | **`in_app_purchase: ^3.3.0`** |
| Billing Library (native) | ❌ None | **Play Billing 7+** (bundled with plugin) |

---

## Proposed Changes

### 1. Android Build Configuration

#### [MODIFY] [build.gradle](file:///d:/bharatheeyamapp%20sample/android/app/build.gradle)
- Update `compileSdk` from `35` → `36`
- Set `targetSdk = 36` explicitly (instead of relying on `flutter.targetSdkVersion`)

#### [MODIFY] [build.gradle (root)](file:///d:/bharatheeyamapp%20sample/android/build.gradle)
- Add `afterEvaluate` block to force all subprojects/plugins to compile against SDK 36 (prevents build failures from plugins still targeting SDK 35)

---

### 2. Flutter Dependencies

#### [MODIFY] [pubspec.yaml](file:///d:/bharatheeyamapp%20sample/pubspec.yaml)
- Add `in_app_purchase: ^3.3.0` to dependencies (the official Flutter plugin that wraps Google Play Billing Library 7+)

---

### 3. New Billing Service

#### [NEW] billing_service.dart (`lib/services/billing_service.dart`)
- Initialize `InAppPurchase` instance
- Define product IDs (subscription/one-time)
- Query available products from Play Store
- Handle purchase flow (buy, restore, verify)
- Listen to purchase stream and acknowledge purchases
- Integrate with existing `SubscriptionService` (set `hasSubscription = true` on valid purchase)

---

### 4. Update Subscription Service

#### [MODIFY] [subscription_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/subscription_service.dart)
- In `initialize()`: also call `BillingService.initialize()` to check for existing purchases
- Update `hasAccess` getter to also check Play Store subscription status
- Keep Firestore manual premium as a parallel path

---

### 5. UI Integration

#### [MODIFY] [settings_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/settings_screen.dart)
- Add "Subscribe" / "Restore Purchases" buttons in the subscription section
- Show current subscription status from Play Store

---

## Verification Plan

### Automated Tests
```bash
flutter pub get
flutter analyze
flutter build appbundle --release
```

### Manual Verification
- Verify `compileSdk 36` and `targetSdk 36` in the built APK/AAB manifest
- Verify `in_app_purchase` plugin resolves correctly
- Test billing flow with Play Console test tracks (requires Play Console product setup)
