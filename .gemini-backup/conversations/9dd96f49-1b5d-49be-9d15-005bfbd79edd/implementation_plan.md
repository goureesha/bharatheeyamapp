# Integrate Stotras into Flutter App

Add all extracted stotras (4,911 with full text) to the Bharatiyam app, organized by deity categories with an Extras section. Remove Sanskrit text, meaning, and explanation fields.

## User Review Required

> [!IMPORTANT]
> **Font Rendering**: The stotras are in **Nudi encoding** (not Unicode Kannada). The app must bundle `brhknd.ttf` and `brhknde.ttf` fonts and render text using raw bytes. This is how the old app worked.

> [!IMPORTANT]
> **Data Size**: 22 MB of stotra text will be bundled as asset files in the APK. This will increase app size by ~22 MB. Is that acceptable, or should we use a compressed format?

> [!WARNING]
> **Categories to EXCLUDE**: Vratas and Puranas removed as requested. The following folders will be skipped:
> - Vishnu_Purana, Mangala_Vrata, Vastu, Amarakosha
> 
> Please confirm if any other categories should be excluded.

## Open Questions

1. **Devi category** — should this combine Parvati + Lakshmi + Saraswati + Durga into one "Devi" section, or keep them as sub-categories under Devi?
2. **Devaranama (1,064 stotras)** — this is a large category. Should it go in Extras or be a main category?
3. **Vedamantra (206 stotras)** — Main category or Extras?
4. **Ashtottara (314) & Sahasranama (74)** — Main or Extras?

## Proposed Changes

### App Structure

**Main Categories (Home Screen Grid):**
| # | Category | Folder Source | Stotras |
|---|----------|--------------|---------|
| 1 | ಶಿವ (Shiva) | Ishwara_ಈಶ್ವರ | 218 |
| 2 | ವಿಷ್ಣು (Vishnu) | Vishnu_ವಿಷ್ಣು | 189 |
| 3 | ದೇವಿ (Devi) | Parvati + Lakshmi + Saraswati + Durga | 378+105+49+23 = 555 |
| 4 | ಗಣಪತಿ (Ganapati) | Ganesha_ಗಣೇಶ | 70 |
| 5 | ಹನುಮಂತ (Hanumanta) | Anjaneya_ಆಂಜನೇಯ | 94 |
| 6 | ನರಸಿಂಹ (Narasimha) | Narasimha_ನರಸಿಂಹ | 68 |
| 7 | ಕೃಷ್ಣ (Krishna) | Krishna_ಶ್ರೀಕೃಷ್ಣ | 80 |
| 8 | ರಾಮ (Rama) | Rama_ಶ್ರೀರಾಮ | 77 |

**Extras (Secondary page with sub-categories):**
| Category | Stotras |
|----------|---------|
| Dattatreya_ದತ್ತಾತ್ರೇಯ | 160 |
| Shridhara_ಶ್ರೀಧರ | 46 |
| Gurudeva_ಗುರುದೇವ | 174 |
| Raghavendra_ರಾಘವೇಂದ್ರ | 60 |
| Subrahmanya_ಸುಬ್ರಹ್ಮಣ್ಯ | 55 |
| Surya_ಸೂರ್ಯ | 43 |
| Navagraha_ನವಗ್ರಹ | 70 |
| Gayatri_ಗಾಯತ್ರೀ | 25 |
| Vedamantra_ವೇದಮಂತ್ರ | 199 |
| Ashtottara_108_ಅಷ್ಟೋತ್ತರ | 306 |
| Sahasranama_1008_ಸಹಸ್ರನಾಮ | 58 |
| Ayyappa_ಅಯ್ಯಪ್ಪ | 11 |
| Ramakrishna_ರಾಮಕೃಷ್ಣ | 78 |
| Homa_Vidhi_ಹೋಮ | 32 |
| Sangeeta_ಸಂಗೀತ | 41 |
| Bhagavadgita_ಭಗವದ್ಗೀತೆ | 26 |
| Pooja_ಪೂಜೆ | 33 |
| Devaranama_ದೇವರನಾಮ | 171 |
| Madhwa_Bhajane_ಮಧ್ವಭಜನೆ | 186 |
| Deshabhakti_ದೇಶಭಕ್ತಿ | 288 |
| Harikathamruta_ಹರಿಕಥಾಮೃತಸಾರ | 34 |
| + Collection folders (Stotra Sangraha 1,2,3, etc.) | ~1,000+ |

