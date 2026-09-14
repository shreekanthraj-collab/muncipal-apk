# ORBI Municipal APK — Frozen UI Specification

This document is the **FINAL functional UI baseline** for the APK. The five pages below are frozen before wiring and Android Studio visual refinement.

## Screen order

1. Login
2. Page 1 — Zone / Ward Home
3. Page 2 — GSM / LTE Valve Control
4. Page 3 — LoRa Valve Control
5. Page 4 — MAP
6. Page 5 — RS485 / MODBUS

## Login — Screen before Page 1

- Admin
- Agent / Operator
- Password
- Forgot Password
- Mobile-number authentication
- Re-authentication when the registered mobile number or phone changes
- App supports phones using a registered mobile number
- Visual styling may be refined later in Android Studio; functionality is frozen here

## Page 1 — Zone / Ward Home

- Zone No. selector
- ADD ZONE
- Ward No. selector
- ADD WARD No.
- GSM / LTE Valve View
- LoRa Valve View
- MAP View
- RS485 View
- This is the landing page after successful Login

## Page 2 — GSM / LTE Valve Control

- ADD NEW VALVE / ADD VALVE
- GSM valve IDs only in this page's Valve ID selector
- GSM Online status
- FW VERSION
- **OTA / Firmware Update is present on GSM/LTE page**
- Sleep Bypass / Active / Off in the top-middle status area
- Valve position: Requested and Actual
- 0 / 25 / 50 / 75 / 100% controls
- SET VALVE TO % / SET % OPEN
- OPEN / CLOSE / STOP / E-STOP
- Valve Calibration: START / OPEN / CLOSE / COMPLETE-SAVE TO NVS
- Voltage / Bypass
- Over Current: OC Trip and Reset
- **Low-voltage bypass operator response: CONFIRM and CANCEL**
- Scheduling / Clock
- View Schedule / Start / Set Schedule / Cancel All / Clock View
- Start Time / Stop Time / Date Set
- **WEEK is the final scheduling item**
- **OWNER REBIND is the absolute last button**

### GSM OTA rule

GSM/LTE valves may receive firmware updates through the GSM/LTE path. OTA is a GSM/LTE function and must not be removed from Page 2.

### Low-voltage bypass rule

When the low-voltage bypass condition is presented to the operator, Page 2 provides **CONFIRM** and **CANCEL** for the bypass response. This is separate from the OTA function.

## Page 3 — LoRa Valve Control

- ADD NEW VALVE / ADD VALVE
- LoRa valve IDs only in this page's Valve ID selector
- LoRa Online status
- LoRa STATUS
- RSSI shown as a **3-bar indicator**; do not display numeric RSSI in the frozen UI
- SF
- FW VERSION
- Valve position: Requested and Actual
- 0 / 25 / 50 / 75 / 100% controls
- SET VALVE TO % / SET % OPEN
- OPEN / CLOSE / STOP / E-STOP
- Valve Calibration: START / OPEN / CLOSE / COMPLETE-SAVE TO NVS
- Voltage / Bypass
- Over Current: OC Trip and Reset
- Scheduling / Clock
- View Schedule / Start / Set Schedule / Cancel All / Clock View
- Start Time / Stop Time / Date Set
- **WEEK is the final scheduling item**
- **OWNER REBIND is the absolute last button**
- **NO OTA control**
- **NO firmware update through the LoRa gateway**

### LoRa firmware rule

LoRa valves do not receive firmware updates through the LoRa gateway. The APK must not create or expose a LoRa-gateway OTA path.

## Page 4 — MAP

Page 4 is frozen to the approved MAP reference image and must be implemented with the following structure and behavior:

### Header

- Back arrow
- Center title: **MAP**
- Overflow menu at top right

### Map identity / add valve row

- **Map Name** field
- Example/reference value: `Farm A - North Field`
- Edit icon on the Map Name field
- **ADD VALVE** button on the right

### Map area

- Phone **My Location (GPS)** card/indicator
- Display current latitude and longitude when GPS is available
- Map surface showing the user's location
- Valve markers on the map
- Each valve marker displays the corresponding Valve ID
- Map controls include current-location/recenter and zoom + / zoom − controls
- Actual map provider/SDK and live GPS wiring are implementation details; the frozen UI structure must remain as shown

### Valve list

- Section title: **Valve List (N)**
- List contains both GSM/LTE and LoRa valves
- Each valve entry shows:
  - Valve ID
  - Latitude
  - Longitude
  - REMOVE button
  - REBIND button
- Valve selection must work from the combined GSM + LoRa list

### Add-valve confirmation

After a valve is successfully added, show a modal confirmation matching the approved flow:

- Green success icon
- **Valve Added Successfully**
- Valve ID
- Latitude
- Longitude
- **OK** button

### Remove-valve confirmation

After a valve is successfully removed, show a modal confirmation matching the approved flow:

- Red delete icon
- **Valve Removed**
- Valve ID
- Latitude
- Longitude
- **OK** button

### Page 4 bottom navigation

The approved reference shows the common bottom navigation with:

- Home — Page 1
- GSM — Page 2
- LoRa — Page 3
- MAP — Page 4, selected/highlighted
- RS485 — Page 5

Page 4 must not remove or replace the common navigation structure.

## Page 5 — RS485 / MODBUS

- **Combined Valve ID selector containing both GSM/LTE and LoRa valves at the top**
- ADD VALVE
- Flow Sensor 1 — FL/sec
- Flow Sensor 2 — FL/sec
- Overflow Tank — FULL / EMPTY
- Water Quality Sensor — % / contents
- ADD NEW SENSOR
- REMOVE SENSOR
- SEARCH FOR NEW DEVICE DRIVERS

The APK does **not** contain a device/sensor driver list. The driver-search action opens the external web driver page in the browser. Manufacturer/model selection and driver download/install are handled by that web page and delivered directly to the device.

## Final functional rules before wiring

- Pages 1–5 above are the frozen APK functional structure.
- Visual spacing, colors, typography, icons and other presentation refinements may be adjusted later in Android Studio without changing the frozen functions or page structure.
- Page 2 GSM/LTE keeps OTA.
- Page 3 LoRa has no OTA and no firmware update through the LoRa gateway.
- Page 2 includes the low-voltage bypass **CONFIRM / CANCEL** operator response.
- Page 4 and Page 5 use combined GSM + LoRa Valve ID selection.
- Page 2 and Page 3 use their respective technology-specific Valve ID selections.
- OWNER REBIND remains the final button on Pages 2 and 3.
- WEEK remains the final scheduling item on Pages 2 and 3.
- Page 4 uses the approved MAP image as the visual reference for implementation.

## Wiring / transport rule

Existing valve command transport remains the basis for the control buttons. The UI must not invent a gateway OTA path or alter the embedded-device firmware protocol. GSM OTA follows the existing GSM/LTE firmware-update path; LoRa OTA is explicitly excluded.
