import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Rs485Screen extends StatefulWidget {
  const Rs485Screen({super.key});

  @override
  State<Rs485Screen> createState() => _Rs485ScreenState();
}

class _Rs485Valve {
  const _Rs485Valve({required this.id, required this.zone, required this.latitude, required this.longitude, required this.isGsm});

  final String id;
  final String zone;
  final double latitude;
  final double longitude;
  final bool isGsm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'zone': zone,
        'latitude': latitude,
        'longitude': longitude,
        'is_gsm': isGsm,
      };

  factory _Rs485Valve.fromJson(Map<String, dynamic> json) => _Rs485Valve(
        id: json['id']?.toString() ?? '',
        zone: json['zone']?.toString() ?? 'North Field',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isGsm: json['is_gsm'] == true,
      );
}

class _Rs485ScreenState extends State<Rs485Screen> {
  static const _valvesKey = 'registered_valves_v1';
  static const _defaultValveIds = ['GSM-001', 'GSM-002', 'LORA-001', 'LORA-002'];

  final List<_Rs485Valve> _valves = [];
  String? selectedValveId;
  bool sensor1Added = true;
  bool sensor2Added = true;
  bool overflowAdded = true;
  bool waterQualityAdded = true;

  static final Uri driverPortal = Uri.parse('https://YOUR_DRIVER_PORTAL_URL');

  @override
  void initState() {
    super.initState();
    _loadValves();
  }

  Future<void> _loadValves() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_valvesKey);
    final loaded = <_Rs485Valve>[];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded.whereType<Map>()) {
            try {
              final valve = _Rs485Valve.fromJson(Map<String, dynamic>.from(item));
              if (valve.id.isNotEmpty) loaded.add(valve);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _valves
        ..clear()
        ..addAll(loaded);
      selectedValveId = loaded.isNotEmpty ? loaded.first.id : null;
    });
  }

  Future<void> _saveValves() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_valvesKey, jsonEncode(_valves.map((v) => v.toJson()).toList()));
  }

  List<String> get _valveIds {
    final ids = <String>{..._defaultValveIds, ..._valves.map((v) => v.id)};
    return ids.toList();
  }

  Future<void> _addValve() async {
    final idController = TextEditingController();
    final zoneController = TextEditingController(text: 'North Field');
    final latController = TextEditingController();
    final lngController = TextEditingController();

    final result = await showDialog<_Rs485Valve>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD RS485 VALVE'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: idController, autofocus: true, decoration: const InputDecoration(labelText: 'Valve ID', hintText: 'e.g. GSM-003')),
            TextField(controller: zoneController, decoration: const InputDecoration(labelText: 'Zone')),
            TextField(controller: latController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Latitude')),
            TextField(controller: lngController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Longitude')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              final zone = zoneController.text.trim().isEmpty ? 'North Field' : zoneController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (id.isEmpty || lat == null || lng == null) return;
              if (_valves.any((v) => v.id.toLowerCase() == id.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Valve $id already exists')));
                return;
              }
              Navigator.pop(context, _Rs485Valve(
                id: id,
                zone: zone,
                latitude: lat,
                longitude: lng,
                isGsm: id.toUpperCase().startsWith('GSM'),
              ));
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _valves.add(result);
      selectedValveId = result.id;
    });
    await _saveValves();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.id} added to RS485 valve registry')));
  }

  Future<void> openDriverPortal() async {
    if (driverPortal.host == 'YOUR_DRIVER_PORTAL_URL') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver portal URL is not configured yet.')));
      return;
    }
    await launchUrl(driverPortal, mode: LaunchMode.externalApplication);
  }

  void addSensor() => setState(() => sensor1Added = true);
  void removeSensor() => setState(() => sensor2Added = false);

  @override
  Widget build(BuildContext context) {
    final ids = _valveIds;
    final currentId = selectedValveId != null && ids.contains(selectedValveId) ? selectedValveId : ids.first;

    return Scaffold(
      appBar: AppBar(title: const Text('RS485 / MODBUS'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('VALVE ID (GSM + LoRa)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: currentId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ids.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
              onChanged: (v) { if (v != null) setState(() => selectedValveId = v); },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _addValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
          ]))),
          ..._valves.map((valve) => Card(child: ListTile(
            leading: Icon(Icons.plumbing, color: valve.isGsm ? Colors.red : Colors.blue),
            title: Text(valve.id, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${valve.zone}\n${valve.latitude.toStringAsFixed(6)}, ${valve.longitude.toStringAsFixed(6)}'),
          ))),
          _sensorCard('Flow Sensor 1', sensor1Added ? '12.5 FL/sec' : 'Not configured', Icons.water_drop),
          _sensorCard('Flow Sensor 2', sensor2Added ? '10.8 FL/sec' : 'Not configured', Icons.water_drop),
          _sensorCard('Overflow Tank', overflowAdded ? 'FULL / EMPTY' : 'Not configured', Icons.storage),
          _sensorCard('Water Quality Sensor', waterQualityAdded ? '% / contents' : 'Not configured', Icons.science),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('SENSOR MANAGEMENT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: FilledButton.icon(onPressed: addSensor, icon: const Icon(Icons.add), label: const Text('ADD NEW SENSOR'))), const SizedBox(width: 8), Expanded(child: FilledButton.tonal(onPressed: removeSensor, icon: const Icon(Icons.delete), label: const Text('REMOVE SENSOR')))]),
          ]))),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('DEVICE DRIVERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: openDriverPortal, icon: const Icon(Icons.open_in_new), label: const Text('SEARCH FOR NEW DEVICE DRIVERS')),
            const SizedBox(height: 6),
            const Text('Opens the driver web page in Chrome for manufacturer/model selection and direct-to-device driver download.', textAlign: TextAlign.center),
          ]))),
        ],
      ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon) => Card(child: ListTile(leading: Icon(icon), title: Text(title), trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))));
}
