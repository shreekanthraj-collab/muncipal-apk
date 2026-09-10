import 'package:flutter/material.dart';

import 'screens/map_view_screen.dart';
import 'screens/rs485_flow_screen.dart';
import 'screens/transport_home_screen.dart';

void main() {
  runApp(const OrbiValveApp());
}

class OrbiValveApp extends StatelessWidget {
  const OrbiValveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ORBI DRIVE',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const OrbiHomeScreen(),
    );
  }
}

class OrbiHomeScreen extends StatelessWidget {
  const OrbiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORBI DRIVE', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _button(context, 'GSM / LTE', Icons.cell_tower, const TransportHomeScreen()),
          const SizedBox(height: 12),
          _button(context, 'MAP VIEW — ALL VALVES', Icons.map, const MapViewScreen()),
          const SizedBox(height: 12),
          _button(context, 'RS485 / FLOW — ALL VALVES', Icons.water_drop, const Rs485FlowScreen()),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, String label, IconData icon, Widget destination) {
    return SizedBox(
      height: 68,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
