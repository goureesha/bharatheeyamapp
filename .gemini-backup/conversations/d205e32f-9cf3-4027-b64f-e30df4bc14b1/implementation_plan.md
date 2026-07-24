# Ready Muhoorta — Pre-computed Event Muhurtas

## Concept
Pre-calculate ALL event muhurtas (panchanga + lagna + guru anukoola + guru asta) once and store them.  
When user enters rashi + nakshatra → just filter by **tara bala + chandra bala + guru bala (from janma rashi)** = instant results.

## What's Pre-computed (same for everyone)
- ✅ Tithi allowed
- ✅ Nakshatra allowed  
- ✅ Vara allowed
- ✅ Vishti (Bhadra) check
- ✅ Shukla Paksha check
- ✅ Lagna windows with shuddhi (malefics in lagna/ashtama/saptama/dashama)
- ✅ Guru anukoola from lagna
- ✅ Guru asta / Shukra asta

## What's Filtered Per-User (fast)
- 🔍 Tara bala (from user's janma nakshatra)
- 🔍 Chandra bala (from user's janma rashi)
- 🔍 Guru bala (from user's janma rashi)

## Implementation

### [MODIFY] [taranukoola_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/taranukoola_screen.dart)

1. **Add Tab 3**: "⚡ ರೆಡಿ ಮುಹೂರ್ತ" (Ready Muhoorta)
2. **Pre-compute on tab open**: Scan next 12 months for ALL events, store valid days with lagna windows
3. **User input**: Just rashi + nakshatra + event dropdown
4. **Filter**: Apply tara/chandra/guru bala → instant display

### Data Structure
```dart
// Pre-computed per event
Map<MuhurtaEvent, List<PrecomputedDay>> _precomputedDays;

class PrecomputedDay {
  DateTime date;
  PanchangData panchang;
  List<LagnaWindow> lagnaWindows; // already filtered by isPerfect
  List<MuhurtaCheckItem> checks;
  int score;
}
```

### Flow
1. When tab opens → background compute for selected event (show progress)
2. User picks rashi + nakshatra → instant filter
3. Results show same cards as current muhurta finder

## Verification
- Compare results with existing muhurta finder for same inputs
- Verify speed improvement
