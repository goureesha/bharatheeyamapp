# Stotra Integration Tasks

- [x] **Phase 1: Data Preparation**
  - [x] Generate stotra_data.json (4,257 stotras, 32 MB)
  - [x] Copy brhknd.ttf, brhknde.ttf fonts to assets/fonts/
  - [x] Update pubspec.yaml (fonts, assets, removed Firebase)

- [x] **Phase 2: Models & Services**
  - [x] New Stotra model (removed sanskrit, meaning, explanation)
  - [x] StotraService to load/serve data from JSON
  - [x] Simplified BookmarkService (no Firebase)
  - [x] Cleaned up old files (shloka.dart, firebase_service, content_data)

- [x] **Phase 3: Screens & Widgets**
  - [x] NudiText widget for Nudi font rendering
  - [x] HomeScreen with 8 deity categories + Extras button
  - [x] CategoryScreen (stotra title list with search)
  - [x] ExtrasScreen (47 extra categories grid)
  - [x] ReaderScreen (full text with zoom, bookmark)
  - [x] BookmarksScreen (saved stotras)
  - [x] SettingsScreen (dark mode, font size, clear)
  - [x] SearchScreen (search across all stotras)

- [ ] **Phase 4: Verify**
  - [ ] Install Flutter SDK
  - [ ] Run flutter pub get
  - [ ] Run flutter build apk
  - [ ] Test on device
