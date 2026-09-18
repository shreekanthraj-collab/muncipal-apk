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
}