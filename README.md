# ಭಾರತೀಯಮ್ — Vedic Astrology Flutter App

A complete offline Vedic Astrology (Jyotish) Android app in **Flutter/Dart**.  
All calculations are done in pure Dart (no internet needed after install).

---

## 📱 Features

- **ಕುಂಡಲಿ** — 4×4 South-Indian chart with D1/D2/D3/D9/D12/D30/Bhava/Navamsa
- **ಗ್ರಹ ಸ್ಫುಟ** — Planet positions with Nakshatra & Pada
- **ಉಪಗ್ರಹ ಸ್ಫುಟ** — 16 advanced sphutas (Dhooma, Vyatipata, Beeja, etc.)
- **ಆರೂಢ** — Manual Aroodha chart builder
- **ದಶ** — Vimshottari Mahadasha → Antardasha → Pratyantardasha with dates
- **ಪಂಚಾಂಗ** — Tithi, Nakshatra, Yoga, Karana, Vara, Ghati
- **ಭಾವ** — All 12 Bhava cusps (Placidus)
- **ಅಷ್ಟಕವರ್ಗ** — SAV grid + BAV table for all 7 planets
- **ಟಿಪ್ಪಣಿ** — Notes per chart
- Save/load multiple birth profiles offline

---

## 🚀 Get the APK (No setup needed — uses GitHub to build)

### Step 1 — Push this code to GitHub

1. Create a **free GitHub account** at https://github.com if you don't have one
2. Create a new **public repository** named `bharatheeyam`
3. Upload all these files to that repo (drag-drop in browser OR use GitHub Desktop)

### Step 2 — Enable GitHub Actions

- Go to your repo → **Actions** tab → Click **"I understand my workflows, go ahead and enable them"**

### Step 3 — Trigger the build

- Make any small edit (e.g., add a space in README.md) and commit it
- OR go to **Actions → "Build APK & Flutter Web" → Run workflow**

### Step 4 — Download APK

- Go to **Actions** → Click the latest workflow run
- Scroll to **Artifacts** → Download **`bharatheeyam-apk`**
- Unzip it — you'll find 3 APKs (arm64 is best for modern phones)
- Transfer to phone and install!

### Step 5 — Live Web Preview

- After the first successful build, go to:  
  `https://YOUR-USERNAME.github.io/bharatheeyam/`
- This is your **live browser preview** of the app!

---

## 🔧 Local Build (if you install Flutter later)

```bash
flutter pub get
flutter run          # for device/emulator
flutter build apk    # for APK
```

---

## 📐 Calculation Engine

Pure Dart implementation of:
- **Jean Meeus Astronomical Algorithms** (2nd Edition)
- Planetary positions: VSOP87 (truncated, ~1' accuracy)
- Ayanamsa: Lahiri / B.V. Raman / Krishnamurti (KP)
- Rahu: True Node / Mean Node
- Houses: Placidus
- Sunrise/Sunset: iterative binary search on altitude
- Mandi: Classic Vedic formula (weekday factors)

No C libraries, no `.se1` data files — fully self-contained.

---

## 📁 Project Structure

```
lib/
  main.dart                    # App entry
  constants/strings.dart       # All Kannada strings
  core/
    ephemeris.dart             # Astronomical engine
    calculator.dart            # Full Vedic calculation logic
  screens/
    input_screen.dart          # Birth data input
    dashboard_screen.dart      # 11-tab dashboard
  widgets/
    common.dart                # Shared UI components
    kundali_chart.dart         # 4x4 Kundali grid
    dasha_widget.dart          # Expandable Dasha tree
    ashtakavarga_widget.dart   # SAV/BAV display
    planet_detail_sheet.dart   # Planet detail popup
  services/
    storage_service.dart       # Local JSON storage
```
