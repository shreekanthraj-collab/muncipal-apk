enum OperatorCommandStatus {
  sent,
  accepted,
  executing,
  completed,
  rejected,
  failed,
  timeout,
  blocked,
}

class OperatorCommandResult {
  final String requestId;
  final String valveId;
  final String command;
  final OperatorCommandStatus status;
  final String? reason;
  final DateTime? nodeTimestamp;
  final DateTime? gatewayTimestamp;
  final DateTime? serverTimestamp;
  final int? position;

  const OperatorCommandResult({
    required this.requestId,
    required this.valveId,
    required this.command,
    required this.status,
    this.reason,
    this.nodeTimestamp,
    this.gatewayTimestamp,
    this.serverTimestamp,
    this.position,
  });

  factory OperatorCommandResult.fromJson(Map<String, dynamic> json) {
    return OperatorCommandResult(
      requestId: json['request_id'] as String,
      valveId: json['valve_id'] as String,
      command: json['command'] as String,
      status: _statusFromString(json['status'] as String),
      reason: json['reason'] as String?,
      nodeTimestamp: _parseTime(json['node_timestamp']),
      gatewayTimestamp: _parseTime(json['gateway_timestamp']),
      serverTimestamp: _parseTime(json['server_timestamp']),
      position: json['position'] as int?,
    );
  }

  static OperatorCommandStatus _statusFromString(String value) {
    switch (value.toUpperCase()) {
      case 'SENT':
        return OperatorCommandStatus.sent;
      case 'ACCEPTED':
        return OperatorCommandStatus.accepted;
      case 'EXECUTING':
        return OperatorCommandStatus.executing;
      case 'COMPLETED':
        return OperatorCommandStatus.completed;
      case 'REJECTED':
        return OperatorCommandStatus.rejected;
      case 'FAILED':
        return OperatorCommandStatus.failed;
      case 'TIMEOUT':
        return OperatorCommandStatus.timeout;
      case 'BLOCKED':
        return OperatorCommandStatus.blocked;
      default:
        throw FormatException('Unknown command status: $value');
    }
  }

  static DateTime? _parseTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
