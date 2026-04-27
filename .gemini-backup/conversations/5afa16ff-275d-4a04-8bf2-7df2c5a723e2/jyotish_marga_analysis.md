# Jyotish Marga Kundli Astrology — Feature Analysis

**APK:** `Jyotish Marga Kundli Astrology_0.9.23_APKPure.apk`  
**Package:** `com.jm.kundli`  
**Engine:** Native JNI library (`libjmal.so`) — all calculations in C/C++

---

## 🏠 Dashboard Features
| Feature | Status in Bharatheeyam |
|---------|----------------------|
| Horoscope | ✅ Have |
| Panchanga | ✅ Have |
| Prashna | ❌ Missing |
| Ashtamangala | ❌ Missing |
| Tajika (Varshaphala) | ❌ Missing |
| Match Making | ❌ Missing |
| PDF Generation | ❌ Missing |
| Saved Kundli / Open Existing | ✅ Have |

---

## 📊 Charts & Kundli
| Feature | Status |
|---------|--------|
| Rashi Kundli | ✅ Have |
| Navamsha Kundli | ✅ Have |
| Bhava Kundli | ✅ Have |
| Shodasha Varga A (D1-D12) | ✅ Have (Hora, Drekkana, etc.) |
| Shodasha Varga B (D16-D60) | ❌ Partial |
| Varga Koshtaka (table) | ❌ Missing |
| Vaisheshikamsha | ❌ Missing |
| Vimshopaka | ❌ Missing |
| South + North Indian chart styles | ✅ Have |

---

## 🔮 Dasha Systems
| Dasha | Status |
|-------|--------|
| Vimshottari Dasha | ✅ Have |
| Yogini Dasha | ❌ Missing |
| Chara Dasha (KN Rao) | ❌ Missing |
| Chara Dasha (Parashara) | ❌ Missing |
| Chara Dasha (Rangacharya) | ❌ Missing |
| Narayana Dasha | ❌ Missing |
| Kaalachakra Dasha | ❌ Missing |
| Ashtottari Dasha | ❌ Missing |
| Shodashottari Dasha | ❌ Missing |
| Dwadashottari Dasha | ❌ Missing |
| Panchottari Dasha | ❌ Missing |
| Shatabdika Dasha | ❌ Missing |
| Shashtihayani Dasha | ❌ Missing |
| Chaturashiti Sama Dasha | ❌ Missing |
| Dwisaptati Sama Dasha | ❌ Missing |
| Shat Trimshat Sama Dasha | ❌ Missing |
| Sudasha | ❌ Missing |
| Lagna Kendradi Rashi Dasha | ❌ Missing |
| Sthira Dasha (KN Rao) | ❌ Missing |

---

## 💪 Strength Calculations
| Feature | Status |
|---------|--------|
| Shadbala | ✅ Have |
| Bhava Bala | ❌ Missing |
| Bhava Drik Bala | ❌ Missing |
| Bhava Shashtyamsha | ❌ Missing |
| Uccha Bala, Digbala, Drishti Bala | ❌ Missing (individual) |
| Ishta Phala / Kashta Phala | ❌ Missing |
| Rashmi Ganita | ❌ Missing |
| Shodhya Pinda | ❌ Missing |

---

## 🔢 Ashtakavarga
| Feature | Status |
|---------|--------|
| Bhinna Ashtakavarga | ✅ Have |
| Sarva Ashtakavarga | ✅ Have |
| Prastara Ashtakavarga | ❌ Missing |
| Trikona Shodhana | ❌ Missing |
| Ekadhipathya Shodhana | ❌ Missing |
| Pinda Shodhana | ❌ Missing |

---

## 📅 Panchanga
| Feature | Status |
|---------|--------|
| Tithi, Nakshatra, Yoga, Karana | ✅ Have |
| Sunrise/Sunset | ✅ Have |
| Moonrise/Moonset | ❌ Missing |
| Chougadiya (Gowri Panchanga) | ❌ Missing |
| Day/Night Hora | ❌ Missing |
| Muhurta Timings | ❌ Missing |
| Gauri Panchanga | ❌ Missing |

---

## 🔯 Jaimini System
| Feature | Status |
|---------|--------|
| Chara Karakas | ❌ Missing |
| Arudha/Pada | ✅ Have (Aroodha) |
| Narayana Dasha | ❌ Missing |
| Brahma/Maheshwara/Rudra | ❌ Missing |

---

## 💑 Compatibility / Match Making
| Feature | Status |
|---------|--------|
| Guna Milan / Match Making | ❌ Missing |
| Navatara | ❌ Missing |
| Gana, Yoni, Varna, Vashya, Naadi | ❌ Missing |
| Tarabala | ❌ Missing |

---

## 🔮 Prashna & Ashtamangala
| Feature | Status |
|---------|--------|
| Prashna Kundli | ❌ Missing |
| Ashtamangala Prashna | ❌ Missing |
| Special Sputas (Trisputaadi) | ❌ Missing |
| Prashna Sutras & Phalas | ❌ Missing |

---

## ⚙️ Misc Features
| Feature | Status |
|---------|--------|
| Graha Maitri (Panchada + Varga) | ❌ Missing |
| Graha Avastas (Baladi, Deeptadi, Jagritadi) | ❌ Missing |
| Graha Yuddha | ❌ Missing |
| Sahams | ❌ Missing |
| Special Nakshatras | ❌ Missing |
| Nakshatra Aspects | ❌ Missing |
| Dhoomaadi Upagrahas | ✅ Have |
| Combust Planets (Asta) | ✅ Have |
| Ghataka Chakra | ❌ Missing |
| Avakahada Chakra | ❌ Missing |
| Papatatwa | ❌ Missing |

---

## 🎯 Priority Recommendations

**High priority** (most useful for astrology practice):
1. **Yogini Dasha** — second most popular dasha system
2. **Match Making / Guna Milan** — very common user request
3. **Chougadiya / Hora** — daily muhurta timing
4. **Prashna Kundli** — casting chart for current moment
5. **PDF Generation** — professional astrologers need this

**Medium priority:**
6. Prastara/Trikona/Ekadhipathya Shodhana (Ashtakavarga)
7. Bhava Bala
8. Chara Karakas (Jaimini)
9. Graha Avastas

> **Note:** The original app uses a proprietary native C library (`libjmal.so`). We cannot reuse its calculations. All features would need to be implemented using our existing Swiss Ephemeris engine.
