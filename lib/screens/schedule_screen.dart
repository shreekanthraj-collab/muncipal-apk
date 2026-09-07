import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Schedule')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: Icon(Icons.schedule), title: Text('Morning irrigation'), subtitle: Text('06:00 • Valve V-001 • Open 30% • Demo'))),
      Card(child: ListTile(leading: Icon(Icons.schedule), title: Text('Evening cycle'), subtitle: Text('18:00 • Valve V-002 • Open 50% • Demo'))),
      SizedBox(height: 16),
      Text('Scheduling bar', style: TextStyle(fontWeight: FontWeight.bold)),
      LinearProgressIndicator(value: .65),
    ]),
  );
}
