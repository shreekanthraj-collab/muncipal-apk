import 'package:flutter/material.dart';

class ValveDetailScreen extends StatelessWidget {
  const ValveDetailScreen({super.key, required this.valveId});

  final String valveId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(valveId)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('STATUS'),
              subtitle: Text('No live device data connected yet.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.tune),
              title: Text('CONTROL'),
              subtitle: Text('Open / Close / Stop controls will be connected to the approved command contract.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.health_and_safety_outlined),
              title: Text('HEALTH'),
              subtitle: Text('Health telemetry will be connected through the backend.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('SCHEDULE'),
              subtitle: Text('Schedule management will be added after the API contract is frozen.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('EVENTS'),
              subtitle: Text('Read-only event history will be connected to the backend.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.build_outlined),
              title: Text('MAINTENANCE'),
              subtitle: Text('Maintenance records will be connected later.'),
            ),
          ),
        ],
      ),
    );
  }
}
