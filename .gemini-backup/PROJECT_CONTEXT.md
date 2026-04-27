# Bharatheeyam App — Project Context & Setup Guide

> This document captures all project context, setup details, and architecture decisions
> so development can resume on any machine.

## 🔧 Environment & Setup

### Prerequisites
- **Flutter SDK** (stable channel)
- **Android Studio** with Android SDK
- **Java JDK 17** (for Android builds)
- **Git** for version control
- **Gemini Antigravity** IDE for AI-assisted development

### Key Dependencies
| Package | Purpose |
|---|---|
| `sweph` | Swiss Ephemeris for planetary calculations |
| `pdf` + `printing` | PDF generation (PdfService) |
| `screenshot` | Widget-to-image for Janma Patrike PDF |
| `firebase_core` + `cloud_firestore` | Device binding, tester service |
| `google_sign_in` | Authentication |
| `shared_preferences` | Local storage |
| `in_app_purchase` | Subscription management |
| `flutter_localizations` | Multi-language support |

### Build & Run
```bash
flutter pub get
flutter run                    # Debug on connected device
flutter build appbundle        # Release AAB for Play Store
```

### CI/CD
- **GitHub Actions** pipeline at `.github/workflows/`
- Triggers on push to `main`
- Builds Android AAB automatically

---

## 🏗️ Architecture

### Core Engine (`lib/core/`)
- **`calculator.dart`** — Main astrological calculation engine (Kundali, Panchanga, Planets, Dasha)
  - Uses Swiss Ephemeris via `sweph` package
  - Internal keys are in **Kannada** (engine language)
  - UI layer translates via `AppLocale.l()` and `trAll()`
- **`ephemeris.dart`** — Sweph initialization and ephemeris file loading
- **`transit_calculator.dart`** — Planetary transit calculations
- **`events.dart`** — Festival/event calendar (600+ lines, all 12 months)

### Services (`lib/services/`)
| Service | Purpose |
|---|---|
| `janma_patrike_service.dart` | Birth chart PDF generation (screenshot-based) |
| `pdf_service.dart` | Kundali PDF generation (pdf package) |
| `device_binding_service.dart` | One-Gmail-one-phone enforcement via Firestore |
| `google_auth_service.dart` | Google Sign-In wrapper |
| `subscription_service.dart` | In-app purchase + trial management |
| `trusted_time_service.dart` | NTP-based tamper-proof time |
| `install_checker.dart` | Play Store sideload detection |
| `tester_service.dart` | Beta tester detection via Firestore |
| `firebase_service.dart` | Firebase init + appointment listener |
| `storage_service.dart` | Local data persistence |
| `festival_cache_service.dart` | Cached festival events |
| `location_service.dart` | GPS/location services |

### UI (`lib/screens/` + `lib/widgets/`)
- **`common.dart`** — Central locale dictionary (2000+ lines), theme system, shared widgets
  - `AppLocale` class with 5 languages: Kannada (kn), Hindi (hi), Tamil (ta), Telugu (te), Malayalam (ml)
  - `AppThemes` for light/dark mode
  - `ChartStyle` for North/South Indian chart styles
- **Screens**: home, input, dashboard, panchanga, about, paywall, settings

### Localization Architecture
- **Engine keys**: Always Kannada (internal lookup)
- **UI display**: `AppLocale.l('key')` for static text
- **Engine values**: `trAll(value)` to translate Rashi/Nakshatra/Planet names
- **PDF fonts**: Bundled Noto Sans for 5 scripts in `assets/fonts/`
  - Dynamic font selection via `_fontForLocale()` in janma_patrike_service

---

## 🔑 Key Design Decisions

### Device Binding (Security)
- **Fail-closed**: Default blocked until Firestore confirms
- **Firestore is sole truth**: `device_bindings/{email}` → `deviceId`
- **7-day offline grace**: Cached local verification expires after 7 days
- **v39 auto-migrate**: One-time rebind on app update to handle reinstalls

### Adhika/Nija Masa Calculation
- Uses `prevAmaRashi` for month naming (DO NOT CHANGE — this is the working version)
- Adhika: No Sankranti between Amavasyas → `adhikaPrefix + masaName`
- Nija: Has Sankranti → `nijaPrefix + masaName`
- Events are skipped during Adhika Masa (`events.dart` line 27)

### Subscription
- 3-day free trial
- ₹700/year subscription via Google Play
- Needs internet verification every 2 days
- Paywall shows 4 benefits (Kundali, Panchanga, Match Making, Data Backup)

### Font Bundling
- 10 TTF files in `assets/fonts/` (Regular + Bold × 5 languages)
- Registered in `pubspec.yaml` as separate font families
- `_fontForLocale()` switches based on `AppLocale.current`

---

## 📁 Important File Paths

| File | What it contains |
|---|---|
| `lib/core/calculator.dart` | Core astro engine (~1070 lines) |
| `lib/widgets/common.dart` | Locale dictionary + theme (~2100 lines) |
| `lib/services/janma_patrike_service.dart` | Birth chart PDF (~900 lines) |
| `lib/main.dart` | App entry, auth flow, blocked screens |
| `lib/core/events.dart` | Festival calendar (~613 lines) |
| `pubspec.yaml` | Dependencies + asset registration |
| `android/app/build.gradle` | Android build config |

---

## 📋 Pending / Future Work

### Not Yet Localized
- `muhurta_rules.dart` — Dosha labels and verdicts
- Ashtamangala screen
- About screen
- `pdf_service.dart` — Needs bundled TTF font loading for Indic scripts

### Known Constraints
- `_shortNames` map in janma_patrike uses `AppLocale.l()` keys but engine lookups (e.g., `planets['ಲಗ್ನ']`) must stay in Kannada
- Adding new languages requires: font TTF → `assets/fonts/`, register in `pubspec.yaml`, add to `_fontForLocale()` switch, add locale entries in `common.dart`

---

## 🗂️ Conversation IDs (for reference)

| ID | Topic |
|---|---|
| `defe206f` | Multi-language localization (main session) |
| `59433267` | PDF localization + font bundling + device binding |
| `9f1a2329` | Cloud sync removal |
| `2432016c` | Reverting to stable build |
| `5afa16ff` | Security hardening + CI/CD |
| `23d4e095` | Books app / Muhurta Chintamani |

---

*Last updated: 2026-04-27*
