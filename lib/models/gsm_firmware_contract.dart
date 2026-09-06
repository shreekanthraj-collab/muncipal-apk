/// Exact GSM firmware Driver Discovery request currently implemented in
/// GSM-VALVE at baseline ef327ff.
///
/// This model intentionally mirrors the firmware contract. Transport is not
/// implemented here.
class GsmFirmwareDriverRequest {
  final String manufacturer;
  final String model;
  final String deviceId;
  final int slaveId;

  const GsmFirmwareDriverRequest({
    required this.manufacturer,
    required this.model,
    required this.deviceId,
    required this.slaveId,
  });

  Map<String, dynamic> toJson() => {
        'type': 'modbus_driver_request',
        'action': 'install',
        'manufacturer': manufacturer,
        'model': model,
        'device_id': deviceId,
        'slave_id': slaveId,
      };
}
