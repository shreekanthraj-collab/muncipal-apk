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
    required this.latitude,
    required this.longitude,
    required this.isGsm,
  });

  final String id;
  final double latitude;
  final double longitude;
  final bool isGsm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'isGsm': isGsm,
      };

  factory _ValveMapItem.fromJson(Map<String, dynamic> json) {
    return _ValveMapItem(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isGsm: json['isGsm'] as bool? ??
          json['id'].toString().toUpperCase().startsWith('GSM'),
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  static const _storageKey = 'municipal_map_valves_v2';

  final MapController _mapController = MapController();
  final TextEditingController _mapNameController =
      TextEditingController(text: 'Municipal Valve Map');

  List<_ValveMapItem> _valves = const [];
  LatLng? _phoneLocation;
  String? _selectedId;
  bool _loading = true;
  bool _locating = false;
  String _locationStatus = 'Phone GPS not active';

  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _loadValves();
    _locatePhone(initial: true);
  }

  @override
  void dispose() {
    _mapNameController.dispose();
    super.dispose();
  }

  Future<void> _loadValves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .map((item) =>
                _ValveMapItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (mounted) {
          setState(() {
            _valves = loaded;
            _selectedId = loaded.isEmpty ? null : loaded.first.id;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {
      // Start with an empty list if old/corrupt map data cannot be decoded.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveValves() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_valves.map((valve) => valve.toJson()).toList()),
    );
  }

  Future<void> _locatePhone({bool initial = false}) async {
    if (_locating) return;
    if (mounted) {
      setState(() {
        _locating = true;
        if (!initial) _locationStatus = 'Locating phone...';
      });
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          setState(() => _locationStatus = 'Location service is OFF');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationStatus = 'Location permission denied');
        }
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationStatus = 'Location permission blocked');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _phoneLocation = location;
        _locationStatus = 'Phone location active';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(location, 16);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _locationStatus = 'Unable to get phone location');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _addValve() async {
    final idController = TextEditingController();
    final latController = TextEditingController(
      text: _phoneLocation?.latitude.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: _phoneLocation?.longitude.toStringAsFixed(6) ?? '',
    );

    final result = await showDialog<_ValveMapItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADD VALVE'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Valve ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (id.isEmpty ||
                  lat == null ||
                  lng == null ||
                  lat < -90 ||
                  lat > 90 ||
                  lng < -180 ||
                  lng > 180) {
                return;
              }
              Navigator.pop(
                context,
                _ValveMapItem(
                  id: id,
                  latitude: lat,
                  longitude: lng,
                  isGsm: id.toUpperCase().startsWith('GSM'),
                ),
              );
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    idController.dispose();
    latController.dispose();
    lngController.dispose();
    if (!mounted || result == null) return;

    if (_valves.any(
        (valve) => valve.id.toUpperCase() == result.id.toUpperCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valve ID already exists')),
      );
      return;
    }

    setState(() {
      _valves = [..._valves, result];
      _selectedId = result.id;
    });
    await _saveValves();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.id} saved to map')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(LatLng(result.latitude, result.longitude), 16);
        }
      });
    }
  }

  Future<void> _removeValve(_ValveMapItem valve) async {
    setState(() {
      _valves = _valves.where((item) => item.id != valve.id).toList();
      _selectedId = _valves.isEmpty ? null : _valves.first.id;
    });
    await _saveValves();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${valve.id} removed')),
      );
    }
  }

  void _rebindValve(_ValveMapItem valve) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rebind requested for ${valve.id}')),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = _valves.map((valve) {
      return Marker(
        point: LatLng(valve.latitude, valve.longitude),
        width: 110,
        height: 80,
        child: GestureDetector(
          onTap: () => setState(() => _selectedId = valve.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 40,
                color: valve.isGsm ? Colors.red : Colors.blue,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [BoxShadow(blurRadius: 4)],
                ),
                child: Text(
                  valve.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (_phoneLocation != null) {
      markers.add(
        Marker(
          point: _phoneLocation!,
          width: 70,
          height: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Text(
                'You',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildValveRow(_ValveMapItem valve) {
    final isSelected = valve.id == _selectedId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedId = valve.id);
            _mapController.move(LatLng(valve.latitude, valve.longitude), 16);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: valve.isGsm
                        ? Colors.red.withValues(alpha: 0.10)
                        : Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_damage_outlined,
                    color: valve.isGsm ? Colors.red : Colors.blue,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valve.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Lat: ${valve.latitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Lng: ${valve.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _removeValve(valve),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('REMOVE'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FilledButton.icon(
                      onPressed: () => _rebindValve(valve),
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('REBIND'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedId == null
        ? null
        : _valves.where((valve) => valve.id == _selectedId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('MAP'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'VALVE ID (GSM + LoRa)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 7),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: _valves
                              .map(
                                (valve) => DropdownMenuItem(
                                  value: valve.id,
                                  child: Text(valve.id),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedId = value),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _addValve,
                          icon: const Icon(Icons.add),
                          label: const Text('ADD VALVE'),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 360,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _phoneLocation ??
                                (selected == null
                                    ? _defaultCenter
                                    : LatLng(
                                        selected.latitude,
                                        selected.longitude,
                                      )),
                            initialZoom:
                                _phoneLocation == null && selected == null
                                    ? 5
                                    : 16,
                            minZoom: 3,
                            maxZoom: 19,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.orb.valve.app',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                    'OpenStreetMap contributors'),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          right: 10,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                _phoneLocation == null
                                    ? _locationStatus
                                    : 'My Location (GPS)\nLat: ${_phoneLocation!.latitude.toStringAsFixed(6)}  Lng: ${_phoneLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _MapButton(
                                icon: Icons.my_location,
                                onPressed:
                                    _locating ? null : () => _locatePhone(),
                              ),
                              const SizedBox(height: 4),
                              _MapButton(
                                icon: Icons.add,
                                onPressed: () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom + 1)
                                      .clamp(3, 19),
                                ),
                              ),
                              _MapButton(
                                icon: Icons.remove,
                                onPressed: () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom - 1)
                                      .clamp(3, 19),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'VALVE LIST',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '(${_valves.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_valves.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No valves saved on this phone.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          SizedBox(
                            height: 430,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _valves.length,
                              itemBuilder: (context, index) =>
                                  _buildValveRow(_valves[index]),
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
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
