# Firebase Backend + Admin Panel — Task Tracker

## Phase 1: Firebase Setup + Firestore

### Firebase Infrastructure
- [x] Create `firestore.rules` — security rules
- [x] Create `firebase.json` — project config + `.firebaserc`
- [x] Create `firestore.indexes.json` — indexes file

### Flutter Firebase Integration
- [x] Update `pubspec.yaml` — add Firebase dependencies
- [x] Update `android/settings.gradle` — add Google Services plugin v4.4.2
- [x] Update `android/app/build.gradle` — apply Google Services plugin
- [x] Update `lib/models/shloka.dart` — add `isPremium`, `order`, `fromFirestore()`, `toFirestore()`
- [x] Create `lib/services/firebase_service.dart` — Firestore CRUD + caching + offline fallback
- [x] Update `lib/main.dart` — initialize Firebase + MultiProvider
- [x] Confirm `google-services.json` is placed ✅

### GitHub Actions
- [x] Build workflow already configured — push triggered new build

## Phase 2: Web Admin Panel

### Admin Panel Files
- [x] Create `admin/index.html` — main admin SPA
- [x] Create `admin/css/styles.css` — premium dark theme
- [x] Create `admin/js/app.js` — admin panel logic (auth, CRUD, routing, seed data)

### Admin Features (all built into app.js)
- [x] Admin login screen (Firebase Auth)
- [x] Dashboard with stats (books, chapters, shlokas, categories counts)
- [x] Book list with filters
- [x] Add/Edit book form (Kannada, Sanskrit, English titles, category, subcategory, god tags, premium toggle)
- [x] Add/Edit chapter form (modal)
- [x] Add/Edit shloka form (Sanskrit, Kannada, meaning, explanation textareas, premium toggle)
- [x] Premium toggle on books/shlokas
- [x] Seed existing data to Firestore (all 9 books, 12 chapters, 41 shlokas)

## User Actions Required
- [ ] Run `firebase login` in terminal (interactive — opens browser)
- [ ] Run `firebase deploy` to deploy admin panel + Firestore rules
- [ ] Create admin user in Firebase Console → Authentication → Add User
- [ ] Log into admin panel and click "Seed Data" to populate Firestore

## Verification
- [ ] Admin panel loads and authenticates
- [ ] Seed data populates Firestore
- [ ] Can add new stotra from admin panel
- [ ] Flutter app builds with Firebase
- [ ] App loads content from Firestore
