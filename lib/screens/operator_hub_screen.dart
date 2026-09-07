import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'gateway_list_screen.dart';
import 'gateway_detail_screen.dart';
import 'operator_valves_screen.dart';
import 'valve_detail_screen.dart';
import 'schedule_screen.dart';
import 'events_history_screen.dart';
import 'alerts_settings_screen.dart';
import 'widget_style_preview_screen.dart';

class OperatorHubScreen extends StatelessWidget {
  const OperatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = <String>[
      'Dashboard','Gateway List','Gateway Detail','Valve List','Valve Detail / Control',
      'Schedule','Events / History','Alerts / Settings','Operator / Settings','Widget Style Preview'
    ];
    final routes = <Widget Function()>[
      () => const DashboardScreen(),
      () => const GatewayListScreen(),
      () => const GatewayDetailScreen(gatewayId: 'GW-001'),
      () => const OperatorValvesScreen(),
      () => const ValveDetailScreen(valveId: 'V-001'),
      () => const ScheduleScreen(),
      () => const EventsHistoryScreen(),
      () => const AlertsSettingsScreen(),
      () => const AlertsSettingsScreen(),
      () => const WidgetStylePreviewScreen(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ORBI Operator — 10 Pages')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pages.length,
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(pages[i]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => routes[i]())),
          ),
        ),
      ),
    );
  }
}
