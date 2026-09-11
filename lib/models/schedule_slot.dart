import 'package:flutter/material.dart';

/// A single recurring daily schedule entry, e.g. "Open to 75% every day at 6:00 AM".
class ScheduleSlot {
  final String id;
  TimeOfDay time;
  int targetPosition;
  bool enabled;

  ScheduleSlot({
    required this.id,
    required this.time,
    required this.targetPosition,
    this.enabled = true,
  });

  String get label => targetPosition == 0 ? 'CLOSE' : 'OPEN TO $targetPosition%';

  String get timeLabel {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
