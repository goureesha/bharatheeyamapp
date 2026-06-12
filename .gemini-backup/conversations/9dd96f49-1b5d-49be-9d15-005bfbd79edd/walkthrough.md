# Bharatiyam Gratha Sudha — Walkthrough

## ✅ Data Extraction Complete

### What Was Done
Extracted **5,876 out of 5,894 stotras (99.7%)** from the original APK's smali bytecode with correct title-content pairing.

### Key Technical Challenges Solved

#### 1. Nudi Font PUA Encoding
The original app uses Nudi fonts (proprietary Kannada encoding). Bytes `0xA0-0xFF` and `0x41-0x7A` are remapped to Unicode Private Use Area (`U+E000+`) so Flutter's text engine renders them correctly with the bundled `brhknd.ttf` and `brhknde.ttf` fonts.

#### 2. Register Ordering in Smali
Smali bytecode stores array elements using two patterns:
- **Small arrays** (`<25` items): `filled-new-array/range {v1..vN}` — register order defines element order
- **Large arrays** (`25+` items): `aput-object` with explicit index constants — index value defines order

The extraction script handles both patterns to correctly order titles.

#### 3. Switch-Case Content Loading
Content classes (`d.smali`, `e.smali`, `h1.smali`, `p0.smali`) use `sparse-switch` and `packed-switch` statements to load different content sets based on an integer parameter:
- Each activity passes a specific int (e.g., `e.<init>(0x4)` for DattaActivity)
- The switch routes to the correct content block

#### 4. Constructor Delegation
Some switch cases delegate to alternate constructors:
- `e` default case → `e.<init>()V` (no-arg, 1079 strings for BMActivity)
- `p0` case 3 → `p0.<init>(Z)V` (23 strings for DSActivity)
- `p0` case 5 → `p0.<init>(B)V` (25 strings for GayatriActivity)

#### 5. Fall-Through Default Cases
When a param value isn't in the switch, execution falls through to the first label (e.g., h1's AshtottaraActivity with param=0 falls into `:pswitch_0`'s 324-string block).

### Final Results

| Content Class | Activities | Status |
|---|---|---|
| **d** | 9/9 | ✅ All perfect |
| **e** | 7/7 | ✅ All OK (BMActivity via delegation) |
| **h1** | 12/12 | ✅ All OK (2 off by 1) |
| **p0** | 9/9 | ✅ All OK (2 via delegation) |
| **Inline** | 37/37 | ✅ All OK |

### Category Breakdown

**8 Main Categories (Deities):**
| Category | Stotras |
|---|---|
| ಶಿವ (Shiva) | 257 |
| ವಿಷ್ಣು (Vishnu) | 274 |
| ದೇವಿ (Devi) | 555 |
| ಗಣಪತಿ (Ganapati) | 85 |
| ಹನುಮಂತ (Hanumanta) | 112 |
| ನರಸಿಂಹ (Narasimha) | 69 |
| ಕೃಷ್ಣ (Krishna) | 126 |
| ರಾಮ (Rama) | 208 |

**19 Extra Categories:** Dattatreya, Raghavendra, Guru, Gayatri, Navagraha, Surya, Sahasranama, Ashtottara, Mantra, Kartikeya, Ayyappa, Sridhara, Shankaracharya, Sangeetha, Saibaba, Pooja, Mallari, Namaste, Other

### Files
- **Data**: [stotra_data.json](file:///d:/bharatheeyam%20books/assets/data/stotra_data.json) (68.8 MB, 5894 entries)
- **Extraction Script**: [extract_final.py](file:///C:/Users/goure/Downloads/apk_decoded/extract_final.py)
- **Fonts**: `assets/fonts/brhknd.ttf`, `assets/fonts/brhknde.ttf`

## App Architecture

The Flutter app is set up with:
- `lib/main.dart` — App entry with Provider
- `lib/models/stotra.dart` — StotraCategory + Stotra models
- `lib/services/stotra_service.dart` — Loads JSON, provides search
- `lib/services/bookmark_service.dart` — SharedPreferences bookmarks
- `lib/screens/` — Home, Category, Extras, Reader, Search, Bookmarks, Settings
- `lib/widgets/nudi_text.dart` — Nudi font text renderer
- GitHub Actions CI/CD for automated builds

## Next Steps
- [ ] Admin website for content management (Firebase)
- [ ] Restore original 5-tab navigation per user's screenshots
- [ ] Reduce JSON file size (currently 68.8 MB, GitHub warns at 50 MB)
