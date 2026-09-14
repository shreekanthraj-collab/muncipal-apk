# ORBI Municipal APK — Frozen UI Specification

This document is the implementation baseline agreed for the APK UI.

## Screen order

1. Login
2. GSM / LTE Valve View
3. LoRa Valve View
4. MAP
5. RS485 / MODBUS

## Login

- Admin
- Agent / Operator
- Password
- Forgot Password
- Mobile-number authentication
- Re-authentication when the registered mobile number or phone changes

## Page 1 — Zone / Ward Home

- Zone No.
- Ward No.
- GSM / LTE Valve View
- LoRa Valve View
- MAP View
- RS485 View

## Page 2 — GSM / LTE

- ADD NEW VALVE / ADD VALVE
- Combined Valve ID selection is used by the application architecture
- FW VERSION
- Sleep Bypass / Active in the top-middle status area
- Valve position and 0 / 25 / 50 / 75 / 100% controls
- SET % OPEN
- OPEN / CLOSE / STOP / E-STOP
- Valve Calibration
- Voltage / Bypass
- Current / Over Current
- Scheduling / Clock
- WEEK is the final scheduling control
- OWNER REBIND is the absolute last button

## Page 3 — LoRa

- ADD NEW VALVE / ADD VALVE
- Combined Valve ID selection
- LoRa STATUS
- RSSI shown as bars
- SF
- FW VERSION
- Valve position and common valve controls
- Valve Calibration
- Voltage / Bypass
- Current / Over Current
- Scheduling / Clock
- WEEK is the final scheduling control
- OWNER REBIND is the absolute last button
- **No OTA control**
- **No firmware update through the LoRa gateway**

## Page 4 — MAP

- Combined GSM + LoRa Valve ID selection
- ADD VALVE
- Phone GPS / map area
- Valve markers
- Valve list with valve ID and latitude / longitude
- REMOVE
- REBIND

## Page 5 — RS485 / MODBUS

- Combined GSM + LoRa Valve ID selection at the top
- ADD VALVE
- Flow Sensor 1 — FL/sec
- Flow Sensor 2 — FL/sec
- Overflow Tank — FULL / EMPTY
- Water Quality Sensor — % / contents
- ADD NEW SENSOR
- REMOVE SENSOR
- SEARCH FOR NEW DEVICE DRIVERS

The APK does **not** contain a device/sensor driver list. The driver-search action opens the external web driver page in the browser. Manufacturer/model selection and driver download/install are handled by that web page and delivered directly to the device.

## Wiring / transport rule

Existing valve command transport remains the basis for the control buttons. The UI must not invent a gateway OTA path or alter the embedded-device firmware protocol.
