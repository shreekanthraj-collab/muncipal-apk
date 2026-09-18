class ValveData {
  final String valveId;
  final String status;
  final int requested;
  final int actual;
  final bool connected;
  final String communicationId;
  final bool ocFault;

  const ValveData({
    required this.valveId,
    required this.status,
    required this.requested,
    required this.actual,
    required this.connected,
    required this.communicationId,
    required this.ocFault,
  });

  factory ValveData.fromJson(Map<String, dynamic> json) {
    return ValveData(
      valveId: json['valve_id'] ?? '',
      status: json['status'] ?? 'STOPPED',
      requested: (json['requested'] ?? 0).toInt(),
      actual: (json['actual'] ?? 0).toInt(),
      connected: json['connected'] ?? false,
      communicationId: (json['communication_id'] ?? json['device_id'] ?? json['thing_name'] ?? '').toString(),
      ocFault: _hasOcFault(json),
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
    };
  }

  static bool _hasOcFault(Map<String, dynamic> json) {
    final direct = json['oc_trip'] ?? json['ocTrip'] ??
        json['over_current_trip'] ?? json['overCurrentTrip'];
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