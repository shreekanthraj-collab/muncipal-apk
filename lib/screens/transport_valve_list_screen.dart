import 'package:flutter/material.dart';

import '../models/transport_type.dart';
import 'valve_detail_screen.dart';

class TransportValveListScreen extends StatefulWidget {
  final TransportType transport;

  const TransportValveListScreen({super.key, required this.transport});

  @override
  State<TransportValveListScreen> createState() => _TransportValveListScreenState();
}

class _TransportValveListScreenState extends State<TransportValveListScreen> {
  late final List<_TransportValve> valves;

  @override
  void initState() {
    super.initState();
    final prefix = widget.transport == TransportType.gsmLte ? 'GSM' : 'LoRa';
    valves = [
      _TransportValve('ORBI-001', '$prefix Valve 001'),
    ];
  }

  Future<void> _addValve() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ADD ${widget.transport.label} VALVE'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Valve name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || name == null) return;

    setState(() {
      final number = valves.length + 1;
      valves.add(
        _TransportValve(
          'ORBI-${number.toString().padLeft(3, '0')}',
          name,
        ),
      );
    });
  }

  void _openValve(_TransportValve valve) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ValveDetailScreen(
          transport: widget.transport,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGsm = widget.transport == TransportType.gsmLte;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transport.label),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: valves.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == valves.length) {
            return OutlinedButton.icon(
              onPressed: _addValve,
              icon: const Icon(Icons.add),
              label: Text('ADD ${isGsm ? 'GSM/LTE' : 'LoRa'} VALVE'),
            );
          }

          final valve = valves[index];
          return Card(
            child: ListTile(
              leading: Icon(
                isGsm ? Icons.cell_tower : Icons.settings_input_antenna,
              ),
              title: Text(
                valve.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${valve.id} • ${widget.transport.label} • ONLINE',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openValve(valve),
            ),
          );
        },
      ),
    );
  }
}

class _TransportValve {
  final String id;
  final String name;

  const _TransportValve(this.id, this.name);
}
