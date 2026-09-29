import 'package:flutter/material.dart';

import 'gsm_screen.dart';
import 'lora_screen.dart';
import 'map_screen.dart';
import '../rs485_modbus_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ZONE / WARD'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Zone No', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Ward No', border: OutlineInputBorder()))),
              ]),
              const SizedBox(height: 28),
              _viewButton(context, 'GSM / LTE VALVE VIEW', Icons.cell_tower, const GsmScreen()),
              const SizedBox(height: 14),
              _viewButton(context, 'LoRa VALVE VIEW', Icons.settings_input_antenna, const LoraScreen()),
              const SizedBox(height: 14),
              _viewButton(context, 'MAP VIEW', Icons.map, const MapScreen()),
              const SizedBox(height: 14),
              _viewButton(context, 'RS485 VIEW', Icons.account_tree, const Rs485ModbusPage()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewButton(BuildContext context, String label, IconData icon, Widget page) {
    return SizedBox(
      height: 62,
      child: FilledButton.icon(
        onPressed: () => open(context, page),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
