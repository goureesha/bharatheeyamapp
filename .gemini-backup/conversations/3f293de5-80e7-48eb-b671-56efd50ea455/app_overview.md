# ಭಾರತೀಯಮ್ (Bharatheeyam) V2 — App Overview

## What is this app?
A **professional Vedic Astrology (Jyotish)** application built with Flutter. It's a full-featured tool for astrologers to compute horoscopes, manage clients/appointments, and generate reports — all in Kannada + English.

**Package:** `com.bharatheeyam.v2` | **Platforms:** Android + Web

---

## 🏠 App Structure (10 Screens)

| Screen | File | Purpose |
|--------|------|---------|
| **Home** | [home_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/home_screen.dart) | Grid menu with all sections |
| **Kundali** | [input_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/input_screen.dart) → [dashboard_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/dashboard_screen.dart) | Birth chart input → Full horoscope dashboard (141KB — largest screen!) |
| **Panchanga** | [panchanga_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/panchanga_screen.dart) | Daily Hindu calendar/almanac |
| **Taranukoola** | [taranukoola_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/taranukoola_screen.dart) | Star compatibility/auspicious timing |
| **Match Making** | [match_making_tab.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/match_making_tab.dart) | Marriage compatibility (Guna Milan) |
| **Planets** | [planets_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/planets_screen.dart) | Current planetary positions |
| **Vedic Clock** | [vedic_clock_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/vedic_clock_screen.dart) | Traditional time system (Ghati/Pala) |
| **Appointments** | [appointment_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/appointment_screen.dart) | Client booking + Google Calendar 2-way sync |
| **Prashna** | [prashna_input_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/prashna_input_screen.dart) → [prashna_dashboard_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/prashna_dashboard_screen.dart) | Horary astrology (question-based prediction) |
| **Ashtamangala** | [ashtamangala_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/ashtamangala_screen.dart) | Tester-only: traditional divination method |
| **Settings** | [settings_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/settings_screen.dart) | Theme, language, sign-in, backup |
| **About** | [about_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/about_screen.dart) | App info, privacy policy |

---

## 🧮 Core Computation Engine (`lib/core/`)

