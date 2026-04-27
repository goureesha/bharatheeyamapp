# Muhurta Chintamani — Complete Lagna Rules Extraction

## Source: मुहूर्तचिन्तामणि (Kedar Datt Joshi edition)

> [!IMPORTANT]
> The Muhurta Chintamani does NOT specify "allowed rashis per ceremony" as a simple list. Instead, it defines lagna quality through **dosha-based rules** — which planets must NOT be in which houses. The concept is **Lagna Shuddhi** (purity), not just checking a predefined list of "allowed lagnas." The overall principle is: **Any lagna can be used** if it passes the planetary shuddhi checks.

---

## 1. General Principles & Prohibitions (Apply broadly)

### Gandanta Lagnas (Junctions)
- **What it is:** The junction points between Water and Fire signs.
- **Rule:** Last 1/2 ghati (12 mins) of Karka, Vrischika, Meena and the first 1/2 ghati of Simha, Dhanu, Mesha are universally forbidden for all muhurtas.
- **Exception (Dosha Bhanga):** Strong Jupiter can cancel lagna gandanta dosha.

### Visha Nadi (Poison Times)
- Each Nakshatra has a specific span of "poison ghatikas".
- **Rule:** Even if the lagna has all good qualities (sarva-guna-anvitam), it must be rejected if the Visha Nadi is running.

### Kartari Dosha (Hemming by Malefics)
- **Rule:** If a retrograde malefic is in the 2nd house and a direct malefic is in the 12th house, it creates Kartari Dosha (scissors effect).
- This applies to the lagna and the Moon. The 5th, 7th, and 9th houses should ideally be free of Kartari dosha as well.

### 7th from Moon (Universal Rule)
> *"रवि मन्द कुजाक्रान्तं मृगाङ्कात्सप्तमं त्यजेत् । विवाहयात्राचूडासु गृहकर्मप्रवेशने ॥"* (Page 459)
- **Rule:** For Marriage, Travel, Tonsure (Chowla), and House Entry, the 7th house from the Moon should not be occupied by the Sun, Saturn, or Mars.

---

## 2. Event-Specific Rules

### A. विवाह लग्न (Vivaha - Marriage)
Vivaha has the strictest rules of all ceremonies.
- **In Lagna (1st house):** The Sun, Mars, Saturn, Rahu, Ketu, and Moon are FORBIDDEN.
- **In Saptama (7th house):** **ALL planets** (benefic and malefic) are FORBIDDEN. The 7th house must be completely empty. ("सर्वे जामित्रसंस्था विदधति मरणम्")
- **In Ashtama (8th house):** Moon, Mercury, Jupiter, Venus, and Mars are FORBIDDEN.
- **In 6th house:** Venus, Moon, and the Lagna lord are FORBIDDEN.
- **In 12th house:** Saturn is FORBIDDEN.
- **In 3rd house:** Venus is FORBIDDEN.

### B. उपनयन लग्न (Upanayana - Thread Ceremony)
Focuses heavily on intelligence and learning.
- **Navamsha Rule:** The Navamsha (D9) of the lagna must ideally belong to Mercury, Jupiter, or Venus (i.e., Vrishabha, Mithuna, Kanya, Tula, Dhanu, Meena). Moon or Malefic navamshas are bad.
- **Good Placements:** Benefics (Jupiter, Venus, Mercury) in Kendra (1,4,7,10) and Trikona (5,9).
- **Bad Placements:** Malefics in Kendra/Trikona. Malefics should be in Upachaya (3,6,11).

### C. अन्नप्राशन लग्न (Annaprashana - First Feeding)
- **Dashama Shuddhi (10th house purity):** The 10th house must be completely empty of any planets. ("दशमे शुद्धिसंयुक्ते")
- **Moon Rule:** Moon should not be in Lagna, 6th, or 8th house. ("व्यन्त्यारिनिधनस्थेन चन्द्रेण प्राशनं शुभम्")
- **House Rules:** Benefics in 1,3,4,5,7,9. Malefics in 3,6,11.

### D. चौलकर्म लग्न (Chowla / Chudakarana - Tonsure)
- **Ashtama Shuddhi (8th house purity):** The 8th house must not have any planets, except Venus which is highly strictly forbidden. ("अष्टमस्था ग्रहाः सर्वे नेष्टाः शुक्रविवजिताः")
- **Moon's 7th:** Must not have Sun, Saturn, or Mars.

### E. गृहप्रवेश लग्न (Griha Pravesha - House Entry)
- **Rashi Rule:** Specifically recommends **स्थिर राशि** (Fixed signs: Vrishabha, Simha, Vrischika, Kumbha) for permanence and stability. ("एवं सुलग्ने स्वगृहं प्रविश्य... स्थिरराश्यादिके")
- **Moon's 7th:** Must not have Sun, Saturn, or Mars.

### F. नामकरण लग्न (Namakarana - Naming)
- **Ashtama Shuddhi:** 8th house must be pure/empty.
- **House Rules:** Standard — benefics in Kendra/Trikona, malefics in 3, 6, 11.

---

## 3. Exceptions and Cancellations (Dosha Bhanga)

The Muhurta Chintamani emphasizes that doshas can be cancelled under specific astrological conditions.

### 1. Ashtama Lagna Dosha Cancellation (Vivaha)
Normally, if the muhurta lagna is the 8th sign from the bride/groom's janma rashi, it's a severe dosha. However, this is cancelled if:
- **Eka-adhipatya:** The lord of the janma rashi and the 8th lord are the exact same planet (e.g., Mesha and Vrischika = Mars).
- **Mitratva:** The lord of the janma rashi and the 8th lord are mutual friends.
- **Specific Rashis Exempted:** Meena, Vrishabha, Karka, Vrischika, Makara, and Kanya placed in the 8th house do not cause ashtama dosha.
- **Kendra Lord:** If the 8th lord is in a Kendra and aspected by a benefic, the dosha is destroyed.

### 2. General Dosha Bhanga (Planet Strength)
- A very strong Jupiter or Venus situated in a Kendra or Trikona can destroy an immense amount of doshas (like a lion scattering an elephant herd).
- If a malefic is in its exalted sign (Uchcha) or own sign (Swagriha), its negative effects are significantly mitigated and it can act as a benefic. ("स्वगृहोच्चायवस्थितः पापग्रहः शुभफलदाता")

---

## Technical Implications for the Codebase

1. **Move away from static `allowedLagnas`:** The rule engine should allow almost any lagna (except Gandanta points) and calculate validity based on planetary placements (`Shuddhi`).
2. **Add Dashama Shuddhi:** For Annaprashana, the 10th house must be empty.
3. **Refine Saptama Shuddhi:** For Vivaha, it currently maps to "no malefics in 7th", but it should be "no planets at all in 7th".
4. **Refine Ashtama Shuddhi:** For Vivaha, Moon, Venus, Jupiter, and Mercury must also be scanned in the 8th house, not just malefics.
5. **Implement Moon-relative limits:** For Yatra, Chowla, Vivaha, and Griha Pravesha, adding a check to ensure Sun, Saturn, and Mars are not in the 7th from Moon.
6. **Implement Dosha Bhanga rules:** Adding conditions where an Ashtama dosha is ignored if the Lagna Lord matches the 8th Lord.
