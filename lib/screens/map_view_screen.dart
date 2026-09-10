import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'valve_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  static const _storageKey = 'map_valves_v1';

  final List<_MapValve> _valves = [
    const _MapValve('ORBI-001', 'Valve 001', 12.9716, 77.5946, 'GSM/LTE', 'ONLINE'),
    const _MapValve('ORBI-002', 'Valve 002', 12.9816, 77.6046, 'LoRa', 'ONLINE'),
    const _MapValve('ORBI-003', 'Valve 003', 12.9616, 77.5846, 'LoRa', 'FAULT'),
  ];

  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadSavedValves();
  }

  Future<void> _loadSavedValves() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? const [];
    for (final item in saved) {
      final parts = item.split('|');
      if (parts.length != 6) continue;
      final lat = double.tryParse(parts[2]);
      final lon = double.tryParse(parts[3]);
      if (lat == null || lon == null) continue;
      _valves.add(_MapValve(parts[0], parts[1], lat, lon, parts[4], parts[5]));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveCustomValves() async {
    final prefs = await SharedPreferences.getInstance();
    const builtInIds = {'ORBI-001', 'ORBI-002', 'ORBI-003'};
    final saved = _valves
        .where((v) => !builtInIds.contains(v.id))
        .map((v) => '${v.id}|${v.name}|${v.latitude}|${v.longitude}|${v.transport}|${v.status}')
        .toList();
    await prefs.setStringList(_storageKey, saved);
  }

  Future<Position?> _getGpsPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await _message('Please turn ON Location/GPS on the phone.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await _message('Location permission is required to place a valve using GPS.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _addValveFromGps() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final position = await _getGpsPosition();
      if (position == null || !mounted) return;

      final nextNumber = _valves.length + 1;
      final nameController = TextEditingController(text: 'Valve $nextNumber');
      var transport = 'GSM/LTE';

      final result = await showDialog<_MapValve>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ADD VALVE AT GPS LOCATION'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Valve name')),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  value: transport,
                  decoration: const InputDecoration(labelText: 'Connection'),
                  items: const [
                    DropdownMenuItem(value: 'GSM/LTE', child: Text('GSM/LTE')),
                    DropdownMenuItem(value: 'LoRa', child: Text('LoRa')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => transport = value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final id = 'ORBI-${(_valves.length + 1).toString().padLeft(3, '0')}';
                Navigator.pop(dialogContext, _MapValve(id, name, position.latitude, position.longitude, transport, 'ONLINE'));
              },
              child: const Text('ADD TO MAP'),
            ),
          ],
        ),
      );

      if (result != null && mounted) {
        setState(() => _valves.add(result));
        await _saveCustomValves();
        await _message('${result.name} added to the map at the phone GPS location.');
      }
    } finally {
      nameControllerCleanup:
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _message(String text) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(text),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'FAULT': return Colors.red;
      case 'OFFLINE': return Colors.grey;
      default: return Colors.green;
    }
  }

  void _openValve(BuildContext context, _MapValve valve) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ValveDetailScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VALVE MAP', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Add valve using phone GPS',
            onPressed: _adding ? null : _addValveFromGps,
            icon: _adding
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_location_alt),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adding ? null : _addValveFromGps,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('ADD VALVE'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final minLat = _valves.map((v) => v.latitude).reduce((a, b) => a < b ? a : b);
                        final maxLat = _valves.map((v) => v.latitude).reduce((a, b) => a > b ? a : b);
                        final minLon = _valves.map((v) => v.longitude).reduce((a, b) => a < b ? a : b);
                        final maxLon = _valves.map((v) => v.longitude).reduce((a, b) => a > b ? a : b);
                        final latSpan = (maxLat - minLat).abs() < 0.001 ? 0.01 : (maxLat - minLat);
                        final lonSpan = (maxLon - minLon).abs() < 0.001 ? 0.01 : (maxLon - minLon);

                        return Stack(
                          children: [
                            const Center(child: Icon(Icons.map, size: 110, color: Colors.grey)),
                            ..._valves.map((valve) {
                              final x = ((valve.longitude - minLon) / lonSpan).clamp(0.08, 0.92);
                              final y = (1 - ((valve.latitude - minLat) / latSpan)).clamp(0.10, 0.90);
                              return Positioned(
                                left: constraints.maxWidth * x - 20,
                                top: constraints.maxHeight * y - 20,
                                child: GestureDetector(
                                  onTap: () => _openValve(context, valve),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on, size: 34, color: _statusColor(valve.status)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade400)),
                                        child: Text(valve.transport, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('${_valves.length} valves'))),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 190),
                    child: ListView.builder(
                      itemCount: _valves.length,
                      itemBuilder: (context, index) {
                        final valve = _valves[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on, color: _statusColor(valve.status)),
                          title: Text(valve.name),
                          subtitle: Text('${valve.id} • ${valve.transport} • ${valve.latitude.toStringAsFixed(5)}, ${valve.longitude.toStringAsFixed(5)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openValve(context, valve),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapValve {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String transport;
  final String status;

  const _MapValve(this.id, this.name, this.latitude, this.longitude, this.transport, this.status);
}
