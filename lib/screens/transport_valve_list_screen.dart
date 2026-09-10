import 'package:flutter/material.dart';

import '../models/transport_type.dart';
import 'valve_detail_screen.dart';

class TransportValveListScreen extends StatelessWidget {
  final TransportType transport;

  const TransportValveListScreen({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    final isGsm = transport == TransportType.gsmLte;

    return Scaffold(
      appBar: AppBar(
        title: Text(transport.label),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(isGsm ? Icons.cell_tower : Icons.settings_input_antenna),
              title: Text(isGsm ? 'GSM Valve 001' : 'LoRa Valve 001'),
              subtitle: Text(isGsm ? 'GSM/LTE • ONLINE' : 'LoRa • ONLINE'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ValveDetailScreen(
                      transport: transport,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('ADD VALVE'),
          ),
        ],
      ),
    );
  }
}
