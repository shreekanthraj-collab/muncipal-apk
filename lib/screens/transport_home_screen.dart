import 'package:flutter/material.dart';

import '../models/transport_type.dart';
import 'transport_valve_list_screen.dart';

class TransportHomeScreen extends StatelessWidget {
  const TransportHomeScreen({super.key});

  void _open(BuildContext context, TransportType transport) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransportValveListScreen(transport: transport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORBI DRIVE'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _transportButton(
              context,
              TransportType.gsmLte,
              Icons.cell_tower,
            ),
            const SizedBox(height: 24),
            _transportButton(
              context,
              TransportType.lora,
              Icons.settings_input_antenna,
            ),
          ],
        ),
      ),
    );
  }

  Widget _transportButton(
    BuildContext context,
    TransportType transport,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: ElevatedButton.icon(
        onPressed: () => _open(context, transport),
        icon: Icon(icon, size: 32),
        label: Text(
          transport.label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
