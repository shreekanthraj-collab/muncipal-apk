import 'dart:convert';

/// GSM JSON contract models.
/// Prototype/API-model layer only: no MQTT/AWS transport is performed here.
class GsmDeviceState {
  final String type;
  final int version;
  final String valveId;
  final String connection;
  final int openingPercent;
  final String system;
  final String voltage;
  final String motor;
  final String rs485;
  final String? fault;

  const GsmDeviceState({
    this.type = 'gsm_valve_state',
    this.version = 1,
    required this.valveId,
    required this.connection,
    required this.openingPercent,
    required this.system,
    required this.voltage,
    required this.motor,
    required this.rs485,
    this.fault,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'version': version,
        'valve_id': valveId,
        'connection': connection,
        'opening_percent': openingPercent,
        'health': {
          'system': system,
          'voltage': voltage,
          'motor': motor,
          'rs485': rs485,
        },
        if (fault != null) 'fault': fault,
      };

  String encode() => jsonEncode(toJson());
}

class GsmCommand {
  final String command;
  final String valveId;
  final int? value;

  const GsmCommand({required this.command, required this.valveId, this.value});

  Map<String, dynamic> toJson() => {
        'type': 'gsm_valve_command',
        'version': 1,
        'valve_id': valveId,
        'command': command,
        if (value != null) 'value': value,
      };

  String encode() => jsonEncode(toJson());
}

class GsmSleepConfig {
  final bool sleepBypass;
  final int sleepSeconds;
  final int wakeupSeconds;

  const GsmSleepConfig({
    this.sleepBypass = false,
    this.sleepSeconds = 300,
    this.wakeupSeconds = 30,
  });

  Map<String, dynamic> toJson() => {
        'type': 'gsm_sleep_config',
        'version': 1,
        'sleep_bypass': sleepBypass,
        'sleep_seconds': sleepSeconds,
        'wakeup_seconds': wakeupSeconds,
      };

  String encode() => jsonEncode(toJson());
}

class GsmOtaRequest {
  final String valveId;
  final String targetVersion;

  const GsmOtaRequest({required this.valveId, required this.targetVersion});

  Map<String, dynamic> toJson() => {
        'type': 'gsm_ota_request',
        'version': 1,
        'valve_id': valveId,
        'target_version': targetVersion,
      };

  String encode() => jsonEncode(toJson());
}
