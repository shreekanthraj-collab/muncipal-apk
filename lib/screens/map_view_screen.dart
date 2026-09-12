import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'valve_control_screen.dart';

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
  bool _placingValve = false;
  LatLng? _placementPoint;
  final MapController _mapController = MapController();

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

      setState(() {
        _placementPoint = LatLng(position.latitude, position.longitude);
        _placingValve = true;
      });

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16.0,
      );

      await _message(
        'Blue marker placed at the phone GPS location. '
        'Move it to the exact valve location, then tap CONFIRM LOCATION.',
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _cancelValvePlacement() {
    setState(() {
      _placingValve = false;
      _placementPoint = null;
    });
  }

  Future<void> _confirmValvePlacement() async {
    final point = _placementPoint;
    if (point == null || !mounted) return;

    var valveName = 'Valve ${_valves.length + 1}';
    var transport = 'GSM/LTE';

    final result = await showDialog<_MapValve>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CONFIRM VALVE LOCATION'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: ${point.latitude.toStringAsFixed(6)}, '
              '${point.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: valveName,
              decoration: const InputDecoration(labelText: 'Valve name'),
              onChanged: (value) => valveName = value,
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setDialogState) => DropdownButtonFormField<String>(
                initialValue: transport,
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final name = valveName.trim();
              if (name.isEmpty) return;
              final id = 'ORBI-${(_valves.length + 1).toString().padLeft(3, '0')}';
              Navigator.pop(
                dialogContext,
                _MapValve(
                  id,
                  name,
                  point.latitude,
                  point.longitude,
                  transport,
                  'ONLINE',
                ),
              );
            },
            child: const Text('SAVE VALVE'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _valves.add(result);
        _placingValve = false;
        _placementPoint = null;
      });
      await _saveCustomValves();
      await _message(
        '${result.name} saved at ${result.latitude.toStringAsFixed(6)}, '
        '${result.longitude.toStringAsFixed(6)}',
      );
    }
  }

  Future<void> _removeValve(_MapValve valve) async {
    const builtInIds = {'ORBI-001', 'ORBI-002', 'ORBI-003'};
    if (builtInIds.contains(valve.id)) {
      await _message('Built-in valves cannot be removed.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('REMOVE VALVE'),
        content: Text('Are you sure you want to remove ${valve.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _valves.removeWhere((v) => v.id == valve.id));
    await _saveCustomValves();
    if (mounted) await _message('${valve.name} removed from the map.');
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ValveControlScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VALVE MAP', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _adding ? null : _addValveFromGps,
              icon: _adding
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_location_alt),
              label: const Text('ADD VALVE'),
            ),
          ),
        ],
      ),
      floatingActionButton: _placingValve
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'cancelPlacement',
                  onPressed: _cancelValvePlacement,
                  icon: const Icon(Icons.close),
                  label: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.extended(
                  heroTag: 'confirmPlacement',
                  onPressed: _confirmValvePlacement,
                  icon: const Icon(Icons.check),
                  label: const Text('CONFIRM LOCATION'),
                ),
              ],
            )
          : null,
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
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _valves.map((v) => v.latitude).reduce((a, b) => a + b) / _valves.length,
                              _valves.map((v) => v.longitude).reduce((a, b) => a + b) / _valves.length,
                            ),
                            initialZoom: 12.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.orbi.valve_app',
                            ),
                            if (_placementPoint != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _placementPoint!,
                                    width: 60,
                                    height: 60,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanUpdate: (details) {
                                        final current = _placementPoint;
                                        if (current == null) return;
                                        final map = _mapController.camera;
                                        final screenPoint = map.latLngToScreenOffset(current);
                                        final newScreenPoint = screenPoint + details.delta;
                                        final newLatLng = map.screenOffsetToLatLng(newScreenPoint);
                                        setState(() => _placementPoint = newLatLng);
                                      },
                                      child: const Icon(Icons.location_on, size: 48, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: _valves.map((valve) {
                                return Marker(
                                  point: LatLng(valve.latitude, valve.longitude),
                                  width: 90,
                                  height: 65,
                                  child: GestureDetector(
                                    onTap: () => _openValve(context, valve),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on, size: 36, color: _statusColor(valve.status)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.grey),
                                          ),
                                          child: Text(valve.transport, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text('${_valves.length} valves'),
                            ),
                          ),
                        ),
                      ],
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove valve',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeValve(valve),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
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
