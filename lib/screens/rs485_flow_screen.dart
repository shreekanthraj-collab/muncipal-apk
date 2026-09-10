import 'package:flutter/material.dart';

/// Common RS485 monitoring page shared by GSM/LTE and LoRa valve systems.
///
/// The current values are presentation placeholders until the RS485/Modbus
/// transport is connected to the live valve data source.
class Rs485FlowScreen extends StatelessWidget {
  const Rs485FlowScreen({super.key});

  static const _valves = <_Rs485Valve>[
    _Rs485Valve('ORBI-001', 'Valve 001', 42.6, 'GSM/LTE'),
    _Rs485Valve('ORBI-002', 'Valve 002', 38.2, 'LoRa'),
    _Rs485Valve('ORBI-003', 'Valve 003', 0.0, 'LoRa'),
    _Rs485Valve('ORBI-004', 'Valve 004', 51.8, 'GSM/LTE'),
    _Rs485Valve('ORBI-005', 'Valve 005', 27.4, 'LoRa'),
    _Rs485Valve('ORBI-006', 'Valve 006', 64.1, 'GSM/LTE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RS485 / FLOW'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _valves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final valve = _valves[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(Icons.water_drop, size: 32),
              title: Text(
                valve.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${valve.id} • ${valve.transport}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    valve.flow.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('FLOW'),
                ],
              ),
            ),
          );
        },
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
