class ValveCommand {
  final String valveId;
  final String command;
  final int value;

  const ValveCommand({
    required this.valveId,
    required this.command,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'valve_id': valveId,
      'command': command,
      'value': value,
    };
  }
}
