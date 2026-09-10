import 'package:flutter/material.dart';

import 'valve_detail_screen.dart';

class MapViewScreen extends StatelessWidget {
  const MapViewScreen({super.key});

  // Global valve map: GSM/LTE and LoRa valves are shown together.
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
      MaterialPageRoute(
        builder: (_) => ValveDetailScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 110, color: Colors.grey),
                  ),
                  ..._valves.map((valve) => _marker(context, valve)),
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
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('GSM/LTE'),
                            SizedBox(height: 4),
                            Text('LoRa'),
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

  Widget _marker(BuildContext context, _MapValve valve) {
    final positions = <String, Offset>{
      'ORBI-001': const Offset(0.22, 0.28),
      'ORBI-002': const Offset(0.68, 0.22),
      'ORBI-003': const Offset(0.46, 0.65),
    };
    final position = positions[valve.id] ?? const Offset(0.5, 0.5);

    return Positioned(
      left: MediaQuery.sizeOf(context).width * position.dx - 42,
      top: 220 * position.dy,
      child: GestureDetector(
        onTap: () => _openValve(context, valve),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 34,
              color: _statusColor(valve.status),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                valve.transport,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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

  const _MapValve({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.transport,
    required this.status,
  });
}
