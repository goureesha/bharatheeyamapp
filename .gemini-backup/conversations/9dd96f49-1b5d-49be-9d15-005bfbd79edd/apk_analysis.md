# ಸ್ತೋತ್ರಮಾಲಾ APK Analysis

**Package**: `com.utl.stotragalu`  
**App Name**: ಸ್ತೋತ್ರಮಾಲಾ  
**Size**: 50MB  
**Type**: Native Android (Java/Kotlin) — NOT Flutter

---

## UI Structure

### 1. Main Screen (`activity_main.xml`)
```
┌─────────────────────────┐
│  Search Bar              │  ← EditText: "Search.. Long-press (+/- Fav/Top)"
│  (filter stotras)        │
├─────────────────────────┤
│                          │
│  ListView                │  ← Scrollable list of all 4590 stotras
│  (stotra list)           │     Each item: English + Kannada title
│                          │
│                          │
├─────────────────────────┤
│  AdMob Banner            │  ← Google Ads (SMART_BANNER)
└─────────────────────────┘
```

### 2. Text Reader (`textview.xml`) — Dark Theme
```
┌─────────────────────────┐
│  Title Bar (white text)  │  ← Stotra title
├─────────────────────────┤
│  ═══════════════════     │  ← SeekBar (font size: 0-40, default 10)
├─────────────────────────┤
│                          │
│  ScrollView              │
│  ┌───────────────────┐   │
│  │  Stotra Text       │   │  ← White text on black background
│  │  (Kannada/Sanskrit)│   │     Scrollable, adjustable font size
│  │                    │   │
│  └───────────────────┘   │
│                          │
└─────────────────────────┘
```

### 3. Title Bar (`kannadatitlebar.xml`)
```
┌─────────────────────────┐
│  🪷  ಸ್ತೋತ್ರಮಾಲಾ       │  ← Lotus icon + Kannada title (serif, 20sp, white)
└─────────────────────────┘
```

### 4. Other Layouts
| Layout | Purpose |
|--------|---------|
| `list_item.xml` | Individual item in the stotra list |
| `row.xml` | Alternative row layout |
| `preferences.xml` | Settings screen |
| `activity_image_view.xml` | Image viewer for deity pictures |
| `image_view.xml` | Shared image display component |
| `custom_dialog.xml` | Dialog popup |
| `textview_bw.xml` | Text reader with alternative B/W theme |

---

## Content Catalog: 4,590 Stotras in 38 Categories

| # | Category | Count | Description |
|---|----------|-------|-------------|
| 1 | **Devaranama** | 1,079 | Devotional songs (ದೇವರನಾಮ) |
| 2 | **Parvati** | 390 | Devi/Parvati stotras |
| 3 | **108 Ashtottaragalu** | 324 | 108-name chants |
| 4 | **Itara Stotragalu** | 316 | Miscellaneous stotras |
| 5 | **Ishwara** | 226 | Shiva stotras |
| 6 | **Vedamantragalu** | 205 | Vedic mantras |
| 7 | **Madhwa Bhajanegalu** | 194 | Madhwa tradition bhajans |
| 8 | **Vishnu** | 191 | Vishnu stotras |
| 9 | **Gurudeva** | 174 | Guru stotras |
| 10 | **Dattatreya** | 160 | Dattatreya stotras |
| 11 | **Lakshmi** | 107 | Lakshmi stotras |
| 12 | **Anjaneya** | 94 | Hanuman stotras |
| 13 | **Krishna** | 82 | Krishna stotras |
| 14 | **Rama** | 79 | Rama stotras |
| 15 | **Deshabhakti** | 78 | Patriotic songs |
| 16 | **1008 Sahasranamavali** | 75 | 1008-name chants |
| 17 | **Ganesha** | 71 | Ganesha stotras |
| 18 | **Navagraha** | 70 | Planetary stotras |
| 19 | **Narasimha** | 69 | Narasimha stotras |
| 20 | **Raghavendra** | 62 | Raghavendra stotras |
| 21 | **Subrahmanya** | 56 | Kartikeya stotras |
| 22 | **Saraswati** | 51 | Saraswati stotras |
| 23 | **Ramakrishna Sharada** | 51 | Vivekananda tradition |
| 24 | **Shridhara** | 46 | Shridhara Swami stotras |
| 25 | **Aditya** | 43 | Surya stotras |
| 26 | **Sanskrit Geetegalu** | 41 | Sanskrit songs |
| 27 | **Shreenivasa** | 39 | Venkateshwara stotras |
| 28 | **Harikathamrutasara** | 33 | Jagannatha Dasa composition |
| 29 | **Sandhya/Pooja** | 33 | Daily worship rituals |
| 30 | **Homa Vidhi** | 31 | Fire ritual procedures |
| 31 | **Bhagavad Gita** | 28 | Gita chapters |
| 32 | **Sai Baba** | 25 | Sai Baba stotras |
| 33 | **Ekavimshati Namavali** | 24 | 21-name chants |
| 34 | **Gayatri** | 24 | Gayatri mantras |
| 35 | **Ayyappa** | 10 | Ayyappa stotras |
| 36 | **Vishwakarma** | 7 | Vishwakarma stotras |
| 37 | **Durga Saptashati** | 1 | Durga 700 verses |
| 38 | **Durga Kavacham** | 1 | Durga protective mantra |

---

## Architecture

### Key Activities (sorted by size = content)
| Activity | Size | Content |
|----------|------|---------|
| `SSActivity` | 7.0 MB | Largest — likely main stotra storage |
| `SSCActivity` | 3.8 MB | Secondary stotra collection |
| `GCPActivity` | 3.5 MB | Ganesha/deity collection |
| `GCActivity` | 2.9 MB | General collection |
| `RamanaActivity` | 2.0 MB | Ramana content |
| `ASActivity` | 1.5 MB | Ashtottara collection |
| `VPActivity` | 1.4 MB | Vishnu Purana content |

### Technical Details
- **Fonts**: 3 custom Kannada fonts (`brhknd.ttf`, `brhknde.ttf`, `nudi01k.ttf`)
- **Ads**: Google AdMob (banner ads at bottom)
- **Features**: Search, Favorites (long-press), Font size slider
- **Text storage**: All stotra text is **hardcoded in Java activities** (not in files or database)
- **Room DB**: Uses AndroidX Room (likely for favorites/bookmarks)

### Extracted Files Location
```
C:\Users\goure\Downloads\apk_decoded\
├── AndroidManifest.xml          ← Human-readable manifest
├── res\layout\                  ← All UI layouts (decoded XML)
├── res\values\strings.xml       ← App strings  
├── smali\com\utl\stotragalu\    ← All app code (smali bytecode)
└── assets\fonts\                ← Custom Kannada fonts
```
