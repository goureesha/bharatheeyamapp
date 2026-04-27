# Multi-Language Support: Tamil, Telugu, Malayalam, Hindi

Add 4 new languages to Bharatheeyam app alongside existing Kannada.

## Scope Analysis

**~2,115 lines** across **41 files** contain hardcoded Kannada text. These fall into 3 categories:

### Category 1: Astrological Terms (Transliteration)
Sanskrit-origin terms that need **script transliteration** only (same word, different script):
- **Rashi** names: ಮೇಷ → மேஷம் / మేషం / മേഷം / मेष
- **Nakshatra**, **Tithi**, **Yoga**, **Karana**, **Vara** names
- **Planet** names: ರವಿ, ಚಂದ್ರ, ಕುಜ etc.
- **Dasha** lords, **Sphuta** names
- **Bhava** names, **Varga** names

These are ~150 unique terms already partially done for Hindi in `strings.dart`.

### Category 2: UI Labels & Messages
Button labels, headers, error messages, tooltips etc:
- `'ಲೆಕ್ಕ ಹಾಕಿ'` (Calculate), `'ಉಳಿಸಿ'` (Save), `'ಅಳಿಸಿ'` (Delete)
- Dashboard tab names, section headers
- Error/success snackbar messages

These are ~100 unique UI strings, partially in `AppLocale._strings`.

### Category 3: Domain Content (Hardcoded)
Large blocks of Kannada content embedded directly in code:
- **muhurta_rules.dart** (380 lines) — Muhurta rule descriptions
- **events.dart** (346 lines) — Festival/event names
- **places.dart** (180 lines) — Place names (may stay as-is)
- **ashtamangala_screen.dart** (224 lines) — Ashtamangala interpretations
- **calculator.dart** (94 lines) — Yoga descriptions, Sphuta labels
- **taranukoola_screen.dart** (100 lines) — Taranukula descriptions

> [!IMPORTANT]
> Category 3 is the largest by volume but lowest priority. These can be translated gradually over time. **Category 1 + 2 should be done first** to make the app functionally usable in all languages.

## Proposed Changes

### Phase 1: Infrastructure (do first)

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)
- Upgrade `AppLocale` to support 5 languages: `kn`, `hi`, `ta`, `te`, `ml`
- Make `current`, `isHindi` dynamic (currently hardcoded to `kn`)
- Add `isTamil`, `isTelugu`, `isMalayalam` getters
- Add `l(key)` lookup that falls back: selected lang → Kannada → key
- Persist language choice to `SharedPreferences`

#### [MODIFY] [strings.dart](file:///d:/bharatheeyamapp%20sample/lib/constants/strings.dart)
- Add `taRashi`, `teRashi`, `mlRashi` (Tamil, Telugu, Malayalam Rashi names)
- Same for Nakshatra, Tithi, Yoga, Karana, Vara, Planet names, Dasha lords, Sphutas
- Update dynamic getters (`appRashi`, `appNak`, etc.) to return correct language list
- Add `planetOrder` for each language

#### [NEW] [ui_strings.dart](file:///d:/bharatheeyamapp%20sample/lib/constants/ui_strings.dart)
- Centralized map of all UI label translations: `Map<String, Map<String, String>>`
- Keys: `'kn'`, `'hi'`, `'ta'`, `'te'`, `'ml'`
- ~100 entries covering all button labels, headers, messages

---

### Phase 2: Settings UI

#### [MODIFY] [settings_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/settings_screen.dart)
- Replace the currently disabled language selector with a working 5-language picker
- Options: ಕನ್ನಡ | हिन्दी | தமிழ் | తెలుగు | മലയാളം
- On selection: call `AppLocale.setLang(code)` → rebuild app

---

### Phase 3: Screen-by-screen hardcoded string replacement
Replace hardcoded Kannada strings with `AppLocale.l('key')` calls across all screens.

Files ordered by impact:
1. `dashboard_screen.dart` (250 lines)
2. `input_screen.dart` (25 lines)
3. `home_screen.dart` (10 lines)
4. `panchanga_screen.dart` (73 lines)
5. `settings_screen.dart` (70 lines)
6. `about_screen.dart` (45 lines)
7. All remaining screens

> [!WARNING]
> **Category 3 content** (muhurta_rules, events, ashtamangala) will remain Kannada-only initially. Translating 900+ lines of domain-specific astrological content requires careful manual review and is best done iteratively.

## Open Questions

1. **Font support**: Tamil (தமிழ்), Telugu (తెలుగు), Malayalam (മലയാളം) need proper fonts. Should we bundle Google Noto fonts for each script, or rely on system fonts?

2. **Places**: The `places.dart` file has 180 place names in Kannada. Should these be translated or kept as-is (since they're proper nouns)?

3. **Priority order**: Which language should we implement first after the infrastructure? Suggested: **Hindi** (already partially done) → **Telugu** → **Tamil** → **Malayalam**

4. **PDF Patrike**: The Janma Patrike PDF service also has Kannada text. Should that also be multi-language?

## Verification Plan

### Automated Tests
- Build the app after each phase to verify no compile errors
- Test language switching in settings

### Manual Verification
- Switch language and verify all screens show correct translations
- Verify astrological terms are correctly transliterated
- Test that saved profiles still work across language switches
