import 'package:flutter/material.dart';

class EventsHistoryScreen extends StatelessWidget {
  const EventsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Events / History')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      Card(child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Valve V-001 opened'), subtitle: Text('Today 08:32 • Demo event'))),
      Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Gateway heartbeat'), subtitle: Text('Today 08:30 • Online'))),
      Card(child: ListTile(leading: Icon(Icons.stop_circle_outlined), title: Text('Valve V-002 closed'), subtitle: Text('Yesterday 18:05 • Operator command'))),
    ]),
  );
}
