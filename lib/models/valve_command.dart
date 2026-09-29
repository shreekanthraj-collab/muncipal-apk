class ValveCommand {
  final String valveId;
  final String command;
  final int value;

  // SET_TIME fields
  final int? year;
  final int? month;
  final int? day;
  final int? hour;
  final int? minute;
  final int? second;
  final int? wday;

  // SET_SCHEDULE fields
  final int? slot;
  final int? enabled;
  final int? action;
  final int? days;

  const ValveCommand({
    required this.valveId,
    required this.command,
    required this.value,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.wday,
    this.slot,
    this.enabled,
    this.action,
    this.days,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'valve_id': valveId,
      'command': command,
      'value': value,
    };

    if (year != null) json['year'] = year;
    if (month != null) json['month'] = month;
    if (day != null) json['day'] = day;
    if (hour != null) json['hour'] = hour;
    if (minute != null) json['minute'] = minute;
    if (second != null) json['second'] = second;
    if (wday != null) json['wday'] = wday;

    if (slot != null) json['slot'] = slot;
    if (enabled != null) json['enabled'] = enabled;
    if (action != null) json['action'] = action;
    if (days != null) json['days'] = days;

    return json;
  }
}
