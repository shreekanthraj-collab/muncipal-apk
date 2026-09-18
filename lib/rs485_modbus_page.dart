import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/valve_storage.dart';

class Rs485ModbusPage extends StatefulWidget {
  const Rs485ModbusPage({super.key});

  @override
  State<Rs485ModbusPage> createState() => _Rs485ModbusPageState();
}

class _Rs485ModbusPageState extends State<Rs485ModbusPage> {
  String valve = '';
  bool scanning = false;
  DateTime? lastScan;
  List<String> valveIds = const [];

  final List<_Rs485Device> devices = const [
    _Rs485Device('Flow Sensor 1', '1', 'FS-100', '12.5 FL/sec', true),
    _Rs485Device('Flow Sensor 2', '2', 'FS-100', '10.8 FL/sec', true),
    _Rs485Device('Overflow Tank', '3', 'LT-200', '75 %', true),
    _Rs485Device('Water Quality Sensor', '4', 'WQ-300', 'pH 7.2', true),
    _Rs485Device('Energy Meter', '5', 'EM-500', '230 V', false),
    _Rs485Device('Pressure Sensor', '6', '--', '--', null),
    _Rs485Device('Temperature', '7', '--', '--', null),
    _Rs485Device('Custom Device', '8', '--', '--', null),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadValveIds();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadValveIds() async {
    final ids = await ValveStorage.loadValveIds();
    if (!mounted) return;
    setState(() {
      valveIds = ids;
      if (valve.isEmpty || !ids.contains(valve)) {
        valve = ids.isEmpty ? '' : ids.first;
      }
    });
  }
class _TopSelectionCard extends StatelessWidget {
  final String valve;
  final List<String> valveIds;
  final ValueChanged<String> onValveChanged;

  const _TopSelectionCard({
    required this.valve,
    required this.valveIds,
    required this.onValveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DropdownField(
              label: 'VALVE ID (GSM + LoRa)',
              value: valve,
              values: valveIds,
              onChanged: onValveChanged,
            ),
            if (valveIds.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'No valves saved on MAP. Add the valve from MAP VIEW first.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}


