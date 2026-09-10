import 'package:flutter/material.dart';

class ValveSchedule {
  final bool enabled;
  final TimeOfDay? time;
  final int position;

  const ValveSchedule({
    required this.enabled,
    required this.time,
    required this.position,
  });

  String get timeLabel {
    if (time == null) return 'Not configured';
    final hour = time!.hour.toString().padLeft(2, '0');
    final minute = time!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
