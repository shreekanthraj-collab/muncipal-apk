# ORBI APK — Frozen Baseline vs Remaining Implementation

## Purpose
This document records the implementation boundary for the ORBI APK. The frozen UI/architecture must not be redesigned or replaced. Work proceeds underneath the frozen baseline, part by part.

## Frozen baseline — DO NOT CHANGE

### UI
- 10 APK pages
- Map page
- Scrollable valve list on each applicable page
- Connected-valve count shown through the agreed controls on all applicable pages
- Existing navigation/layout/visual decisions already committed

### Existing firmware/API contract — REUSE
| APK feature | Existing JSON | Action |
|---|---|---|
| OPEN / CLOSE | Existing | Reuse |
| E-STOP | Existing | Reuse |
| Opening % | Existing | Reuse |
| STATUS | Existing | Reuse |
| Calibration | Existing | Reuse |
| Protection / faults | Existing | Reuse |
| Current min/max | Existing | Reuse |
| Motor disengage current | Existing | Reuse |
| Voltage trip | Existing | Reuse |
| Sleep / Wakeup | Existing | Reuse |
| Scheduling | Existing | Reuse |
| OTA | Existing / verify | Reuse or add |
| RS485 8 slots | Existing | DO NOT CHANGE |

## New implementation only
1. New Device Found — add as a discovery layer without changing the existing device contract.
2. Driver Discovery v1 — add without changing the RS485 8-slot framework.

## Verification / implementation order
1. Verify Device Model against the frozen commit.
2. Verify existing JSON adapter against the real firmware contract.
3. Verify command mapping.
4. Verify status/event mapping.
5. Wire verified data into the frozen 10 pages.
6. Add New Device Found.
7. Add Driver Discovery v1.
8. Build APK.
9. Test APK end-to-end.
10. Connect AWS last.

## Rules
- Inspect before modifying.
- Preserve existing working code.
- Make the smallest change needed for the current step.
- Do not invent firmware JSON fields, commands, events, or behavior.
- If the firmware contract cannot be verified, stop at that boundary.
- Do not redesign the frozen UI.
- Do not change the RS485 8-slot architecture.
- Do not wire AWS before local APK integration and testing are complete.

## Current verification checkpoint
The existing `ValveData` model at commit `9c07acd8186770e6e4b7cb8302fb7999d852dec5` was verified to contain `valveId`, `status`, `requested`, `actual`, `connected`, plus JSON serialization/deserialization. This is only the basic valve model; it does not by itself prove the complete frozen data contract.
