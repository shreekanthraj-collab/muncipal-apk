import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LocalScadaRegistrationTestScreen extends StatefulWidget {
  const LocalScadaRegistrationTestScreen({super.key});
  @override
  State<LocalScadaRegistrationTestScreen> createState() => _LocalScadaRegistrationTestScreenState();
}

class _LocalScadaRegistrationTestScreenState extends State<LocalScadaRegistrationTestScreen> {
  final _pcIp = TextEditingController(text: '192.168.1.100');
  final _valveId = TextEditingController(text: 'V-TEST-001');
  final _zone = TextEditingController(text: 'Zone 1');
  final _ward = TextEditingController(text: 'Ward 1');
  final _oht = TextEditingController(text: 'OHT-1');
  final _flow = TextEditingController(text: 'FM-001');
  final _overflow = TextEditingController(text: 'OF-001');
  final _level = TextEditingController(text: 'LI-001');
  String _type = 'MAIN';
  String _transport = 'GSM';
  String _result = '';

  @override
  void dispose() {
    for (final c in [_pcIp, _valveId, _zone, _ward, _oht, _flow, _overflow, _level]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _send() async {
    final ip = _pcIp.text.trim();
    final valveId = _valveId.text.trim();
    if (ip.isEmpty || valveId.isEmpty) return;
    final payload = <String, dynamic>{
      'valve_id': valveId,
      'valve_type': _type,
      'transport': _transport.toLowerCase(),
      'zone': _zone.text.trim(),
      'ward': _ward.text.trim(),
      'device_id': valveId,
      'oht_id': _oht.text.trim(),
      'flow_meter_id': _flow.text.trim(),
      'overflow_sensor_id': _overflow.text.trim(),
      'level_indicator_id': _level.text.trim(),
    };
    setState(() => _result = 'Sending...');
    try {
      final response = await http.post(
        Uri.parse('http://$ip:8765/register'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      setState(() {
        _result = response.statusCode == 200
            ? 'REGISTERED: $valveId → SCADA'
            : 'FAILED (' + response.statusCode.toString() + '): ' + response.body;
      });
    } catch (e) { setState(() => _result = 'FAILED: $e'); }
  }

  Widget _field(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: controller, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('LOCAL SCADA REGISTRATION TEST')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('ONE-TIME TEST — AWS NOT USED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 12),
        _field('SCADA PC IPv4 address', _pcIp),
        _field('Valve ID', _valveId),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Valve type', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value: 'MAIN', child: Text('MAIN')), DropdownMenuItem(value: 'DISTRIBUTION', child: Text('DISTRIBUTION'))],
          onChanged: (v) => setState(() => _type = v ?? 'MAIN'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _transport,
          decoration: const InputDecoration(labelText: 'Transport', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value: 'GSM', child: Text('GSM')), DropdownMenuItem(value: 'LORA', child: Text('LoRa'))],
          onChanged: (v) => setState(() => _transport = v ?? 'GSM'),
        ),
        const SizedBox(height: 10),
        _field('Zone', _zone), _field('Ward', _ward), _field('OHT ID', _oht),
        _field('Flow Meter ID', _flow), _field('Overflow Sensor ID', _overflow), _field('Level Indicator ID', _level),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _send, icon: const Icon(Icons.cloud_upload), label: const Padding(padding: EdgeInsets.all(12), child: Text('REGISTER ON SCADA'))),
        const SizedBox(height: 12),
        Text(_result, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}