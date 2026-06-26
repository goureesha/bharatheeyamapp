# Prashna Section — ರಾಶಿ ಫಲ & ಯೋಗ Tabs

## Background

The Prashna dashboard currently has 4 tabs: ಕುಂಡಲಿ, ಸ್ಫುಟ, ಪಂಚಾಂಗ, ಷಡ್ವರ್ಗ. The user wants 2 new options **under the ಕುಂಡಲಿ tab** (after the Rashi and Bhava kundali charts).

There is already existing code:
- [graha_phala.dart](file:///d:/bharatheeyamapp%20clone/lib/core/graha_phala.dart) — Has Sanskrit shlokas + Kannada summaries for all 7 planets in 12 rashis (from Brihad Jataka Ch.18)
- [prashna_dashboard_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/prashna_dashboard_screen.dart#L624-L687) — Has orphaned `_buildGrahaPhalas()` and `_phalaRow()` methods

## User Review Required

> [!IMPORTANT]
> **Shlokas verification**: The user wants Brihad Jataka shlokas in **Kannada** for verification before adding to the app. The current shlokas are in **Sanskrit**. I need to prepare Kannada transliterations/translations.

> [!IMPORTANT]  
> **Bhava Phala**: The user wants Bhava Phala (results per house) based on which planet occupies which bhava. This is a NEW data set not yet in the code — it needs Brihad Jataka bhava-related shlokas.

## Open Questions

1. **"Under the kundalis"** — Should these be:
   - **Option A**: Two new sections below the Rashi/Bhava charts in the existing ಕುಂಡಲಿ tab (scrollable)
   - **Option B**: Two new top-level tabs (making it 6 tabs total: ಕುಂಡಲಿ, ರಾಶಿ ಫಲ, ಯೋಗ, ಸ್ಫುಟ, ಪಂಚಾಂಗ, ಷಡ್ವರ್ಗ)

2. **Yogas tab** — Which yogas to include? Some options:
   - Pancha Mahapurusha Yogas (Ruchaka, Bhadra, Hamsa, Malavya, Sasa)
   - Chandra Yogas (Sunafa, Anafa, Durudhara, Kemadurma)
   - Raja Yogas
   - Daridra Yogas
   - Brihad Jataka specific yogas (Chapter 12-13)?

3. **Bhava Phala source** — Brihad Jataka Chapter 17 (Bhava Phala Adhyaya)?

## Proposed Changes — Phase 1 (Verification)

First, I'll prepare the **Brihad Jataka shlokas in Kannada** as an artifact for your review.

### Rashi Phala Shlokas

For each of the 7 grahas × 12 rashis = **84 shlokas** covering:
- ರವಿ ರಾಶಿ ಫಲ (BJ Ch.18, verses 1-4)
- ಚಂದ್ರ ರಾಶಿ ಫಲ (BJ Ch.18, verses 5-8)
- ಕುಜ ರಾಶಿ ಫಲ (BJ Ch.18, verses 9-12)
- ಬುಧ ರಾಶಿ ಫಲ (BJ Ch.18, verses 13-15)
- ಗುರು ರಾಶಿ ಫಲ (BJ Ch.18, verses 16-18)
- ಶುಕ್ರ ರಾಶಿ ಫಲ (BJ Ch.18, verses 19-21)
- ಶನಿ ರಾಶಿ ಫಲ (BJ Ch.18, verses 22-24)

### Bhava Phala Shlokas

For each bhava (1-12), what results when different planets occupy it:
- BJ Ch.17 (Bhava Phala Adhyaya)
- 12 bhavas × 7+ planets = **84+ shlokas**

---

## Proposed Changes — Phase 2 (Implementation)

After shlokas are verified:

### [MODIFY] [graha_phala.dart](file:///d:/bharatheeyamapp%20clone/lib/core/graha_phala.dart)
- Replace Sanskrit shlokas with verified Kannada shlokas
- Add Bhava Phala data (planet in bhava results)
- Add method to compute bhava phala based on selected lagna graha

### [NEW] [lib/core/yoga_calculator.dart](file:///d:/bharatheeyamapp%20clone/lib/core/yoga_calculator.dart)
- Yoga detection logic using planet positions
- Returns list of active yogas with names, descriptions, shlokas

### [MODIFY] [prashna_dashboard_screen.dart](file:///d:/bharatheeyamapp%20clone/lib/screens/prashna_dashboard_screen.dart)
- Wire up the orphaned `_buildGrahaPhalas()` into the ಕುಂಡಲಿ tab
- Add Bhava Phala section with lagna-graha selector
- Add Yogas section
- Add new tabs or sub-sections as decided

## Verification Plan

### Manual Verification
- User verifies all Kannada shlokas before they go into the app
- Test with different kundali charts to ensure correct rashi/bhava placement
- Verify bhava phala changes correctly when different graha is selected as lagna
