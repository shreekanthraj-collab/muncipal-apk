class ValveData {
  final String valveId;
  final String status;
  final int requested;
  final int actual;
  final bool connected;
  final String communicationId;
  final bool ocFault;
  final bool lowVoltageBypass;
  final bool lowVoltageBypassKnown;
  final String gwid;

  const ValveData({
    required this.valveId,
    required this.status,
    required this.requested,
    required this.actual,
    required this.connected,
    required this.communicationId,
    required this.ocFault,
    required this.lowVoltageBypass,
    this.lowVoltageBypassKnown = false,
    this.gwid = '',
  });

  factory ValveData.fromJson(Map<String, dynamic> json) {
    final rawGwid = json['gwid'] ?? json['gateway_id'] ?? '';
    return ValveData(
      valveId: json['valve_id'] ?? '',
      status: json['status'] ?? 'STOPPED',
      requested: (json['requested'] ?? 0).toInt(),
      actual: (json['actual'] ?? 0).toInt(),
      connected: json['connected'] ?? false,
      communicationId: (json['communication_id'] ??
              json['device_id'] ??
              json['thing_name'] ??
              '')
          .toString(),
      ocFault: _hasOcFault(json),
      lowVoltageBypass: _hasLowVoltageBypass(json),
      lowVoltageBypassKnown: _containsLowVoltageBypass(json),
      gwid: rawGwid.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valve_id': valveId,
      'status': status,
      'requested': requested,
      'actual': actual,
      'connected': connected,
      'communication_id': communicationId,
      'oc_fault': ocFault,
      if (lowVoltageBypassKnown) 'low_voltage_bypass': lowVoltageBypass,
      'gwid': gwid,
    };
  }

  static bool _containsLowVoltageBypass(Map<String, dynamic> json) {
    if (json.containsKey('low_voltage_bypass') ||
        json.containsKey('lowVoltageBypass')) {
      return true;
    }
    final faults = json['faults'];
    return faults is Map &&
        (faults.containsKey('low_voltage_bypass') ||
            faults.containsKey('lowVoltageBypass'));
  }

  static bool _hasLowVoltageBypass(Map<String, dynamic> json) {
    final direct = json['low_voltage_bypass'] ?? json['lowVoltageBypass'];
    if (direct is bool) return direct;
    if (direct is num) return direct != 0;
    final faults = json['faults'];
    if (faults is Map) {
      final value = faults['low_voltage_bypass'] ?? faults['lowVoltageBypass'];
      if (value is bool) return value;
      if (value is num) return value != 0;
    }
    return false;
  }

  static bool _hasOcFault(Map<String, dynamic> json) {
    final direct = json['oc_trip'] ??
        json['ocTrip'] ??
        json['over_current_trip'] ??
        json['overCurrentTrip'];
    if (direct is bool) return direct;
    if (direct is num) return direct != 0;
    final flags = json['fault_flags'] ?? json['faultFlags'] ?? json['faults'];
    if (flags is num) return flags.toInt() != 0;
    if (flags is List) {
      return flags.any((f) {
        final s = f.toString().toUpperCase();
        return s.contains('OC') || s.contains('OVER_CURRENT');
      });
    }
    if (flags is String) {
      final s = flags.toUpperCase();
      return s.contains('OC') || s.contains('OVER_CURRENT');
    }
    final status = (json['status'] ?? '').toString().toUpperCase();
    return status.contains('OC TRIP') ||
        status.contains('OVERCURRENT') ||
        status.contains('OVER CURRENT');
  }
}