---

### Data Layer

#### [NEW] [stotra_data.json](file:///d:/bharatheeyam%20books/assets/stotra_data.json)
- Convert all extracted `.txt` files into a single JSON file
- Structure: `{ categories: [{ id, title, titleEn, icon, stotras: [{ id, title, content }] }] }`
- Content stored as **base64-encoded raw bytes** (Nudi encoding) to preserve svaras
- ~22 MB compressed JSON asset

#### [MODIFY] [shloka.dart](file:///d:/bharatheeyam%20books/lib/models/shloka.dart)
- **Remove**: `sanskrit`, `meaning`, `explanation` fields from Shloka
- **Add**: `content` field (raw Nudi text)
- **Add**: `fontType` field (brhknd vs brhknde for svara)
- Simplify to just: `id`, `number`, `title`, `content`, `categoryId`, `fontType`

#### [NEW] [stotra_service.dart](file:///d:/bharatheeyam%20books/lib/services/stotra_service.dart)
- Load stotra data from JSON asset
- Provide methods: `getMainCategories()`, `getExtrasCategories()`, `getStotras(categoryId)`, `getStotraContent(stotraId)`, `search(query)`
- Cache loaded data in memory

---

### Font Assets

#### [NEW] [brhknd.ttf](file:///d:/bharatheeyam%20books/assets/fonts/brhknd.ttf)
#### [NEW] [brhknde.ttf](file:///d:/bharatheeyam%20books/assets/fonts/brhknde.ttf)
- Bundle both Nudi fonts from the old APK
- Register in pubspec.yaml

#### [MODIFY] [pubspec.yaml](file:///d:/bharatheeyam%20books/pubspec.yaml)
- Add font declarations for brhknd and brhknde
- Add stotra_data.json to assets
- Remove google_fonts dependency (not needed for Nudi text)

---

### Screens

#### [MODIFY] [home_screen.dart](file:///d:/bharatheeyam%20books/lib/screens/home_screen.dart)
- Replace current layout with:
  - 8 main deity category cards in a grid (2 columns)
  - "Extras" button at bottom → opens extras screen
  - Search bar at top
  - Bottom nav: Home | Favorites | Settings

#### [NEW] [category_screen.dart](file:///d:/bharatheeyam%20books/lib/screens/category_screen.dart)
- Shows list of stotra titles for a selected category
- Tap on a title → opens reader

#### [NEW] [extras_screen.dart](file:///d:/bharatheeyam%20books/lib/screens/extras_screen.dart)
- Grid of extra category cards
- Tap → opens category_screen for that category

#### [NEW] [reader_screen.dart](file:///d:/bharatheeyam%20books/lib/screens/reader_screen.dart)
- Full-screen stotra text reader
- Uses `brhknd`/`brhknde` font for Nudi text rendering
- Pinch-to-zoom text size
- Dark/light background
- Bookmark button
- Share button

#### [DELETE] Previous screens that show Sanskrit/meaning/explanation

---

### Widgets

#### [NEW] [nudi_text.dart](file:///d:/bharatheeyam%20books/lib/widgets/nudi_text.dart)
- Custom widget that renders Nudi-encoded bytes using the bundled brhknd/brhknde font
- Handles raw byte → String conversion with Latin-1 encoding
- Supports adjustable font size

#### [MODIFY] [shloka_card.dart](file:///d:/bharatheeyam%20books/lib/widgets/shloka_card.dart)
- Remove Sanskrit, meaning, explanation sections
- Show only stotra title + Nudi content

---

## Verification Plan

### Manual Verification
1. Run `flutter run` and verify:
   - 8 main deity categories show on home screen
   - Tapping a category shows stotra title list
   - Tapping a stotra shows full text in Nudi font
   - Svaras render correctly (above/below) for Vedamantra texts
   - Extras section shows all secondary categories
   - Search works across all stotras
   - Bookmarks work
   - Dark mode works
