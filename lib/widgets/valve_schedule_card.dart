import 'package:flutter/material.dart';

class ValveScheduleCard extends StatelessWidget {
  final bool enabled;
  final TimeOfDay? time;
  final int position;
  final VoidCallback onPressed;
  final ValueChanged<bool> onEnabledChanged;

  const ValveScheduleCard({
    super.key,
    required this.enabled,
    required this.time,
    required this.position,
    required this.onPressed,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = time == null ? 'Not configured' : time!.format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Switch(value: enabled, onChanged: onEnabledChanged),
              ],
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Next action'),
              subtitle: Text('$timeText  •  Set valve to $position%'),
              trailing: OutlinedButton(
                onPressed: onPressed,
                child: const Text('EDIT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
