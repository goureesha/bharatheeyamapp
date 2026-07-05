# Trip Planning & Live Tracking Overhaul

## Goal

Rebuild the trip planning system so users can:
1. **Plan trips on the map** — pick start/end points, add stops, toggle round trip, save to Firestore
2. **Load & track saved trips** — load any saved plan onto the map with full route details
3. **Share trip plans** — share in-app (to other TravelBuddy users) and via WhatsApp
4. **Live trip mode** — share location with team, log activity stops (fuel, food, hotel, viewpoint, etc.) that get saved to the trip plan

---

## Current State (What Exists)

| Feature | Status | Gap |
|---------|--------|-----|
| Route planning on map | ✅ UI exists (start/end/stops/search) | ❌ Routes are **in-memory only** — never saved |
| Trip Planner screen | ✅ Basic CRUD | ❌ Only stores name/destination/dates — **no map/route data** |
| Trip sharing | ✅ Share codes | ❌ Shares only text metadata — **no route/waypoints** |
| Location sharing | ✅ Works with teams | ❌ Not linked to a trip plan |
| Stop logging | ❌ Doesn't exist | Need activity-tagged stops during live trips |
| Round trip | ❌ Doesn't exist | Need toggle to make end = start |
| WhatsApp sharing | ❌ Doesn't exist | Need `share_plus` deep link or text |

---

## Firestore Schema

### `users/{uid}/trip_plans/{planId}`

```json
{
  "name": "Bangalore to Goa",
  "isRoundTrip": false,
  "status": "planned",           // planned | active | completed
  "waypoints": [
    {"name": "Bangalore", "lat": 12.97, "lng": 77.59, "order": 0, "type": "start"},
    {"name": "Chitradurga Fort", "lat": 14.23, "lng": 76.40, "order": 1, "type": "stop"},
    {"name": "Goa", "lat": 15.49, "lng": 73.82, "order": 2, "type": "end"}
  ],
  "routeDistanceKm": 560.2,
  "routeDurationMin": 630.0,
  "routePolyline": "encoded_polyline_string",
  "teamId": null,                // if shared with a team
  "shareCode": null,             // for sharing
  "createdBy": "uid",
  "createdByName": "John",
  "createdAt": Timestamp,
  "startedAt": null,             // when live trip began
  "completedAt": null,
  "stops": [                     // logged during live trip
    {
      "name": "HP Petrol Pump",
      "lat": 13.45, "lng": 77.12,
      "activity": "fuel",        // fuel | food | tea | hotel | viewpoint | suggestion | other
      "notes": "Filled 20L diesel",
      "timestamp": "ISO8601",
      "addedBy": "uid"
    }
  ]
}
```

> [!NOTE]
> The same document serves both **planning** (waypoints + route) and **live tracking** (stops + status). This avoids data duplication between the current `planned_trips`, `routes`, and `trips` collections.

---

## Proposed Changes

### New Service Layer

#### [NEW] [trip_plan_service.dart](file:///d:/TravelBuddy/lib/services/trip_plan_service.dart)

Central service for trip plan CRUD. Replaces the fragmented approach across `trip_service.dart`, `route_service.dart` for plan data.

- `savePlan()` — create/update a plan with waypoints + route data
- `getPlans()` — stream all user plans (or team plans)
- `getPlan(id)` — single plan stream
- `startTrip(planId)` — set status to `active`, record `startedAt`
- `completeTrip(planId)` — set status to `completed`
- `addStop(planId, stop)` — append an activity stop during live trip
- `sharePlan(planId)` — generate share code, copy to `shared_trips` collection
- `loadSharedPlan(code)` — fetch a shared plan by code
- `deletePlan(planId)`

---

### Map Screen Changes

#### [MODIFY] [live_map_screen.dart](file:///d:/TravelBuddy/lib/screens/live_map_screen.dart)

This is the biggest change. The existing route planner sheet UI stays mostly intact, but we add:

1. **"Save Plan" button** in the route planner bottom sheet (after route info shows distance/duration)
   - Opens a dialog: trip name, round trip toggle
   - Calls `TripPlanService.savePlan()` with current waypoints + route data
   - Shows confirmation snackbar

2. **"Load Trip" button** in the map toolbar
   - Shows bottom sheet with saved trip plans
   - On tap: loads waypoints onto map, fetches route, shows polyline + markers
   - Shows stop markers if trip has logged stops

3. **Round trip toggle** in the route planner sheet
   - When enabled: automatically sets end = start waypoint
   - Route includes return leg via OSRM

4. **"Start Trip" button** (when a plan is loaded)
   - Sets plan status to `active`
   - Starts location broadcasting
   - Shows "Add Stop" FAB

