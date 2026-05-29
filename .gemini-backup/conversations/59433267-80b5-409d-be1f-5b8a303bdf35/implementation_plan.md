# Enhanced Guna Milan — Full Compatibility Analysis

Complete overhaul of the Match Making section: from manual Rashi/Nakshatra dropdowns to full birth-data input with kundali calculation, dosha analysis, and detailed compatibility scoring.

## Current State

The existing Guna Milan ([match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)) only has:
- 4 dropdowns (bride rashi/nak, groom rashi/nak)
- Ashta Koota calculation ([match_making.dart](file:///d:/bharatheeyamapp%20sample/lib/core/match_making.dart)) — works, keep it
- No birth data input, no kundali calculation, no dosha analysis

## Open Questions

> [!IMPORTANT]
> **Graha Maitri (Brihad Jataka):** The current Graha Maitri in Ashta Koota uses Rashi Lords and a friendship matrix. The Brihad Jataka-based Graha Maitri compares the **Navamsha Rashi lords** of each planet to determine Mitra/Shatru/Sama relationships. Should we:
> - **Option A:** Replace the existing Ashta Koota Graha Maitri with Brihad Jataka method?
> - **Option B:** Keep the Ashta Koota Graha Maitri as-is, and add a **separate "Graha Maitri Amsha" section** below showing Brihad Jataka-style analysis for all 7 planets?
> I recommend **Option B** to keep Ashta Koota standard while adding the detailed analysis separately.

> [!IMPORTANT]
> **Papa Dosha calculation:** Papa grahas are traditionally Surya, Kuja, Shani, Rahu (and waning Chandra, weak Budha). Should Ketu also be included as a papa graha? Classical texts vary on this.

> [!IMPORTANT]
> **Kuja Dosha from Shukra:** You mentioned calculating Kuja Dosha from 3 points — Lagna, Chandra, and **Shukra**. Classical texts typically use Lagna, Chandra, and **Shukra** (Venus) as reference houses. Confirming this is correct?

---

## Proposed Changes

### Component 1: Compatibility Calculator Engine

#### [MODIFY] [match_making.dart](file:///d:/bharatheeyamapp%20sample/lib/core/match_making.dart)

Keep existing Ashta Koota logic, add new calculation methods:

**Kuja Dosha Calculator:**
- Check if Kuja (Mars) is placed in houses 1, 2, 4, 7, 8, 12 from:
  - Lagna (Ascendant)
  - Chandra (Moon sign)
  - Shukra (Venus sign)
- If Kuja is in any of these houses from any of the 3 reference points → Kuja Dosha present
- Return detailed breakdown: which houses from which reference point

**Papa Dosha Calculator:**
- Count papa grahas (Surya, Kuja, Shani, Rahu + waning Chandra) in houses 1, 2, 4, 7, 8, 12 from:
  - Lagna
  - Chandra  
  - Shukra
- Compare bride's papa count vs groom's papa count (Papa Samya)
- If difference ≤ 1 → balanced (acceptable)

**Graha Maitri Amsha (Brihad Jataka):**
- For each of the 7 planets (Sun through Saturn), determine:
  - Natural friendship (Naisargika Maitri) based on Brihad Jataka fixed table
  - Temporary friendship (Tatkalika Maitri) based on angular distance
  - Combined (Panchadha Maitri): Mitra+Mitra=Atimitra, Mitra+Shatru=Sama, etc.
- Compare bride's and groom's planet friendship relationships

**Shatha Ashtaka Dosha:**
- Check if groom's Moon is in the 6th from bride's Moon (or vice versa) — this is Shatha Ashtaka
- Return boolean + details

**Dvirdvadasha Dosha:**
- Check if groom's Moon is in the 2nd or 12th from bride's Moon (or vice versa)
- Return boolean + details

**New method signature:**
```dart
static Map<String, dynamic> calculateFullCompatibility({
  required KundaliResult brideResult,
  required KundaliResult groomResult,
});
```

Returns a map with:
- `ashtaKoota`: existing 8 koota scores + total
- `kujaDosha`: `{bride: {lagna: bool, chandra: bool, shukra: bool}, groom: {...}}`
- `papaDosha`: `{bride: {lagnaCount: int, ...}, groom: {...}, samya: bool}`
- `grahaMaitri`: planet-wise comparison table
- `shathaAshtaka`: `{present: bool, details: String}`
- `dvirdvadasha`: `{present: bool, details: String}`

---

### Component 2: Enhanced Match Making Screen

#### [MODIFY] [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)

Complete rewrite of the UI:

**Step 1 — Input Section:**
- Two input cards: **Groom** (left/top) and **Bride** (right/bottom)
- Each card has: Name, Date picker, Time picker, Place autocomplete
- Reuse the same place search pattern from [input_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/input_screen.dart)
- "Calculate" button at bottom → calls `AstroCalculator.calculate()` for both → stores both `KundaliResult` objects

**Step 2 — Results Display (tabs or scrollable sections):**

1. **Individual Details** (for each person):
   - Mini Rashi Kundali chart (reuse existing `KundaliChart` widget)
   - Mini Navamsha Kundali chart
   - Mini Bhava Kundali chart
   - Panchanga summary (name, place, date, time, nakshatra, rashi, dasha lord/balance)

2. **Kuja Dosha Section:**
   - Side-by-side display: Bride vs Groom
   - From Lagna: ✅/❌ with house position
   - From Chandra: ✅/❌ with house position
   - From Shukra: ✅/❌ with house position
   - Verdict: Both have / Neither / Mismatch

3. **Papa Dosha Section:**
   - Papa count from Lagna, Chandra, Shukra for each
   - Papa Samya verdict (balanced or not)

4. **Graha Maitri Amsha (Brihad Jataka):**
   - Table showing each planet's Naisargika + Tatkalika + Panchadha relationship
   - Comparison between bride and groom

5. **Shatha Ashtaka & Dvirdvadasha:**
   - Simple present/absent indicators with explanation

6. **Ashta Koota (existing, enhanced):**
   - Use nakshatra and rashi from calculated panchanga (not manual dropdowns)
   - Same 8-koota table with scores
   - Total and verdict

---

### Component 3: Localization

#### [MODIFY] [common.dart](file:///d:/bharatheeyamapp%20sample/lib/widgets/common.dart)

Add new locale keys for all 5 languages:
- `kujaDosha`, `papaDosha`, `papaSamya`, `grahaMaitriAmsha`
- `shathaAshtaka`, `dvirdvadasha`
- `fromLagna`, `fromChandra`, `fromShukra`
- `doshaPresent`, `doshaAbsent`, `balanced`, `imbalanced`
- `groomLabel`, `brideLabel`
- `calculateMatch`, `individualDetails`, `comparisonDetails`
- `naisargikaMaitri`, `tatkalikaMaitri`, `panchadhaMaitri`
- `atimitra`, `mitra`, `sama`, `shatru`, `atishatru`

---

## Verification Plan

### Manual Verification
- Test with known birth data pairs where Kuja Dosha is present/absent
- Verify Ashta Koota scores match the existing dropdown-based calculation
- Cross-check Brihad Jataka friendship tables with published references
- Test all 5 language translations

### Automated Tests
- Verify `calculateFullCompatibility()` returns correct structure
- Test edge cases: same person matched with self, extreme date ranges
