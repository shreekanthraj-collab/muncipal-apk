import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../admin_app.dart';
import '../screens/add_valve_qr_screen.dart';
import '../services/orb_drive_server_config.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final mapped = <String>{'GSM-001', 'GSM-002', 'LoRa-001'};

  @override
  Widget build(BuildContext c) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const Header('MAP'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Map Name',
                            hintText: 'Farm A - North Field',
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      FilledButton.icon(
                        onPressed: () => _add(c),
                        icon: const Icon(Icons.add),
                        label: const Text('ADD VALVE'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(height: 350, child: _map()),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valve List (${mapped.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: blue,
                            ),
                          ),
                          SizedBox(
                            height: 300,
                            child: ListView(
                              children: store.valves
                                  .where((v) => mapped.contains(v.id))
                                  .map(
                                    (v) => ListTile(
                                      leading: const Icon(
                                        Icons.plumbing,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Valve ID: ${v.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Lat: ${(v.lat ?? 14.598001).toStringAsFixed(6)}\n'
                                        'Lng: ${(v.lng ?? 120.982331).toStringAsFixed(6)}',
                                      ),
                                      trailing: Wrap(
                                        children: [
                                          IconButton(
                                            onPressed: () => setState(
                                              () => mapped.remove(v.id),
                                            ),
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                ScaffoldMessenger.of(c)
                                                    .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Rebind requested for ${v.id}',
                                                ),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.link,
                                              color: blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _map() {
    return Card(
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          const Positioned(
            left: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(7),
                child: Text(
                  'My Location (GPS)\nLat: 14.599221\nLng: 120.984321',
                ),
              ),
            ),
          ),
          for (int i = 0; i < store.valves.length && i < 5; i++)
            Positioned(
              left: 35.0 + (i * 65) % 240,
              top: 110.0 + (i * 58) % 190,
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                  Container(
                    color: Colors.white,
                    child: Text(
                      store.valves[i].id,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const Positioned(
            right: 8,
            bottom: 8,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: null,
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 4),
                FloatingActionButton.small(
                  onPressed: null,
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext c) async {
    if (store.bearerToken == null || store.bearerToken!.isEmpty) {
      ScaffoldMessenger.of(c).showSnackBar(
        const SnackBar(content: Text('Sign in as a registered municipal operator first')),
      );
      return;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to place a valve on the map');
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Turn on phone location/GPS and try again');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!c.mounted) return;

      final result = await Navigator.of(c).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => AddValveQrScreen(
            latitude: position.latitude,
            longitude: position.longitude,
            accessToken: store.bearerToken!,
            serverBaseUrl: OrbDriveServerConfig.baseUrl,
          ),
        ),
      );
      if (!c.mounted || result == null) return;

      final id = (result['id'] ?? '').toString().trim();
      if (id.isEmpty) throw Exception('Server registered the valve but did not return its valve ID');

      final transport = (result['transportType'] ?? (result['isGsm'] == true ? 'GSM' : 'LORA'))
          .toString()
          .toUpperCase();
      if (store.get(id) == null) store.addValve(id, transport == 'GSM' ? 'GSM' : 'LoRa');
      final valve = store.get(id)!;
      valve.lat = (result['latitude'] as num?)?.toDouble() ?? position.latitude;
      valve.lng = (result['longitude'] as num?)?.toDouble() ?? position.longitude;
      setState(() => mapped.add(id));

      ScaffoldMessenger.of(c).showSnackBar(
        SnackBar(content: Text('$id registered and added to map ($transport)')),
      );
    } catch (e) {
      if (!c.mounted) return;
      ScaffoldMessenger.of(c).showSnackBar(
        SnackBar(content: Text('Unable to add valve: $e')),
      );
    }
  }

}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()..color = const Color(0xFFDDEFD8),
    );
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 14;

    for (double y = 35; y < s.height; y += 75) {
      c.drawLine(Offset(0, y), Offset(s.width, y + 30), p);
    }
    for (double x = 30; x < s.width; x += 100) {
      c.drawLine(Offset(x, 0), Offset(x + 60, s.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
