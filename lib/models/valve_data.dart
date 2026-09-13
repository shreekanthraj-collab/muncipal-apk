class ValveData {
  final String valveId;
  final String status;
  final int requested;
  final int actual;
  final bool connected;
  final int? rssi;

  const ValveData({
    required this.valveId,
    required this.status,
    required this.requested,
    required this.actual,
    required this.connected,
    this.rssi,
  });

  factory ValveData.fromJson(Map<String, dynamic> json) {
    final rawRssi = json['rssi'];

    return ValveData(
      valveId: json['valve_id'] ?? '',
      status: json['status'] ?? 'STOPPED',
      requested: (json['requested'] ?? 0).toInt(),
      actual: (json['actual'] ?? 0).toInt(),
      connected: json['connected'] ?? false,
      rssi: rawRssi is num ? rawRssi.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valve_id': valveId,
      'status': status,
      'requested': requested,
      'actual': actual,
      'connected': connected,
      if (rssi != null) 'rssi': rssi,
    };
  }
}
