import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _ValveMapItem {
  const _ValveMapItem({
    required this.id,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.isGsm,
  });

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

  factory _ValveMapItem.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final lat = json['latitude'];
    final lng = json['longitude'];
    if (id.isEmpty || lat is! num || lng is! num) {
      throw const FormatException('Invalid valve record');
    }
    return _ValveMapItem(
      id: id,
      zone: json['zone']?.toString().trim().isNotEmpty == true
          ? json['zone'].toString()
          : 'North Field',
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      isGsm: json['is_gsm'] == true || id.toUpperCase().startsWith('GSM'),
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  static const _valvesKey = 'map_valves_v2';
  static const _legacyValvesKey = 'map_valves_v1';
  static const _registeredValvesKey = 'registered_valves_v1';
  static const _zonesKey = 'map_zones_v1';
  static const _selectedZoneKey = 'map_selected_zone_v1';
  static const _mapNameKey = 'map_name_v1';

  final TextEditingController _mapNameController =
      TextEditingController(text: 'Farm A - North Field');

  final List<String> _zones = ['North Field'];
  String _selectedZone = 'North Field';
  bool _loading = true;

  final List<_ValveMapItem> _valves = [
    const _ValveMapItem(
      id: 'GSM-001', zone: 'North Field', latitude: 14.598001,
      longitude: 120.982331, isGsm: true,
    ),
    const _ValveMapItem(
      id: 'LORA-001', zone: 'North Field', latitude: 14.601210,
      longitude: 120.987654, isGsm: false,
    ),
    const _ValveMapItem(
      id: 'GSM-002', zone: 'North Field', latitude: 14.595678,
      longitude: 120.990123, isGsm: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<List<_ValveMapItem>> _decodeValves(String? raw) async {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((item) {
        try {
          return _ValveMapItem.fromJson(Map<String, dynamic>.from(item));
        } catch (_) {
          return null;
        }
      }).whereType<_ValveMapItem>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadMapData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_mapNameKey);
      final savedZones = prefs.getStringList(_zonesKey);
      final savedSelectedZone = prefs.getString(_selectedZoneKey);

      var mapRaw = prefs.getString(_valvesKey);
      mapRaw ??= prefs.getString(_legacyValvesKey);
      final mapValves = await _decodeValves(mapRaw);
      final registeredValves = await _decodeValves(
        prefs.getString(_registeredValvesKey),
      );

      final merged = <String, _ValveMapItem>{};
      for (final valve in mapValves) {
        merged[valve.id.toLowerCase()] = valve;
      }
      for (final valve in registeredValves) {
        merged[valve.id.toLowerCase()] = valve;
      }

      final loadedZones = <String>{'North Field'};
      if (savedZones != null) {
        loadedZones.addAll(savedZones.where((z) => z.trim().isNotEmpty));
      }
      for (final valve in merged.values) {
        loadedZones.add(valve.zone);
      }

      if (!mounted) return;
      setState(() {
        if (savedName != null && savedName.trim().isNotEmpty) {
          _mapNameController.text = savedName;
        }
        _zones
          ..clear()
          ..addAll(loadedZones);
        _selectedZone = savedSelectedZone != null &&
                loadedZones.contains(savedSelectedZone)
            ? savedSelectedZone
            : _zones.first;
        if (merged.isNotEmpty || mapRaw != null || registeredValves.isNotEmpty) {
          _valves
            ..clear()
            ..addAll(merged.values);
        }
        _loading = false;
      });

      if (registeredValves.isNotEmpty) {
        await _saveMapData();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveMapData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _valvesKey,
      jsonEncode(_valves.map((valve) => valve.toJson()).toList()),
    );
    await prefs.setStringList(_zonesKey, _zones);
    await prefs.setString(_selectedZoneKey, _selectedZone);
    await prefs.setString(_mapNameKey, _mapNameController.text.trim());
  }

  @override
  void dispose() {
    _mapNameController.dispose();
    super.dispose();
  }

  void _editMapName() {
    final controller = TextEditingController(text: _mapNameController.text);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Map Name', border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () async {
              setState(() => _mapNameController.text = controller.text.trim());
              await _saveMapData();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _addZone() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD ZONE'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Zone Name', hintText: 'e.g. South Field',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ADD')),
        ],
      ),
    );
    if (!mounted || result == null || result.isEmpty) return;
    if (_zones.any((z) => z.toLowerCase() == result.toLowerCase())) return;
    setState(() { _zones.add(result); _selectedZone = result; });
    await _saveMapData();
  }

  Future<void> _addValve() async {
    final idController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final result = await showDialog<_ValveMapItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD VALVE'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: idController, autofocus: true, decoration: const InputDecoration(labelText: 'Valve ID')),
            TextField(controller: latController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Latitude')),
            TextField(controller: lngController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Longitude')),
            const SizedBox(height: 6),
            Text('Zone: $_selectedZone'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (id.isEmpty || lat == null || lng == null) return;
              if (_valves.any((v) => v.id.toLowerCase() == id.toLowerCase())) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Valve $id already exists')));
                return;
              }
              Navigator.pop(context, _ValveMapItem(
                id: id, zone: _selectedZone, latitude: lat, longitude: lng,
                isGsm: id.toUpperCase().startsWith('GSM'),
              ));
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _valves.add(result));
    await _saveMapData();
    if (mounted) _showAdded(result);
  }

  void _showAdded(_ValveMapItem valve) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 58),
        title: const Text('Valve Added Successfully'),
        content: Text(
          'Valve ID: ${valve.id}\n'
          'Zone: ${valve.zone}\n'
          'Latitude: ${valve.latitude.toStringAsFixed(6)}\n'
          'Longitude: ${valve.longitude.toStringAsFixed(6)}',
        ),
        actions: [SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')))],
      ),
    );
  }

  Future<void> _removeValve(_ValveMapItem valve) async {
    setState(() => _valves.removeWhere((item) => item.id == valve.id));
    await _saveMapData();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete, color: Colors.red, size: 58),
        title: const Text('Valve Removed'),
        content: Text('Valve ID: ${valve.id}'),
        actions: [SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')))],
      ),
    );
  }

  void _rebindValve(_ValveMapItem valve) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rebind requested for ${valve.id}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('MAP'), centerTitle: true, leading: const BackButton()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Column(children: [
                  TextField(
                    controller: _mapNameController, readOnly: true,
                    decoration: const InputDecoration(labelText: 'Map Name', border: OutlineInputBorder(), suffixIcon: Icon(Icons.edit)),
                    onTap: _editMapName,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedZone,
                        decoration: const InputDecoration(labelText: 'Zone', border: OutlineInputBorder()),
                        items: _zones.map((zone) => DropdownMenuItem(value: zone, child: Text(zone))).toList(),
                        onChanged: (zone) async {
                          if (zone == null) return;
                          setState(() => _selectedZone = zone);
                          await _saveMapData();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _addZone, icon: const Icon(Icons.add), label: const Text('ADD ZONE')),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _addValve, icon: const Icon(Icons.add), label: const Text('ADD VALVE')),
                  ]),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  children: [
                    _MapSurface(valves: _valves),
                    const SizedBox(height: 10),
                    Card(child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('Valve List (${_valves.length})', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ..._valves.map(_valveTile),
                      ]),
                    )),
                  ],
                ),
              ),
            ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.cell_tower), label: 'GSM'),
          NavigationDestination(icon: Icon(Icons.settings_input_antenna), label: 'LoRa'),
          NavigationDestination(icon: Icon(Icons.map), label: 'MAP'),
          NavigationDestination(icon: Icon(Icons.account_tree), label: 'RS485'),
        ],
      ),
    );
  }

  Widget _valveTile(_ValveMapItem valve) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.plumbing, color: valve.isGsm ? Colors.red : Colors.blue, size: 34),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Valve ID: ${valve.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Zone: ${valve.zone}'),
                Text('Lat: ${valve.latitude.toStringAsFixed(6)}'),
                Text('Lng: ${valve.longitude.toStringAsFixed(6)}'),
              ])),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _removeValve(valve), icon: const Icon(Icons.delete_outline), label: const Text('REMOVE'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: () => _rebindValve(valve), icon: const Icon(Icons.link), label: const Text('REBIND'))),
            ]),
          ]),
        ),
      );
}

