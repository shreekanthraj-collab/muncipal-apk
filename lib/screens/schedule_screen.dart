import 'package:flutter/material.dart';

import '../models/schedule_slot.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<ScheduleSlot> _slots = [];
  int _nextId = 1;

  Future<void> _addSlot() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: 'SET SCHEDULE TIME',
    );
    if (pickedTime == null || !mounted) return;

    final targetPosition = await _pickTargetPosition();
    if (targetPosition == null || !mounted) return;

    setState(() {
      _slots.add(ScheduleSlot(
        id: 'sched_${_nextId++}',
        time: pickedTime,
        targetPosition: targetPosition,
      ));
      _slots.sort((a, b) =>
          (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));
    });
  }

  Future<int?> _pickTargetPosition() {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [0, 25, 50, 75, 100].map((value) {
              return ElevatedButton(
                onPressed: () => Navigator.pop(context, value),
                child: Text('$value%'),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _removeSlot(String id) => setState(() => _slots.removeWhere((s) => s.id == id));

  void _toggleSlot(String id, bool value) {
    setState(() => _slots.firstWhere((s) => s.id == id).enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlot,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add schedule'),
      ),
      body: _slots.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 64),
                  const SizedBox(height: 16),
                  const Text('No schedules yet'),
                  const SizedBox(height: 8),
                  const Text('Tap "Add schedule" and set a time on the clock.'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addSlot,
                    icon: const Icon(Icons.add_alarm),
                    label: const Text('Add schedule'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time_filled),
                    title: Text(slot.timeLabel),
                    subtitle: Text('${slot.label} • Every day'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(value: slot.enabled, onChanged: (v) => _toggleSlot(slot.id, v)),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeSlot(slot.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
