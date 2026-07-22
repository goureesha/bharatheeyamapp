# Add New Pages to Janma Patrike PDF

Add 4 new pages (Pages 3–6) to the existing 2-page Janma Patrike PDF, bringing it to a comprehensive 6-page Jataka Patrika.

## Current State

| Page | Content |
|---|---|
| Page 1 | Birth Details + Panchanga + Graha Table + 3 Charts (Rashi, Navamsha, Bhava) |
| Page 2 | Vimshottari Mahadasha Table + Shishta Dasha Banner |

## Proposed New Pages

### Page 3: Antardasha (Bhukti) Tables
- **Data source:** `DashaEntry.antardashas` (already computed, 5 levels deep)
- **Layout:** For each of the 9 Mahadashas, show a compact table of its Antardashas (Level 2) with:
  - Antardasha Lord | Start Date | End Date
- **Design:** Grouped by Mahadasha with colored headers matching the theme
- Highlight the **current running** Mahadasha-Antardasha pair

### Page 4: Divisional Charts (Varga Kundalis)
- **Data source:** `PlanetInfo` fields — `d2` (Hora), `d3` (Drekkana), `d9` (Navamsha), `d12` (Dvadashamsha), `d30` (Trimshamsha) — already computed by `AstroCalculator.getPlanetDetail()`
- **Layout:** 6 South Indian style charts arranged in a 2×3 grid:
  - D1 (Rashi) — already drawn on Page 1, included for completeness
  - D2 (Hora)
  - D3 (Drekkana)
  - D9 (Navamsha)
  - D12 (Dvadashamsha)
  - D30 (Trimshamsha)
- **Design:** Smaller chart boxes using the existing `_buildChartWidget()` method, with chart labels

> [!NOTE]
> D4, D7, D10, D16, D20, D24, D27, D40, D45, D60 charts require new calculation logic and can be added in a future update.

### Page 5: Ashtakavarga Tables
- **Data source:** `AshtakaVarga.computeAll()` — already computed (BAV for 7 planets + SAV)
- **Layout:**
  - **Section 1:** Bhinnashtakavarga (BAV) — 7 individual planet tables showing bindus (0/1) across 12 rashis, with row totals
  - **Section 2:** Sarvashtakavarga (SAV) — single row showing total bindus per rashi (sum of all 7 planets)
- **Design:** Compact 12-column grid per planet, rashi names as column headers

### Page 6: Shadbala (Planetary Strength) Table
- **Data source:** `KundaliResult.shadbala` — already computed (7 planets × 6 components)
- **Layout:** Single detailed table with columns:
  - Graha | Sthana | Dik | Kala | Cheshta | Naisargika | Drik | **Total** | Required | Strong?
- **Design:** Color-coded rows (green for strong planets, red for weak), bar/percentage visualization if space allows

## Proposed Changes

### [MODIFY] [janma_patrike_service.dart](file:///d:/bharatheeyamapp%20sample/lib/services/janma_patrike_service.dart)
- Add 4 new page builder methods: `_buildPage3Antardasha()`, `_buildPage4VargaCharts()`, `_buildPage5Ashtakavarga()`, `_buildPage6Shadbala()`
- Update the main `generate()` method to include all 6 pages
- Each page follows the existing pattern: build widget → screenshot → embed as full-page PDF image

### [MODIFY] [calculator.dart](file:///d:/bharatheeyamapp%20sample/lib/core/calculator.dart) (minor)
- Ensure `getPlanetDetail()` divisional sign data (d2, d3, d9, d12, d30) is accessible for chart grid computation
- Add helper to compute divisional chart grid positions from sign names

### No new files needed — all changes are additions to existing services.

## Open Questions

> [!IMPORTANT]
> 1. **Antardasha depth:** Should Page 3 show only Level 2 (Antardasha/Bhukti), or also Level 3 (Pratyantardasha)? Level 3 would need an additional page.
> 2. **Language:** The charts and tables will use the app's current locale (Kannada/Hindi/Tamil/Telugu/Malayalam). Is that correct?
> 3. **Current Dasha highlighting:** Should the currently running Mahadasha/Antardasha be visually highlighted (e.g., bold border, colored background)?

## Verification Plan

### Manual Verification
- Generate the PDF with test birth data
- Verify all 6 pages render correctly
- Cross-check Antardasha dates against existing Mahadasha dates
- Verify Ashtakavarga bindu counts per rashi
- Verify Shadbala totals match the calculator output
