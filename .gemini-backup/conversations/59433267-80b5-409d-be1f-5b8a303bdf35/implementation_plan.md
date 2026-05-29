# Per-Person Tabs in Kundali Dashboard

## Problem
When multiple persons are added, every tab (Kundali, Sphuta, Dasha, etc.) shows **all persons' data stacked vertically**. Users have to scroll through one person's data to find the next.

## Proposed Change
Add a **person selector row** above the existing 11-tab bar. Each person gets their own independent view of all 11 tabs.

### UI Layout (Before → After)

**Before:**
```
[Kundali] [Sphuta] [Aroodha] [Dasha] ...
┌─────────────────────────┐
│ Person 1 charts         │
│ ─────────────────────── │
│ Person 2 charts         │
│ ─────────────────────── │
│ Person 3 charts         │
└─────────────────────────┘
```

**After:**
```
[👤 Ravi ✕] [👤 Priya ✕] [👤 Suresh ✕]  [+ Add]
[Kundali] [Sphuta] [Aroodha] [Dasha] ...
┌─────────────────────────┐
│ Only selected person's  │
│ charts/data             │
└─────────────────────────┘
```

## Proposed Changes

### [MODIFY] [dashboard_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/dashboard_screen.dart)

#### 1. Add `_selectedPersonIndex` state (line ~123)
- New state: `int _selectedPersonIndex = 0;`
- `0` = primary person, `1+` = extra persons

#### 2. Add person selector row (above TabBar, line ~1429)
- Horizontal scrollable row of chips/buttons
- Primary person always first (non-removable)
- Extra persons show with ✕ remove button
- `[+ Add]` button at the end (moves the existing person_add icon here)
- Tapping a chip sets `_selectedPersonIndex`

#### 3. Update ALL tab builders to use selected person only
Instead of building `allPersons` list and iterating, each tab builder will use a single person based on `_selectedPersonIndex`:

```dart
// Helper to get current person's data
KundaliResult get _activeResult => _selectedPersonIndex == 0 
    ? _primaryResult 
    : _extraPersons[_selectedPersonIndex - 1].result;
String get _activeName => _selectedPersonIndex == 0 
    ? _primaryName 
    : _extraPersons[_selectedPersonIndex - 1].name;
// ... etc for dob, hour, minute, ampm, lat, lon, place
```

**Tabs to update (9 tabs):**
- `_buildKundaliTab()` (L1468) — remove allPersons loop, show single person
- `_buildSphutas()` (L1621) — remove allPersons loop
- `_buildDashaTab()` (L2166) — remove allPersons loop
- `_buildPanchangTab()` (L2202) — remove allPersons loop
- `_buildBhavaTab()` (L2417) — remove allPersons loop
- `_buildGrahaShadvargaTab()` (L2580) — remove allPersons loop
- `_buildShadbalaTab()` (L2766) — remove allPersons loop
- `_buildAshtakaTab()` (L2736) — remove allPersons loop
- `_buildNotesTab()` (L3049) — remove allPersons loop

**Tabs unchanged (2 tabs):**
- `_buildAroodhaTab()` — already single person
- `_buildJanmaPatrikeTab()` — already single person (will use active person)

#### 4. Safety: auto-reset index when person is removed
When a person is removed and `_selectedPersonIndex` is out of bounds, reset to 0.

## Verification Plan

### Manual
- Add 2-3 persons → verify each person's tab shows only their data
- Switch between persons → verify tabs update correctly
- Remove a person → verify selection resets properly
- Single person (no extras) → verify no person selector shows (or shows just the one name)
