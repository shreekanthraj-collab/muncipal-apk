import 'package:flutter/material.dart';

class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({super.key});

  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  bool alerts = true;
  bool compactWidgets = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alerts / Settings')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: ListTile(leading: Icon(Icons.warning_amber_outlined), title: Text('Valve V-002 communication warning'), subtitle: Text('Demo alert • Check gateway connection'))),
      const Card(child: ListTile(leading: Icon(Icons.battery_alert_outlined), title: Text('Battery status'), subtitle: Text('Normal • Voltage hidden unless low'))),
      SwitchListTile(title: const Text('Alerts'), subtitle: const Text('Show operator alerts'), value: alerts, onChanged: (v) => setState(() => alerts = v)),
      SwitchListTile(title: const Text('Compact widgets'), subtitle: const Text('Preview alternate widget layout'), value: compactWidgets, onChanged: (v) => setState(() => compactWidgets = v)),
      const ListTile(leading: Icon(Icons.info_outline), title: Text('ORBI DRIVE'), subtitle: Text('Operator APK • UI preview • Backend not connected')),
    ]),
  );
}
