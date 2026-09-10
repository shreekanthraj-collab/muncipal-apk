import 'package:flutter/material.dart';

/// Common RS485 monitoring page shared by GSM/LTE and LoRa valve systems.
///
/// The current flow values are presentation placeholders until the
/// RS485/Modbus transport is connected to the live valve data source.
class Rs485FlowScreen extends StatelessWidget {
  const Rs485FlowScreen({super.key});

  // Fixed eight-slot RS485 device framework.
  static const _valves = <_Rs485Valve>[
    _Rs485Valve('ORBI-001', 'Valve 001', 42.6, 'GSM/LTE'),
    _Rs485Valve('ORBI-002', 'Valve 002', 38.2, 'LoRa'),
    _Rs485Valve('ORBI-003', 'Valve 003', 0.0, 'LoRa'),
    _Rs485Valve('ORBI-004', 'Valve 004', 51.8, 'GSM/LTE'),
    _Rs485Valve('ORBI-005', 'Valve 005', 27.4, 'LoRa'),
    _Rs485Valve('ORBI-006', 'Valve 006', 64.1, 'GSM/LTE'),
    _Rs485Valve('ORBI-007', 'Valve 007', 19.8, 'LoRa'),
    _Rs485Valve('ORBI-008', 'Valve 008', 33.5, 'GSM/LTE'),
  ];

  void _driverSearch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching for new RS485 devices...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RS485 / FLOW',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              onPressed: () => _driverSearch(context),
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'NEW DEVICE FOUND\nDRIVER SEARCH',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 52),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: _valves.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final valve = _valves[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: const Icon(Icons.water_drop, size: 32),
                title: Text(valve.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                subtitle: Text('${valve.id} • ${valve.transport}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(valve.flow.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text('FLOW'),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Rs485Valve {
  final String id;
  final String name;
  final double flow;
  final String transport;

  const _Rs485Valve(this.id, this.name, this.flow, this.transport);
}
