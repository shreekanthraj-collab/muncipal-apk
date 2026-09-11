import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'valve_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(12.9716, 77.5946);
  LatLng? _mobileLocation;
  bool _loadingLocation = true;
  String? _locationError;

  static const _valves = <_MapValve>[
    _MapValve(id: 'ORBI-001', name: 'Valve 001', latitude: 12.9716, longitude: 77.5946, transport: 'GSM/LTE', status: 'ONLINE'),
    _MapValve(id: 'ORBI-002', name: 'Valve 002', latitude: 12.9816, longitude: 77.6046, transport: 'LoRa', status: 'ONLINE'),
    _MapValve(id: 'ORBI-003', name: 'Valve 003', latitude: 12.9616, longitude: 77.5846, transport: 'LoRa', status: 'FAULT'),
  ];

  @override
  void initState() {
    super.initState();
    _getMobileLocation();
  }

  Future<void> _getMobileLocation() async {
    setState(() { _loadingLocation = true; _locationError = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('GPS/location service is turned off');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Location permission denied');
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() { _mobileLocation = location; _center = location; _loadingLocation = false; });
      _mapController.move(location, 16);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingLocation = false; _locationError = e.toString(); });
    }
  }

  Color _statusColor(String status) => status == 'FAULT' ? Colors.red : status == 'OFFLINE' ? Colors.grey : Colors.green;

  void _openValve(BuildContext context, _MapValve valve) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ValveDetailScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VALVE MAP', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.my_location), tooltip: 'Show my location', onPressed: _getMobileLocation)],
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _center, initialZoom: 16, minZoom: 3, maxZoom: 19),
          children: [
            TileLayer(
              urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.orb_valve_app',
              maxZoom: 19,
            ),
            MarkerLayer(markers: [
              ..._valves.map((valve) => Marker(
                point: LatLng(valve.latitude, valve.longitude), width: 52, height: 60,
                child: GestureDetector(onTap: () => _openValve(context, valve), child: Icon(Icons.location_on, size: 42, color: _statusColor(valve.status))),
              )),
              if (_mobileLocation != null) Marker(point: _mobileLocation!, width: 54, height: 54, child: const _MobileLocationMarker()),
            ]),
          ],
        ),
        Positioned(left: 12, top: 12, child: Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text('${_valves.length} valves')))),
        if (_loadingLocation) const Positioned(top: 12, left: 0, right: 0, child: Center(child: Card(child: Padding(padding: EdgeInsets.all(8), child: Text('Getting mobile GPS...'))))),
        if (_locationError != null && _mobileLocation == null) Positioned(left: 12, right: 12, bottom: 12, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.location_off), const SizedBox(width: 8), Expanded(child: Text(_locationError!)), IconButton(icon: const Icon(Icons.refresh), onPressed: _getMobileLocation)])))),
      ]),
    );
  }
}

class _MobileLocationMarker extends StatelessWidget {
  const _MobileLocationMarker();
  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
    Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(.18))),
    Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue, border: Border.all(color: Colors.white, width: 3))),
  ]);
}

class _MapValve {
  final String id; final String name; final double latitude; final double longitude; final String transport; final String status;
  const _MapValve({required this.id, required this.name, required this.latitude, required this.longitude, required this.transport, required this.status});
}
