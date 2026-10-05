import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/valve_fault_storage.dart';
import '../services/server_api_service.dart';
import 'add_valve_qr_screen.dart';

class _ManualValveRegistrationDialog extends StatefulWidget {
  const _ManualValveRegistrationDialog({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<_ManualValveRegistrationDialog> createState() =>
      _ManualValveRegistrationDialogState();
}

class _ManualValveRegistrationDialogState
    extends State<_ManualValveRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valveId = TextEditingController();
  final _wardId = TextEditingController();
  final _zoneId = TextEditingController();
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  String _valveType = 'DISTRIBUTION';

  @override
  void initState() {
    super.initState();
    _latitude = TextEditingController(
      text: widget.latitude.toStringAsFixed(6),
    );
    _longitude = TextEditingController(
      text: widget.longitude.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _valveId.dispose();
    _wardId.dispose();
    _zoneId.dispose();
    _ohtId.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('REGISTER BY VALVE ID'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valveId,
                decoration: const InputDecoration(
                  labelText: 'Valve ID',
                  hintText: 'e.g. ORB-VLV-00000001',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter Valve ID'
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _valveType,
                decoration: const InputDecoration(labelText: 'Valve Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'MAIN',
                    child: Text('MAIN'),
                  ),
                  DropdownMenuItem(
                    value: 'DISTRIBUTION',
                    child: Text('DISTRIBUTION'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _valveType = value);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _wardId,
                decoration: const InputDecoration(labelText: 'Ward ID'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter Ward ID'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _zoneId,
                decoration: const InputDecoration(labelText: 'Zone ID'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter Zone ID'
                    : null,
              ),
              const SizedBox(height: 8),
              if (_valveType == 'MAIN')
                TextFormField(
                  controller: _ohtId,
                  decoration: const InputDecoration(
                    labelText: 'OHT ID',
                    hintText: 'e.g. OHT-01',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter OHT ID for MAIN valve'
                      : null,
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _latitude,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
                validator: (value) {
                  final n = double.tryParse(value?.trim() ?? '');
                  return n == null || n < -90 || n > 90
                      ? 'Enter valid latitude'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _longitude,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
                validator: (value) {
                  final n = double.tryParse(value?.trim() ?? '');
                  return n == null || n < -180 || n > 180
                      ? 'Enter valid longitude'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'valveId': _valveId.text.trim(),
              'wardId': _wardId.text.trim(),
              'zoneId': _zoneId.text.trim(),
              'valveType': _valveType,
              'ohtId': _ohtId.text.trim(),
              'latitude': _latitude.text.trim(),
              'longitude': _longitude.text.trim(),
            });
          },
          child: const Text('REGISTER'),
        ),
      ],
    );
  }
}

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
    required this.zone,
    required this.ward,
    this.valveType = 'DISTRIBUTION',
    this.ohtId,
  });

  final String id;
  final double latitude;
  final double longitude;
  final bool isGsm;
  final String zone;
  final String ward;
  final String valveType;
  final String? ohtId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'isGsm': isGsm,
        'zone': zone,
        'ward': ward,
        'valveType': valveType,
        if (ohtId != null && ohtId!.isNotEmpty) 'ohtId': ohtId,
      };

