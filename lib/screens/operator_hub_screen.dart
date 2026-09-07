import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'events_history_screen.dart';
import 'alerts_settings_screen.dart';

class OperatorHubScreen extends StatelessWidget {
  const OperatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = <String>[
      'Dashboard','Gateway List','Gateway Detail','Valve List','Valve Detail / Control',
      'Schedule','Events / History','Alerts / Faults','Operator / Settings','Widget Style Preview'
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ORBI Operator — 10 Pages')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pages.length,
        itemBuilder: (context, i) {
          return Card(child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(pages[i]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (i == 5) Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
              if (i == 6) Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsHistoryScreen()));
              if (i == 8) Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsSettingsScreen()));
            },
          ));
        },
      ),
    );
  }
}
