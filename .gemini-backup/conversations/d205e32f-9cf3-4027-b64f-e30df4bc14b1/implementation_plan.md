# Dvadasha Koota Matchmaking (12-Point System)

Add Dvadasha Koota (12 kootas, 36 points) alongside the existing Ashta Koota (8 kootas, 36 points), with a toggle to switch between them.

## Proposed Changes

### Backend: Match Making Logic

#### [MODIFY] [match_making.dart](file:///d:/bharatheeyamapp%20sample/lib/core/match_making.dart)

Add 4 new koota methods (the 4 extra kootas for Dvadasha system that are not in Ashta Koota):

| # | ಕೂಟ | Max | Logic |
|---|---|---|---|
| 1 | ವರ್ಣ (Varna) | 1 | Same as Ashta |
| 2 | ವಶ್ಯ (Vashya) | 2 | Same as Ashta |
| 3 | ತಾರಾ (Tara) | 3 | Same as Ashta |
| 4 | ಯೋನಿ (Yoni) | 4 | Same as Ashta |
| 5 | ಗ್ರಹ ಮೈತ್ರಿ (Graha Maitri) | 5 | Same as Ashta |
| 6 | ಗಣ (Gana) | 6 | Same as Ashta |
| 7 | ಭಕೂಟ (Bhakoot/Rashi) | 7 | Same as Ashta |
| 8 | ನಾಡಿ (Nadi) | 8 | Same as Ashta |
| **9** | **ಮಹೇಂದ್ರ (Mahendra)** | **1** | **NEW** — Count nakshatras from bride to groom. If (count-1) % 9 ∈ {0,3,6} → 1 pt |
| **10** | **ಸ್ತ್ರೀ ದೀರ್ಘ (Stree Deergha)** | **1** | **NEW** — If groom nak >= bride nak by 13+ → 1 pt |
| **11** | **ರಾಜ್ಜು (Rajju)** | **1** | **NEW** — Body part mapping (feet/hip/navel/neck/head). Same part = 0 |
| **12** | **ವೇಧ (Vedha)** | **1** | **NEW** — Specific nak pairs cause vedha (obstruction). No vedha = 1 pt |

- New method: `calculateDvadashaKoota(bRashi, bNak, gRashi, gNak)` → returns all 12 scores + total (out of 40)
- Add to `calculateFullCompatibility()` return map

---

### Frontend: Match Making Tab UI

#### [MODIFY] [match_making_tab.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/match_making_tab.dart)

1. **Add toggle state**: `int _kootaMode = 0;` (0 = Ashta, 1 = Dvadasha)
2. **Add segmented button** above the koota table to switch
3. **Conditionally render** `_buildAshtaKootaTable()` or `_buildDvadashaKootaTable()` based on toggle
4. **New method** `_buildDvadashaKootaTable()` — shows 12 rows with scores

---

### Localization

Add string keys for new kootas: `mahendra`, `streeDeergha`, `rajju`, `vedha`, `dvadashaKoota`, `ashtaKoota`

## Verification Plan

### Manual Verification
- Toggle between Ashta Koota and Dvadasha Koota
- Verify all 12 koota scores appear correctly
- Check all 5 languages display properly