  factory _ValveMapItem.fromJson(Map<String, dynamic> json) {
    return _ValveMapItem(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isGsm: json['isGsm'] as bool? ??
          json['id'].toString().toUpperCase().startsWith('GSM'),
      zone: json['zone']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      valveType: json['valveType']?.toString() == 'MAIN' ? 'MAIN' : 'DISTRIBUTION',
      ohtId: json['ohtId']?.toString(),
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
  bool _mapReady = false;
  final Map<String, bool> _ocFaults = {};
  String _locationStatus = 'Phone GPS not active';

  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  void _safeMove(LatLng point, double zoom) {
    if (!_mapReady || !mounted || !_validPoint(point)) return;
    final safeZoom = zoom.clamp(3.0, 19.0).toDouble();
    if (!safeZoom.isFinite) return;
    try {
      _mapController.move(point, safeZoom);
    } catch (_) {
      // The map can be rebuilding while the surrounding ListView changes size.
    }
  }

  void _onMapReady() {
    _mapReady = true;
    final location = _phoneLocation;
    if (location != null) {
      _safeMove(location, 16);
    }
  }

  @override
  void initState() {
    super.initState();
    ValveFaultStorage.changes.addListener(_onFaultStorageChanged);
    _loadValves();
    _locatePhone(initial: true);
  }

  void _onFaultStorageChanged() {
    if (mounted) unawaited(_loadFaults());
  }

  @override
  void dispose() {
    ValveFaultStorage.changes.removeListener(_onFaultStorageChanged);
    _mapNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFaults() async {
    for (final valve in _valves) {
      _ocFaults[valve.id] = await ValveFaultStorage.load(valve.id);
    }
    if (mounted) setState(() {});
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
            _selectedId = null;
            _loading = false;
          });
          await _loadFaults();
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
        _safeMove(location, 16);
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
    final zoneController = TextEditingController();
    final wardController = TextEditingController();
    final ohtController = TextEditingController();
    String valveType = 'DISTRIBUTION';
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
                controller: zoneController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Zone No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: wardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ward No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setDialogState) => DropdownButtonFormField<String>(
                  initialValue: valveType,
                  decoration: const InputDecoration(
                    labelText: 'Valve Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MAIN', child: Text('MAIN')),
                    DropdownMenuItem(value: 'DISTRIBUTION', child: Text('DISTRIBUTION')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => valveType = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (valveType == 'MAIN')
                TextField(
                  controller: ohtController,
                  decoration: const InputDecoration(
                    labelText: 'OHT ID',
                    hintText: 'e.g. OHT-01',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (valveType == 'MAIN') const SizedBox(height: 10),
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
              final zone = zoneController.text.trim();
              final ward = wardController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              final ohtId = ohtController.text.trim();
              if (id.isEmpty ||
                  zone.isEmpty ||
                  ward.isEmpty ||
                  lat == null ||
                  lng == null ||
                  lat < -90 ||
                  lat > 90 ||
                  lng < -180 ||
                  lng > 180 ||
                  (valveType == 'MAIN' && ohtId.isEmpty)) {
                return;
              }
              Navigator.pop(
                context,
                _ValveMapItem(
                  id: id,
                  latitude: lat,
                  longitude: lng,
                  isGsm: id.toUpperCase().startsWith('GSM'),
                  zone: zone,
                  ward: ward,
                  valveType: valveType,
                  ohtId: ohtId.isEmpty ? null : ohtId,
                ),
              );
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      idController.dispose();
      zoneController.dispose();
      wardController.dispose();
      ohtController.dispose();
      latController.dispose();
      lngController.dispose();
    });
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
      _selectedId = null;
    });
    await _saveValves();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.id} saved to map')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _safeMove(LatLng(result.latitude, result.longitude), 16);
        }
      });
    }
  }

  Future<void> _registerByValveId() async {
    final location = _phoneLocation;
    if (location == null) {
      await _locatePhone();
      if (!mounted || _phoneLocation == null) return;
    }

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ManualValveRegistrationDialog(
        latitude: _phoneLocation!.latitude,
        longitude: _phoneLocation!.longitude,
      ),
    );
    if (!mounted || values == null) return;

    final valveId = values['valveId']!.trim();
    final wardId = values['wardId']!.trim();
    final zoneId = values['zoneId']!.trim();
    final valveType = values['valveType']?.trim() == 'MAIN'
        ? 'MAIN'
        : 'DISTRIBUTION';
    final latitude = double.tryParse(values['latitude']!.trim());
    final longitude = double.tryParse(values['longitude']!.trim());
    if (valveId.isEmpty ||
        wardId.isEmpty ||
        zoneId.isEmpty ||
        latitude == null ||
        longitude == null) {
      return;
    }

    final item = _ValveMapItem(
      id: valveId,
      latitude: latitude,
      longitude: longitude,
      isGsm: valveId.toUpperCase().startsWith('GSM'),
      ward: wardId,
      zone: zoneId,
      valveType: valveType,
    );

    if (_valves.any(
      (valve) => valve.id.toUpperCase() == item.id.toUpperCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valve is already on this map.')),
      );
      return;
    }

    // Save locally first. Damaged-QR registration must work even when the
    // municipal server is unavailable or the operator is not logged in.
    setState(() {
      _valves = [..._valves, item];
      _selectedId = item.id;
    });
    await _saveValves();
    await _loadFaults();
    _safeMove(LatLng(item.latitude, item.longitude), 18);

    final prefs = await SharedPreferences.getInstance();
    final bearer = prefs.getString('municipal_access_token');

    if (bearer == null || bearer.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Valve saved on this phone. Server registration is pending until municipal login.',
            ),
          ),
        );
      }
      return;
    }

    final service = ServerApiService(
      baseUrl: const String.fromEnvironment(
        'ORB_SERVER_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
      bearerToken: bearer,
    );

    try {
      final result = await service.registerValveById(
        valveId: valveId,
        wardId: wardId,
        zoneId: zoneId,
        valveType: item.valveType,
        ohtId: item.ohtId,
        latitude: latitude,
        longitude: longitude,
      );

      final serverItem = _ValveMapItem(
        id: result['valve_id']?.toString() ?? item.id,
        latitude: (result['latitude'] as num?)?.toDouble() ?? item.latitude,
        longitude:
            (result['longitude'] as num?)?.toDouble() ?? item.longitude,
        isGsm: item.isGsm,
        ward: result['ward_id']?.toString() ?? item.ward,
        zone: result['zone_id']?.toString() ?? item.zone,
        valveType: item.valveType,
      );

      setState(() {
        _valves = _valves
            .map((v) => v.id.toUpperCase() == item.id.toUpperCase()
                ? serverItem
                : v)
            .toList();
        _selectedId = serverItem.id;
      });
      await _saveValves();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${serverItem.id} saved on phone and registered on server.'),
          ),
        );
      }
    } on ServerApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.id} is saved on this phone. Server registration pending: ${error.body['detail'] ?? error.body}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.id} is saved on this phone. Server registration pending: $error',
            ),
          ),
        );
      }
    }

  }

  Future<void> _scanValveQr() async {
    final location = _phoneLocation;
    if (location == null) {
      await _locatePhone();
      if (!mounted || _phoneLocation == null) return;
    }

    final gps = _phoneLocation!;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddValveQrScreen(
          latitude: gps.latitude,
          longitude: gps.longitude,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final id = result['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final item = _ValveMapItem(
      id: id,
      latitude: (result['latitude'] as num).toDouble(),
      longitude: (result['longitude'] as num).toDouble(),
      isGsm: result['isGsm'] == true,
      ward: result['ward']?.toString() ?? '',
      zone: result['zone']?.toString() ?? '',
      valveType: result['valveType']?.toString() ?? 'DISTRIBUTION',
      ohtId: result['ohtId']?.toString(),
    );

    if (_valves.any(
      (valve) => valve.id.toUpperCase() == item.id.toUpperCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valve ID already exists')),
      );
      return;
    }

    setState(() {
      _valves = [..._valves, item];
      _selectedId = item.id;
    });
    await _saveValves();
    await _loadFaults();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.id} added to the municipal map.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _safeMove(LatLng(item.latitude, item.longitude), 18);
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
      final isFault = _ocFaults[valve.id] == true;
      final pinColor = isFault
          ? Colors.red
          : (valve.isGsm ? Colors.green : Colors.blue);
      return Marker(
        point: LatLng(valve.latitude, valve.longitude),
        width: 110,
        height: 100,
        child: GestureDetector(
          onTap: () => setState(() => _selectedId = valve.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 40,
                color: pinColor,
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
      markers.insert(
        0,
        Marker(
          point: _phoneLocation!,
          width: 36,
          height: 36,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildValveRow(_ValveMapItem valve) {
    final isSelected = valve.id == _selectedId;
    final isFault = _ocFaults[valve.id] == true;
    final pinColor = isFault
        ? Colors.red
        : (valve.isGsm ? Colors.green : Colors.blue);

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
            setState(() => _selectedId = isSelected ? null : valve.id);
            _safeMove(LatLng(valve.latitude, valve.longitude), 16);
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
                    color: pinColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_damage_outlined,
                    color: pinColor,
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
                      Text(
                        'Type: ${valve.valveType == 'MAIN' ? 'MAIN' : 'DISTRIBUTION'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (valve.zone.isNotEmpty || valve.ward.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 14,
                          runSpacing: 2,
                          children: [
                            if (valve.zone.isNotEmpty)
                              Text(
                                'Zone: ${valve.zone}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            if (valve.ward.isNotEmpty)
                              Text(
                                'Ward: ${valve.ward}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          'GPS: ${valve.latitude.toStringAsFixed(6)}, ${valve.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                          onPressed: _scanValveQr,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('SCAN VALVE QR'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _registerByValveId,
                          icon: const Icon(Icons.edit_note),
                          label: const Text('REGISTER BY VALVE ID'),
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
                            onMapReady: _onMapReady,
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
                                  fontSize: 16,
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
                                onPressed: () {
                                  final zoom = _mapController.camera.zoom;
                                  if (zoom.isFinite) {
                                    _safeMove(
                                      _mapController.camera.center,
                                      zoom + 1,
                                    );
                                  }
                                },
                              ),
                              _MapButton(
                                icon: Icons.remove,
                                onPressed: () {
                                  final zoom = _mapController.camera.zoom;
                                  if (zoom.isFinite) {
                                    _safeMove(
                                      _mapController.camera.center,
                                      zoom - 1,
                                    );
                                  }
                                },
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
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _valves.length,
                            itemBuilder: (context, index) =>
                                _buildValveRow(_valves[index]),
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
