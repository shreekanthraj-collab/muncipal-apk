import 'package:flutter/material.dart';

import 'valve_detail_screen.dart';

/// Assigned valve-list UI shell. These rows are navigation fixtures only;
/// live device state will come from the approved backend contract.
class OperatorValvesScreen extends StatelessWidget {
  const OperatorValvesScreen({super.key});

  static const _valves = [
    ('ORBI-VALVE-001', 'ONLINE'),
    ('ORBI-VALVE-002', 'OFFLINE'),
    ('ORBI-VALVE-003', 'FAULT'),
    ('ORBI-VALVE-004', 'CONTROL BLOCKED'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valves')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _valves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final valve = _valves[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text(valve.$1),
              subtitle: Text(valve.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ValveDetailScreen(valveId: valve.$1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
