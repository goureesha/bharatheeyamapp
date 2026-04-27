# Ashtamangala Calculation Logic — Jyotish Marga vs Bharatheeyam

## JNI API Signature
```java
AstroLib.calcAshtamangala(pruchaka, sprushtanga, birthRashi, asmNumber, swarna, isMale)
```

## Input Parameters (from `y.java` fields)

| Parameter | Field | Default | Description |
|---|---|---|---|
| `pruchaka` | `s` | 1 | Querent's Janma Nakshatra index (1-27) |
| `sprushtanga` | `t` | 1 | Body part touched by querent (1-based index) |
| `birthRashi` | `u` | 1 | Querent's Birth Rashi (1-12) |
| `asmNumber` | `v` | 444 | 3-digit Ashtamangala number (100-999) |
| `swarna` | `w` | 1 | Gold coin placement (1-based) |
| `tambula` | `x` | 1 | Betel leaf placement (1-based) |
| `isMale` | `r==0` | true | Gender (0=Male, 1=Female) |

## Output: `getAsmPart(enum)` — 63 result fields

| # | Enum | Our Status |
|---|---|---|
| 0-2 | ChandraKriya, ChandraAvastha, ChandraVela | ❌ Not implemented (JNI-only) |
| 3-7 | SamanyaSutra, AdhipaSutra, AmshaSutra, NakshatraSutra, MahaSutra | ❌ Not implemented |
| 8-9 | TambulaGraha, TambulaRashi | ❌ Not implemented |
| 10-21 | Graha(1-3), Yoni(1-3), Jantu(1-3), Pbhuta(1-3) | ❌ Not implemented |
| **22-28** | **NumPaksha, NumTithi, NumNakshatra, NumVaara, NumRashi, NumGraha, NumPanchaBhuta** | **✅ Implemented** (Sankhya Ganita) |
| 29-30 | MadhyaPhala, SankhyaPhala | ❌ Not implemented |
| **31-61** | **Quality of Time checks** (BalannaVarjya → ShubhaMuhurta) | **⚠️ Partially** (9 checks, JM has 31) |
| 62 | ChatraRashi | ❌ Not implemented |

## Output: `getAsmSputa(enum)` — 37 special sputas

| # | Enum | Our Status |
|---|---|---|
| **0-6** | **Trisputa, Chatusputa, Panchasputa, PranaSputa, DehaSputa, MrityuSputa, SukshmaTrisputa** | **✅ Implemented** |
| 7-11 | Dhuma, Vyatipata, Parivesha, Indrachapa, Upaketu | ❌ (these are upagrahas, available elsewhere) |
| 12-17 | BeejaKshetra(1-3), Santana(1-3) | ❌ Not implemented |
| 18 | MaranashaniSputa | ❌ Not implemented |
| **19** | **AroodaSputa** | **✅ Implemented** |
| 20-21 | VeetiSputa, ChatraSputa | ❌ Not implemented |
| 22 | LagnaRaviYoga | ❌ Not implemented |
| **23-24** | **SannidhyaSputa, ChaitanyaSputa** | **✅ Implemented** |
| 25-36 | ChalanaSputa → KalaSputa (12 more) | ❌ Not implemented |

## Key Gaps — What We're Missing

1. **Sprushtanga input** — body part touched (maps to specific deductions)
2. **Swarna/Tambula inputs** — gold/betel placements  
3. **Gender input** — male/female affects calculations
4. **Chandra Kriya/Avastha/Vela** — Moon-based states (JNI-computed)
5. **5 Sutras** — Samanya, Adhipa, Amsha, Nakshatra, Maha (requires specific algorithms)
6. **Madhya/Sankhya Phala** — final result interpretation
7. **22 more Quality checks** — Gulikodaya, Ahishiras, Ekargala, etc.
8. **~20 more Sputas** — BeejaKshetra, Santana, Veeti, Chalana, Karana, Prasada, etc.

## What We Got Right ✅
- Sankhya Ganita (number→Paksha/Tithi/Nak/Vara/Rashi/Graha/Bhuta)
- Core 7 Sputas (Tri/Chatus/Pancha/Prana/Deha/Mrityu/Sukshma + Arooda/Sannidhya/Chaitanya)
- 8 Mangala Dravyas with deity mapping
- 9 Quality of Time checks
