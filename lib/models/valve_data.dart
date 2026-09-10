class ValveData {
  final String valveId;
  final String status;
  final int requested;
  final int actual;
  final bool connected;
  final int rssi;
  final String firmwareVersion;
  final double batteryVoltage;
  final bool batteryLowBypass;
  final bool overCurrent;
  final double overCurrentThresholdA;

  const ValveData({
    required this.valveId,
    required this.status,
    required this.requested,
    required this.actual,
    required this.connected,
    this.rssi = 0,
    this.firmwareVersion = '—',
    this.batteryVoltage = 0,
    this.batteryLowBypass = false,
    this.overCurrent = false,
    this.overCurrentThresholdA = 0,
  });

  factory ValveData.fromJson(Map<String, dynamic> json) {
    return ValveData(
      valveId: json['valve_id'] ?? '',
      status: json['status'] ?? 'STOPPED',
      requested: (json['requested'] ?? 0).toInt(),
      actual: (json['actual'] ?? 0).toInt(),
      connected: json['connected'] ?? false,
      rssi: (json['rssi'] ?? 0).toInt(),
      firmwareVersion: json['firmware_version'] ?? '—',
      batteryVoltage: (json['battery_voltage'] ?? 0).toDouble(),
      batteryLowBypass: json['battery_low_bypass'] ?? false,
      overCurrent: json['over_current'] ?? false,
      overCurrentThresholdA: (json['over_current_threshold_a'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valve_id': valveId,
      'status': status,
      'requested': requested,
      'actual': actual,
      'connected': connected,
      'rssi': rssi,
      'firmware_version': firmwareVersion,
      'battery_voltage': batteryVoltage,
      'battery_low_bypass': batteryLowBypass,
      'over_current': overCurrent,
      'over_current_threshold_a': overCurrentThresholdA,
    };
  }
}
