import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'valve_detail_screen.dart';

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  static const _valves = <_MapValve>[
    _MapValve(
      id: 'ORBI-001',
      name: 'Valve 001',
      latitude: 12.9716,
      longitude: 77.5946,
      transport: 'GSM/LTE',
      status: 'ONLINE',
    ),
    _MapValve(
      id: 'ORBI-002',
      name: 'Valve 002',
      latitude: 12.9816,
      longitude: 77.6046,
      transport: 'LoRa',
      status: 'ONLINE',
    ),
    _MapValve(
      id: 'ORBI-003',
      name: 'Valve 003',
      latitude: 12.9616,
      longitude: 77.5846,
      transport: 'LoRa',
      status: 'FAULT',
    ),
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'FAULT':
        return Colors.red;
      case 'OFFLINE':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  void _openValve(BuildContext context, _MapValve valve) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ValveDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mapCenter = LatLng(12.9716, 77.5946);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VALVE MAP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 13,
                      minZoom: 3,
                      maxZoom: 19,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.orb.valve_app',
                      ),
                      MarkerLayer(
                        markers: _valves.map((valve) {
                          return Marker(
                            point: LatLng(valve.latitude, valve.longitude),
                            width: 52,
                            height: 60,
                            child: GestureDetector(
                              onTap: () => _openValve(context, valve),
                              child: Tooltip(
                                message: '${valve.name} • ${valve.transport}',
                                child: Icon(
                                  Icons.location_on,
                                  size: 42,
                                  color: _statusColor(valve.status),
                                ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text('${_valves.length} valves'),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _legend('GSM/LTE', Icons.cell_tower),
                            const SizedBox(height: 4),
                            _legend('LoRa', Icons.settings_input_antenna),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: _valves.map((valve) {
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: _statusColor(valve.status),
                  ),
                  title: Text(valve.name),
                  subtitle: Text(
                    '${valve.id} • ${valve.transport} • ${valve.status}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openValve(context, valve),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
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

  const _MapValve({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.transport,
    required this.status,
  });
}
