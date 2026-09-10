import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Common RS485 monitoring page shared by GSM/LTE and LoRa valve systems.
///
/// The eight slots are the fixed RS485 device framework. Live discovery and
/// Modbus values can be connected to the transport layer without changing
/// this UI.
class Rs485FlowScreen extends StatelessWidget {
  const Rs485FlowScreen({super.key});

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

  Future<void> _searchDrivers(BuildContext context, _Rs485Valve valve) async {
    final query = Uri.encodeComponent('RS485 ${valve.name} Modbus driver');
    final uri = Uri.parse('https://www.google.com/search?q=$query');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Chrome for driver search.')),
      );
    }
  }

  void _openValve(BuildContext context, _Rs485Valve valve) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(valve.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${valve.id} • ${valve.transport}'),
            const SizedBox(height: 16),
            const Text(
              'NEW DEVICE FOUND',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'If a new RS485 device is connected, search for its driver in Chrome, then download and install the required driver on the host system.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          ElevatedButton.icon(
            onPressed: () => _searchDrivers(context, valve),
            icon: const Icon(Icons.search),
            label: const Text('SEARCH DRIVERS IN CHROME'),
          ),
        ],
      ),
    );
  }

  void _scanForNewDevice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('NEW DEVICE FOUND'),
        content: const Text(
          'Connect the new RS485 device, then use SEARCH DRIVERS IN CHROME to find and download the required driver. Driver installation is performed on the host system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              final first = _valves.first;
              _searchDrivers(context, first);
            },
            icon: const Icon(Icons.search),
            label: const Text('SEARCH DRIVERS IN CHROME'),
          ),
        ],
      ),
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
          IconButton(
            tooltip: 'New device found / driver search',
            onPressed: () => _scanForNewDevice(context),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: _valves.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final valve = _valves[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: const Icon(Icons.water_drop, size: 32),
                title: Text(
                  valve.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${valve.id} • ${valve.transport}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          valve.flow.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('FLOW'),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _openValve(context, valve),
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
