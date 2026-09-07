import 'package:flutter/material.dart';

import '../valve_data.dart';

class AssignedValveListScreen extends StatelessWidget {
  const AssignedValveListScreen({super.key});

  // Temporary UI fixtures only. They are clearly marked as sample data and
  // must be replaced by the backend/API repository before production use.
  static const _valves = <ValveData>[
    ValveData(valveId: 'ORBI-VALVE-001', status: 'OPEN', requested: 100, actual: 100, connected: true),
    ValveData(valveId: 'ORBI-VALVE-002', status: 'CLOSE', requested: 0, actual: 0, connected: true),
    ValveData(valveId: 'ORBI-VALVE-003', status: 'FAULT', requested: 50, actual: 47, connected: true),
    ValveData(valveId: 'ORBI-VALVE-004', status: 'STOPPED', requested: 60, actual: 60, connected: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Valves')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _valves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ValveTile(valve: _valves[index]),
      ),
    );
  }
}

class _ValveTile extends StatelessWidget {
  const _ValveTile({required this.valve});
  final ValveData valve;

  @override
  Widget build(BuildContext context) {
    final status = valve.connected ? valve.status : 'OFFLINE';
    final position = valve.actual.clamp(0, 100);

    return Card(
      child: ListTile(
        leading: Icon(_statusIcon(status)),
        title: Text(valve.valveId),
        subtitle: Text('$status  •  Position $position%'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'FAULT':
        return Icons.error_outline;
      case 'OFFLINE':
        return Icons.cloud_off_outlined;
      case 'OPEN':
      case 'CLOSE':
        return Icons.check_circle_outline;
      default:
        return Icons.pause_circle_outline;
    }
  }
}
