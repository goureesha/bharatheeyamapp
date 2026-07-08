# Copy Multi-Person Kundali View from Clone App

Port 3 features from `D:\bharatheeyamapp clone` → `D:\bharatheeyamapp sample`:

## Proposed Changes

### [MODIFY] [dashboard_screen.dart](file:///d:/bharatheeyamapp%20sample/lib/screens/dashboard_screen.dart)

#### 1. Person Selector Chip Bar
- Add `int _selectedPersonIdx = -1` state variable (`-1` = show all)
- Add horizontal `ChoiceChip` bar between app bar and tab bar — shows "All", primary name, and extra person names
- Only visible when `_extraPersons.isNotEmpty`

#### 2. `_filterPersons()` Method
- New method: filters `allPersons` list by `_selectedPersonIdx`
- Called in **every tab** (`_buildKundaliTab`, `_buildSphutas`, `_buildDashaTab`, `_buildPanchangTab`, `_buildBhavaTab`, `_buildGrahaShadvargaTab`, `_buildShadbalaTab`, `_buildAshtakaTab`)

#### 3. New "Bhava Shadvarga" Tab (ಭಾವ ಷಡ್ವರ್ಗ)
- 12 tabs instead of 11
- New `_buildBhavaShadvargaTab()` method showing Bhava varga table with D1, D3, D2, D9, D12, D30, sub-drekkana columns, and D81

## Verification Plan

### Manual Verification
- Build and test with multiple persons added
- Verify chip bar appears and filters work per tab
- Verify new Bhava Shadvarga tab renders correctly