| File | Size | Purpose |
|------|------|---------|
| [calculator.dart](file:///d:/bharatheeyamapp%20clone/lib/core/calculator.dart) | 45KB | **Main astrology engine** — planetary positions, house calculations, Rashi, Nakshatra |
| [ephemeris.dart](file:///d:/bharatheeyamapp%20clone/lib/core/ephemeris.dart) | 10KB | Swiss Ephemeris (Sweph) wrapper for accurate planetary positions |
| [events.dart](file:///d:/bharatheeyamapp%20clone/lib/core/events.dart) | 63KB | Festival/event definitions and calculations |
| [muhurta_rules.dart](file:///d:/bharatheeyamapp%20clone/lib/core/muhurta_rules.dart) | 78KB | **Largest core file** — auspicious timing rules |
| [viyoni_janma.dart](file:///d:/bharatheeyamapp%20clone/lib/core/viyoni_janma.dart) | **198KB** | **Largest file in app** — Viyoni Janma calculations |
| [graha_phala.dart](file:///d:/bharatheeyamapp%20clone/lib/core/graha_phala.dart) | 23KB | Planetary effects/predictions |
| [ashtakavarga.dart](file:///d:/bharatheeyamapp%20clone/lib/core/ashtakavarga.dart) | 6KB | Ashtakavarga point system |
| [shadbala.dart](file:///d:/bharatheeyamapp%20clone/lib/core/shadbala.dart) | 7KB | Planetary strength calculations |
| [match_making.dart](file:///d:/bharatheeyamapp%20clone/lib/core/match_making.dart) | 7KB | Guna Milan marriage compatibility |
| [transit_calculator.dart](file:///d:/bharatheeyamapp%20clone/lib/core/transit_calculator.dart) | 8KB | Planetary transit analysis |

---

## 🔌 Services Layer (`lib/services/`)

### Authentication & Cloud
| Service | Purpose |
|---------|---------|
| [google_auth_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/google_auth_service.dart) | Google Sign-In (email + drive + calendar scopes) |
| [firebase_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/firebase_service.dart) | Firebase Firestore — listens for web appointment bookings |
| [tester_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/tester_service.dart) | Controls tester/beta features access |
| [device_binding_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/device_binding_service.dart) | Binds app to device (anti-piracy) |

### Data & Storage
| Service | Purpose |
|---------|---------|
| [appointment_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/appointment_service.dart) | CRUD for appointments (SharedPreferences + Google Sheets sync) |
| [client_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/client_service.dart) | Client/customer management |
| [storage_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/storage_service.dart) | Local profile/kundali storage |
| [history_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/history_service.dart) | Calculation history tracking |
| [festival_cache_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/festival_cache_service.dart) | Caches Hindu festival dates |

### Calendar & Sync
| Service | Purpose |
|---------|---------|
| [calendar_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/calendar_service.dart) | **Google Calendar 2-way sync** (NEW!) |
| [sheets_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/sheets_service.dart) | Google Sheets integration (stub) |
| [drive_backup_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/drive_backup_service.dart) | Google Drive app data backup |
| [backup_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/backup_service.dart) | Platform-aware backup routing |

### Output & Export
| Service | Purpose |
|---------|---------|
| [pdf_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/pdf_service.dart) | Generates PDF horoscope reports |
| [pdf_theme.dart](file:///d:/bharatheeyamapp%20clone/lib/services/pdf_theme.dart) | PDF styling/theming |
| [janma_patrike_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/janma_patrike_service.dart) | Birth chart (Janma Patrike) generation |
| [export_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/export_service.dart) | Platform-specific file export |
| [local_export_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/local_export_service.dart) | Local file saving |

### Utilities
| Service | Purpose |
|---------|---------|
| [location_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/location_service.dart) | GPS/location for birth place |
| [network_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/network_service.dart) | Network connectivity checks |
| [ad_service.dart](file:///d:/bharatheeyamapp%20clone/lib/services/ad_service.dart) | Google Mobile Ads |
| [install_checker.dart](file:///d:/bharatheeyamapp%20clone/lib/services/install_checker.dart) | Install source verification |

---

## 🎨 Widgets (`lib/widgets/`)

| Widget | Purpose |
|--------|---------|
| [kundali_chart.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/kundali_chart.dart) | South Indian horoscope chart drawing |
| [north_indian_chart.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/north_indian_chart.dart) | North Indian diamond chart drawing |
| [prashna_chart.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/prashna_chart.dart) | Horary astrology chart |
| [ashtakavarga_widget.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/ashtakavarga_widget.dart) | Ashtakavarga point display |
| [shadbala_widget.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/shadbala_widget.dart) | Planetary strength bars |
| [dasha_widget.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/dasha_widget.dart) | Dasha period timeline |
| [planet_detail_sheet.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/planet_detail_sheet.dart) | Planet info bottom sheet |
| [common.dart](file:///d:/bharatheeyamapp%20clone/lib/widgets/common.dart) | Theme colors, shared UI utilities, AppLocale (i18n) |

---

## 🌐 External Integrations

| Integration | What it does |
|-------------|--------------|
| **Google Sign-In** | User authentication |
| **Google Calendar API** | 2-way appointment sync to "ಭಾರತೀಯಮ್ Appointments" calendar |
| **Google Drive** | App data backup/restore |
| **Firebase Firestore** | Receives appointment requests from web booking form |
| **Swiss Ephemeris (Sweph)** | Accurate astronomical planetary positions |
| **Google Ads** | Monetization (AdMob) |
| **WhatsApp** | Send appointment confirmations via deep link |
| **PDF Generation** | Horoscope reports as shareable PDFs |

---

## 📊 App Stats

| Metric | Value |
|--------|-------|
| **Total Dart files** | 72 |
| **Total code size** | ~1.3 MB |
| **Largest file** | `viyoni_janma.dart` (198 KB) |
| **Largest screen** | `dashboard_screen.dart` (141 KB) |
| **Languages** | Kannada (primary) + English + Hindi |
| **Themes** | Light + Dark mode |

---

## 🏗️ Architecture Summary

```
User → HomeScreen (Grid Menu)
         ├── Kundali Flow: InputScreen → DashboardScreen (full horoscope)
         ├── Panchanga: Daily almanac
         ├── Taranukoola: Star compatibility
         ├── Match Making: Marriage compatibility
         ├── Planets: Live planetary positions
         ├── Vedic Clock: Traditional time
         ├── Appointments: Booking + Google Calendar sync
         ├── Prashna: Horary astrology
         └── Settings: Theme, language, backup, sign-in

Data Flow:
  Calculator (Sweph) → Screen → PDF Service → Export
  AppointmentService ↔ CalendarService ↔ Google Calendar API
  Firebase (web bookings) → AppointmentService → Local cache
  Google Drive ← DriveBackupService ← StorageService
```
