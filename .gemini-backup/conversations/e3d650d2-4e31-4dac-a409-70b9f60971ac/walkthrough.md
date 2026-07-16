# Bharatiyam Panchanga — Build Walkthrough

## ✅ Project Complete — 31 Files Created

### Project Structure

```
d:\bharatiyam calender\
├── pubspec.yaml                          # Dependencies & config
├── analysis_options.yaml                 # Lint rules
├── .gitignore                            # Git exclusions
├── .github/workflows/build.yml           # CI/CD (APK + Web)
│
├── lib/
│   ├── main.dart                         # App entry point
│   │
│   ├── core/                             # 🔬 Calculation Engines (10 files)
│   │   ├── ephemeris.dart                # Swiss Ephemeris wrapper
│   │   ├── panchanga_calculator.dart     # 5-limb calculator
│   │   ├── masa_calculator.dart          # 4 calendar systems
│   │   ├── samvatsara.dart              # 60-year cycle + Rutu + Ayana
│   │   ├── muhurta_calculator.dart       # 15+15 muhurtas + specials
│   │   ├── kala_calculator.dart          # Rahu/Yama/Gulika Kala
│   │   ├── hora_calculator.dart          # 12+12 planetary hours
│   │   ├── chougadiya_calculator.dart    # 8+8 Chougadiya periods
│   │   ├── lagna_calculator.dart         # 12-rashi transit timings
│   │   └── ghati_calculator.dart         # Visha/Amruta Ghati
│   │
│   ├── models/
│   │   └── panchanga_data.dart           # All data model classes
│   │
│   ├── i18n/                             # 🌐 7 Languages
│   │   ├── app_locale.dart               # Language manager
│   │   └── strings/
│   │       ├── kn.dart                   # Kannada (primary, full)
│   │       ├── en.dart                   # English (full)
│   │       ├── hi.dart                   # Hindi (full)
│   │       ├── ta.dart                   # Tamil (essentials)
│   │       ├── te.dart                   # Telugu (essentials)
│   │       ├── ml.dart                   # Malayalam (essentials)
│   │       └── sa.dart                   # Sanskrit (essentials)
│   │
│   ├── constants/
│   │   └── places.dart                   # 45 Indian cities database
│   │
│   ├── services/
│   │   ├── location_service.dart         # GPS + city selector
│   │   └── export_service.dart           # PDF + Image export
│   │
│   ├── screens/                          # 📱 UI Screens
│   │   ├── home_screen.dart              # Main screen with summary
│   │   ├── panchanga_screen.dart         # Detail with 4 tabs
│   │   └── settings_screen.dart          # Language + Location
│   │
│   └── widgets/
│       └── common.dart                   # Design system + reusable widgets
```

---

## Features Implemented

### 🔬 Astronomical Calculations
- **Swiss Ephemeris** (`sweph` package) for planetary positions
- **Lahiri Ayanamsha** (default, with Raman/KP options)
- **Mid-limb sunrise** (-0.5667° horizon with atmospheric refraction)
- **Binary search** for all transition times (20-iteration precision)

### 📅 5 Panchanga Limbs
| Limb | Calculation | Extra |
|------|-------------|-------|
| **Tithi** | (Moon-Sun)/12° | End time, Gata/Shesha/Parama ghati |
| **Nakshatra** | Moon/13.333° | Pada, End time, ghati details |
| **Yoga** | (Moon+Sun)/13.333° | End time, ghati details |
| **Karana** | (Moon-Sun)/6° | End time, ghati details |
| **Vara** | Weekday at sunrise | Vedic convention (Sun=0) |

### 📆 4 Calendar Systems
- **Amanta** — New Moon to New Moon
- **Pournimanta** — Full Moon to Full Moon (full calculation)
- **Chandra Mana** — Combined lunar month + paksha
- **Soura Mana** — Solar month (Sankranti-based) + Gata Dina

### ⏰ Timing Systems
- **15 Day Muhurtas** — Sunrise to Sunset / 15
- **15 Night Muhurtas** — Sunset to Next Sunrise / 15
- **Rahu Kala / Yamaganda / Gulika Kala** — Daytime / 8 muhurtas
- **12+12 Hora** — Planetary hours (day + night)
- **8+8 Chougadiya** — Gauri Panchanga periods
- **12-Rashi Lagna Transit** — Full day + night ascendant timings
- **Abhijit Muhurta** — Midday ± half muhurta
- **Durmuhurta** — Weekday-specific inauspicious periods
- **Varjyam** — Nakshatra-specific avoidance window
- **Amrita Siddhi Yoga** — Vara + Nakshatra combos

### 🌐 Multi-Language
- Kannada (ಕನ್ನಡ) — Primary, complete
- Hindi (हिन्दी) — Complete
- English — Complete
- Tamil (தமிழ்) — Essential terms
- Telugu (తెలుగు) — Essential terms
- Malayalam (മലയാളം) — Essential terms
- Sanskrit (संस्कृतम्) — Essential terms

### 📍 Location
- GPS auto-detect with nearest-city matching
- 45 Indian cities database (Karnataka focus)
- City search by name/state
- Persistent location preference

### 📤 Export
- PDF export with share
- Image screenshot export

### 🎨 Premium UI
- Dark mode with deep purple/indigo gradient
- Gold accent system
- Glassmorphism cards
- Responsive layout (mobile + web)

---

## How to Build

### GitHub Actions (Recommended)
1. Push this code to a GitHub repo (e.g., `bharatiyam-panchanga`)
2. Go to **Actions** tab → **Build APK & Flutter Web**
3. Click **Run workflow**
4. Download APK from artifacts
5. Web auto-deploys to GitHub Pages

### The workflow will:
- Auto-generate Android/Web platform files via `flutter create`
- Add location permissions to AndroidManifest
- Build split APKs (arm64, armeabi, x86_64)
- Build web with base-href for GitHub Pages
- Deploy web to `gh-pages` branch

---

## Date Range
- Supported: **1900 CE — 2100 CE**
- Swiss Ephemeris data files cover this range

## Known Limitations
- Tamil, Telugu, Malayalam, Sanskrit have essential terms only (nakshatras, varas, rashis). Missing keys fall back to Kannada.
- Custom fonts (NotoSansKannada) removed from pubspec to avoid build errors — uses system fonts.
- First load may take 1-2 seconds for Swiss Ephemeris initialization.
