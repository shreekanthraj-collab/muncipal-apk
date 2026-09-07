import 'dart:convert';

/// Controller/Operator application-level command envelope.
///
/// This is intentionally separate from transport-specific firmware packets.
/// GSM and LoRa adapters can translate the command as required.
class OperatorCommand {
  final String requestId;
  final DateTime timestamp;
  final String valveId;
  final String command;
  final int? value;
  final int? expiresInMs;

  const OperatorCommand({
    required this.requestId,
    required this.timestamp,
    required this.valveId,
    required this.command,
    this.value,
    this.expiresInMs,
  });

  Map<String, dynamic> toJson() => {
        'type': 'valve_command',
        'version': 1,
        'request_id': requestId,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'valve_id': valveId,
        'command': command,
        if (value != null) 'value': value,
        if (expiresInMs != null) 'expires_in_ms': expiresInMs,
      };

  String encode() => jsonEncode(toJson());
}

/// Command names used at the Operator APK application layer.
///
/// Transport-specific IDs remain outside this model.
abstract final class OperatorCommands {
  static const open = 'OPEN';
  static const close = 'CLOSE';
  static const stop = 'STOP';
  static const emergencyStop = 'EMERGENCY_STOP';
  static const clearEmergencyStop = 'CLEAR_EMERGENCY_STOP';
  static const setPosition = 'SET_POSITION';
  static const getStatus = 'GET_STATUS';
  static const getTelemetry = 'GET_TELEMETRY';
}
