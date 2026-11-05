# Municipal APK role and zone-control policy

## Purpose

Define the Municipal APK access contract for Admin and line-operator accounts. The server is the authority for identity, zone assignment, control ownership, and command authorization. APK visibility rules are a usability layer and must never be treated as the security boundary.

## Roles

### Municipal Admin

- View telemetry for every zone, ward, and registered valve in the municipality.
- Full operational access to all zones and valves.
- Claim, release, and administratively recover zone control.
- Manage operator accounts, assignments, and access.
- Perform OPEN, CLOSE, valve positioning, and emergency stop.
- View ownership state and audit history.

### Line operator

- View telemetry for all zones, wards, and registered valves (read-only outside the assigned zone).
- Assigned to one zone for control.
- May use valve positioning and Emergency Stop only within the assigned zone.
- Must not receive OPEN or CLOSE controls or command permissions.
- Must not receive calibration, OTA, voltage/current configuration, scheduling, bypass, rebind, registration, or operator-management permissions unless a separate explicit policy is approved.
- May claim and explicitly release control of their assigned zone.
- Cannot claim another operator's zone or perform administrative recovery.

## Exclusive zone ownership

- One active controlling APK/operator per zone.
- The server stores the owner and the claim/release audit events.
- Ownership has no automatic timeout.
- App closure, uninstall, logout, phone shutdown, network loss, and session expiry do not release ownership.
- Only the owning operator can explicitly release the zone.
- Admin may perform a separate audited recovery/override.
- A competing APK may continue viewing telemetry but cannot issue control commands for an owned zone.
- Claim must be atomic on the server so simultaneous claims cannot both succeed.

## Command policy

| Action | Admin | Line operator |
|---|---|---|
| View telemetry | All zones | All zones |
| Valve positioning | All zones | Assigned zone only, while holding zone ownership |
| OPEN | All zones | Denied |
| CLOSE | All zones | Denied |
| Emergency Stop | All zones | Assigned zone only |
| Calibration / OTA / configuration / scheduling | Admin only | Denied |
| Claim / release zone | All zones | Assigned zone only |
| Ownership recovery | Yes, audited | Denied |

## Required server contract

The APK must consume authoritative role and assignment fields returned by municipal OTP verification. It must not infer a role from a login-screen selector, phone number, locally cached preference, or client-supplied value.

The server must expose authenticated zone-control claim, state, release, and audited Admin-recovery operations. Every command endpoint must validate:

1. Operator identity and active session.
2. Municipality, assigned zone, and valve placement.
3. Role/action permission.
4. Current zone owner for every control action.
5. Ownership and permission again at command dispatch where commands are queued.

The server must reject OPEN/CLOSE from line operators even if the request is sent outside the APK UI. It must also reject positioning/E-stop outside the operator's assigned zone or when another operator owns that zone.

## Offline and reconnect behavior

- An offline APK may display cached telemetry with an explicit stale/offline indicator.
- It must not queue control actions locally for later automatic replay.
- On reconnect, it must fetch the current server ownership state before enabling controls.
- A disconnected owner remains the owner until explicit release or Admin recovery.

## Implementation boundary

This document records the approved APK behavior and integration contract. UI hiding alone is not authorization. The APK role-aware controls and server-side enforcement must be delivered and tested together before production use. Do not alter actuator firmware motor/safety logic as part of this access-control work.
