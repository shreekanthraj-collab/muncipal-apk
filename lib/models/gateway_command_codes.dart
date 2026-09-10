/// ORB DRIVE Gateway command opcodes.
///
/// These values mirror the production Gateway protocol definitions in
/// LORA-GATEWAY/gw_protocol.h. Do not change numeric values without a
/// corresponding protocol revision.
abstract final class GatewayCommandCodes {
  static const int open = 0x01;
  static const int close = 0x02;
  static const int stop = 0x03;
  static const int getStatus = 0x04;
  static const int clearFault = 0x05;
  static const int setTurns = 0x06;
  static const int setSchedule = 0x07;
  static const int clearSchedule = 0x08;
  static const int setChannel = 0x09;
  static const int voltageBypass = 0x0A;
  static const int voltageCancel = 0x0B;
  static const int setTime = 0x0C;
  static const int getSchedule = 0x0D;
  static const int setCurrent = 0x0E;
  static const int calibrate = 0x0F;
  static const int calibrationSet = 0x10;
  static const int calibrationAbort = 0x11;
  static const int enterEol = 0x12;
  static const int rebindOwner = 0x13;
  static const int setDisengageCurrent = 0x15;
}

/// Human-readable command names used by the APK UI and transport layer.
abstract final class GatewayCommandNames {
  static const String open = 'OPEN';
  static const String close = 'CLOSE';
  static const String stop = 'STOP';
  static const String getStatus = 'GET_STATUS';
  static const String clearFault = 'CLEAR_FAULT';
  static const String setPosition = 'SET_POSITION';
  static const String setTurns = 'SET_TURNS';
  static const String setSchedule = 'SET_SCHEDULE';
  static const String clearSchedule = 'CLR_SCHEDULE';
  static const String setChannel = 'SET_CHANNEL';
  static const String voltageBypass = 'VOLTAGE_BYPASS';
  static const String voltageCancel = 'VOLTAGE_CANCEL';
  static const String setTime = 'SET_TIME';
  static const String getSchedule = 'GET_SCHEDULE';
  static const String setCurrent = 'SET_CURRENT';
  static const String calibrate = 'CALIBRATE';
  static const String calibrationSet = 'CAL_SET';
  static const String calibrationAbort = 'CAL_ABORT';
  static const String enterEol = 'ENTER_EOL';
  static const String rebindOwner = 'REBIND_OWNER';
  static const String setDisengageCurrent = 'SET_DISENGAGE_CURRENT';
}

/// UI-facing command descriptor.
class GatewayCommandDefinition {
  final int opcode;
  final String name;

  const GatewayCommandDefinition({
    required this.opcode,
    required this.name,
  });
}

/// Commands exposed to the normal valve-control UI.
const List<GatewayCommandDefinition> valveControlCommands = [
  GatewayCommandDefinition(opcode: GatewayCommandCodes.open, name: GatewayCommandNames.open),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.close, name: GatewayCommandNames.close),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.stop, name: GatewayCommandNames.stop),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.getStatus, name: GatewayCommandNames.getStatus),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.clearFault, name: GatewayCommandNames.clearFault),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.setTurns, name: GatewayCommandNames.setTurns),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.setSchedule, name: GatewayCommandNames.setSchedule),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.clearSchedule, name: GatewayCommandNames.clearSchedule),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.setCurrent, name: GatewayCommandNames.setCurrent),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.setDisengageCurrent, name: GatewayCommandNames.setDisengageCurrent),
];

/// Calibration command set.
const List<GatewayCommandDefinition> calibrationCommands = [
  GatewayCommandDefinition(opcode: GatewayCommandCodes.calibrate, name: GatewayCommandNames.calibrate),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.calibrationSet, name: GatewayCommandNames.calibrationSet),
  GatewayCommandDefinition(opcode: GatewayCommandCodes.calibrationAbort, name: GatewayCommandNames.calibrationAbort),
];