class _MapSurface extends StatefulWidget {
  const _MapSurface({required this.valves});
  final List<_ValveMapItem> valves;

  @override
  State<_MapSurface> createState() => _MapSurfaceState();
}

class _MapSurfaceState extends State<_MapSurface> {
  final MapController _mapController = MapController();
  LatLng? _phoneLocation;
  bool _locating = false;
  String _locationStatus = 'Press location button to locate phone';

  static const LatLng _defaultCenter = LatLng(14.599232, 120.984321);

  Future<void> _locatePhone() async {
    if (_locating) return;
    setState(() { _locating = true; _locationStatus = 'Locating phone...'; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationStatus = 'Location service is OFF');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationStatus = 'Location permission denied');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationStatus = 'Location permission blocked');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() { _phoneLocation = location; _locationStatus = 'Phone location active'; });
      _mapController.move(location, 16);
    } catch (_) {
      if (mounted) setState(() => _locationStatus = 'Unable to get phone location');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.valves.isNotEmpty
        ? LatLng(widget.valves.first.latitude, widget.valves.first.longitude)
        : _defaultCenter;

    final markers = <Marker>[
      ...widget.valves.map((valve) => Marker(
        point: LatLng(valve.latitude, valve.longitude), width: 110, height: 70,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${valve.id}\n${valve.latitude.toStringAsFixed(6)}, ${valve.longitude.toStringAsFixed(6)}'))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_on, color: valve.isGsm ? Colors.red : Colors.blue, size: 38),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: const [BoxShadow(blurRadius: 4)]),
              child: Text(valve.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ]),
        ),
      )),
      if (_phoneLocation != null) Marker(
        point: _phoneLocation!, width: 80, height: 65,
        child: Column(children: [
          Container(
            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            padding: const EdgeInsets.all(7),
            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
          ),
          const Text('You', style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
        ]),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1.16,
        child: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.orb_valve_app',
                tileProvider: NetworkTileProvider(
                  headers: const {
                    'User-Agent': 'ORB-Valve-App/1.0',
                  },
                ),
                panBuffer: 0,
                keepBuffer: 1,
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
            ],
          ),
          Positioned(
            left: 10, top: 10, right: 10,
            child: Card(child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(children: [
                Icon(_phoneLocation == null ? Icons.location_searching : Icons.my_location, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _phoneLocation == null ? _locationStatus : 'My Location (GPS)\nLat: ${_phoneLocation!.latitude.toStringAsFixed(6)}\nLng: ${_phoneLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                )),
              ]),
            )),
          ),
          Positioned(
            right: 10, bottom: 10,
            child: Column(children: [
              _MapButton(icon: Icons.my_location, onPressed: _locating ? null : _locatePhone),
              const SizedBox(height: 4),
              _MapButton(icon: Icons.add, onPressed: () => _mapController.move(_mapController.camera.center, (_mapController.camera.zoom + 1).clamp(3, 19))),
              _MapButton(icon: Icons.remove, onPressed: () => _mapController.move(_mapController.camera.center, (_mapController.camera.zoom - 1).clamp(3, 19))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 48, height: 44, child: Icon(icon)),
        ),
      );
}
