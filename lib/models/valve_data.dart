class ValveData {
  final String valveId;
  final String status;
  final int requested;
  final int actual;
  final bool connected;
  final String gwid;

  const ValveData({
    required this.valveId,
    required this.status,
    required this.requested,
    required this.actual,
    required this.connected,
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
      'gwid': gwid,
    };
  }
}