5. **"Add Stop" FAB** (during active trip)
   - Bottom sheet with activity picker: ⛽ Fuel, 🍵 Tea, 🍽️ Food, 🏨 Hotel, 🏔️ Viewpoint, 💡 Suggestion, 📝 Other
   - Auto-fills current GPS location
   - Optional notes field
   - Saves to `stops` array in the trip plan doc

6. **Stop markers on map** — colored by activity type, tappable for details

---

### Trip Planner Screen Changes

#### [MODIFY] [trip_planner_screen.dart](file:///d:/TravelBuddy/lib/screens/trip_planner_screen.dart)

- Change Firestore source from `planned_trips` to `trip_plans`
- Show route info (distance, duration, stop count) on each card
- Show status badge (Planned / Active / Completed)
- Tap a trip → open `LiveMapScreen` with that plan loaded
- Add share button (in-app code + WhatsApp)
- Keep the "Plan Trip" FAB but make it open the map directly in planning mode

---

### Trip Sharing Changes

#### [MODIFY] [trip_sharing_screen.dart](file:///d:/TravelBuddy/lib/screens/trip_sharing_screen.dart)

- Share from `trip_plans` instead of `planned_trips`
- Include full waypoints + route data in shared doc
- **WhatsApp sharing**: use `share_plus` to send a text message like:
  ```
  🗺️ Check out my trip plan "Bangalore to Goa"!
  📍 3 stops · 560 km · ~10.5 hrs
  Open in TravelBuddy: [share code]
  ```
- Add "Share via WhatsApp" button alongside the existing code share

---

### Existing Services (Keep / Deprecate)

| Service | Action |
|---------|--------|
| [route_service.dart](file:///d:/TravelBuddy/lib/services/route_service.dart) | **Keep** — still used for OSRM API calls (`getDirections`, `getRouteInfo`). Remove Firestore route CRUD (moved to `TripPlanService`) |
| [trip_service.dart](file:///d:/TravelBuddy/lib/services/trip_service.dart) | **Keep for now** — fuel-tracking trips are a separate concept. Can merge later |
| [trip_log_service.dart](file:///d:/TravelBuddy/lib/services/trip_log_service.dart) | **Keep** — checkpoint logging is separate from activity stops |
| [location_service.dart](file:///d:/TravelBuddy/lib/services/location_service.dart) | **Keep as-is** — location broadcasting works well |

---

## Open Questions

> [!IMPORTANT]
> **1. Migration**: The current `planned_trips` collection has existing user data. Should I:
> - **(a)** Migrate old `planned_trips` docs into the new `trip_plans` format on first load?
> - **(b)** Start fresh with `trip_plans` and keep old data as-is (users lose their planned trips)?

> [!IMPORTANT]
> **2. Team trips**: Should trip plans be team-shareable (stored under `teams/{teamId}/trip_plans/`)? Or only personal plans that can be shared via code? Your current description suggests personal plans shared via code/WhatsApp, and location sharing happens separately via teams.

> [!IMPORTANT]
> **3. Route optimizer screen**: The existing [route_optimizer_screen.dart](file:///d:/TravelBuddy/lib/screens/route_optimizer_screen.dart) has its own route UI. Should I:
> - **(a)** Remove it (since map now does everything)?
> - **(b)** Keep it as a standalone tool?

---

## File Summary

| Action | File | Description |
|--------|------|-------------|
| **NEW** | `lib/services/trip_plan_service.dart` | Central CRUD for trip plans |
| **MODIFY** | `lib/screens/live_map_screen.dart` | Save/load plans, round trip, live stops, start/complete trip |
| **MODIFY** | `lib/screens/trip_planner_screen.dart` | Use new `trip_plans` collection, show route info, open map |
| **MODIFY** | `lib/screens/trip_sharing_screen.dart` | Share full route data, WhatsApp sharing |
| **MODIFY** | `lib/services/route_service.dart` | Remove Firestore CRUD, keep OSRM calls |

---

## Verification Plan

### Manual Testing
1. Open map → plan a route (start → stops → end) → save → verify in Trip Planner list
2. Open Trip Planner → tap a saved plan → verify map loads with all waypoints + polyline
3. Toggle round trip → verify end point matches start, route shows return leg
4. Share a plan → copy code → load it on another account → verify all data
5. Share via WhatsApp → verify message format
6. Start a trip → verify location broadcasting starts
7. Add stops (fuel, food, hotel) → verify they appear on map + in Firestore
8. Complete trip → verify status changes, stops are preserved

### Automated
- `flutter analyze` — no lint errors
- `flutter build web --release` — builds cleanly
