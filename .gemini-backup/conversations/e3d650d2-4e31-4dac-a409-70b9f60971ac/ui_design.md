# Bharatiyam Panchanga — UI Design

## Design Direction
Premium **dark-mode** Hindu calendar app with **sacred geometry** aesthetics, **glassmorphism** cards, and **golden accents** on deep indigo/purple.

### Color Palette
| Token | Color | Usage |
|-------|-------|-------|
| Background | `#0D0221` | Main app background |
| Surface | `#1A0533` | Card backgrounds |
| Primary | `#D4A639` | Gold — headings, accents, borders |
| Secondary | `#00BFA5` | Teal — Moon/water elements |
| Accent | `#7C4DFF` | Purple — highlights |
| Shubha | `#00C853` | Green — auspicious |
| Ashubha | `#FF1744` | Red — inauspicious |
| Madhyama | `#FFB300` | Amber — neutral |
| Text | `#F5F0E8` | Warm white for body |
| Muted | `#8B7FA3` | Faded purple for labels |

### Typography
- **App title**: Noto Sans Kannada Bold, gold color
- **Section headers**: Noto Sans Bold 14-16sp
- **Body**: Noto Sans Regular 12-13sp
- **All Indic scripts**: Noto Sans family (Kannada, Devanagari, Tamil, Telugu, Malayalam)

---

## Screen 1: Home Screen

![Home Screen — Calendar grid with today's panchanga summary](C:\Users\goure\.gemini\antigravity\brain\e3d650d2-4e31-4dac-a409-70b9f60971ac\panchanga_home_screen_1783863691338.png)

**Key Elements:**
- Golden app title with Om/sacred symbol
- Monthly calendar grid with Tithi indicators on dates
- Green dots on auspicious (Agni Vasa = Bhumi) days
- Today's panchanga quick summary card
- Sunrise/Sunset display
- Bottom navigation: Home, Panchanga, Muhurta, Settings

---

## Screen 2: Panchanga Detail Screen

![Panchanga Detail — Full view with calendar system tabs](C:\Users\goure\.gemini\antigravity\brain\e3d650d2-4e31-4dac-a409-70b9f60971ac\panchanga_detail_screen_1783863703123.png)

**Key Elements:**
- **Calendar system tab bar**: Amanta | Pournimanta | Chandra Mana | Soura Mana
- Date selector with left/right navigation + location pin
- **Panchanga card**: Tithi, Vara, Nakshatra+Pada, Yoga, Karana — all with end times
- **Surya card**: Sunrise, Sunset, Surya Nakshatra, Soura Masa
- **Chandra card**: Chandra Rashi, Chandra Masa, Parama Ghati
- **Ashubha Kala card**: Rahu/Yama/Gulika with colored time bars
- **Kala card**: Samvatsara, Rutu, Ayana, Divamana, Ratrimana, Visha/Amruta Ghati
- Export buttons (PDF, Image, Share)

---

## Screen 3: Muhurta & Timings Screen

![Muhurta — Day/Night muhurtas, Lagna transits, Hora](C:\Users\goure\.gemini\antigravity\brain\e3d650d2-4e31-4dac-a409-70b9f60971ac\muhurta_timings_screen_1783863714411.png)

**Key Elements:**
- **Day Muhurta** (15): Name, time range, nature pill (green/red/amber), current highlighted
- **Night Muhurta** (15): Same format
- **Special Muhurtas**: Abhijit (⭐), Durmuhurta (⚠️), Varjyam (🚫), Amrita Siddhi (💎)
- **Lagna Transit**: 12 rashis with rising/setting timeline
- **Hora**: 12+12 planetary hours with planet symbols
- **Chougadiya**: 8+8 day/night periods

---

## Additional Screens (not yet mocked)

### Settings Screen
- Location: GPS + city search + manual entry
- Language: 7-language grid selector
- Ayanamsha: Lahiri (default) / Raman / KP
- Theme: Dark (default) / Light
- Export format preferences

### Search Screen  
- Find specific Tithi/Nakshatra/Masa dates
- Filter by date range, time range
- Results list with full panchanga summary

---

## UI Components

### Glassmorphism Card
```
Background: rgba(26, 5, 51, 0.7)
Border: 1px solid rgba(212, 166, 57, 0.15)
Border-radius: 16px
Backdrop-blur: 12px
Box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3)
```

### Section Header
```
Icon (20px) + Title (14sp bold) in gold
Background: gold at 8% opacity
Bottom border: gold at 20% opacity
```

### Time Range Chip
```
Background: accent-color at 10% opacity
Border: accent-color at 30% opacity  
Border-radius: 8px
Text: 12sp bold in accent-color
```

### Nature Pills
```
Shubha: green bg 12% + green text + "ಶುಭ"
Ashubha: red bg 12% + red text + "ಅಶುಭ"  
Madhyama: amber bg 12% + amber text + "ಮಧ್ಯಮ"
```

---

> [!IMPORTANT]
> **Review these mockups.** Do you like this design direction? Any changes to colors, layout, or features? Once approved, I'll start building the full app.
