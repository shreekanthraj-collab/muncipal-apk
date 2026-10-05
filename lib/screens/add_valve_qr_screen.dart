import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddValveQrScreen extends StatefulWidget {
  const AddValveQrScreen({super.key, required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
  @override
  State<AddValveQrScreen> createState() => _AddValveQrScreenState();
}

class _AddValveQrScreenState extends State<AddValveQrScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _handled = false;
  bool _loading = false;
  static const serverBaseUrl = String.fromEnvironment('ORB_SERVER_URL', defaultValue: 'http://10.0.2.2:8000');

  @override
  void dispose() { _scanner.dispose(); super.dispose(); }

  Future<Map<String, String>?> _askPlacement() async {
    final ward = TextEditingController();
    final zone = TextEditingController();
    final oht = TextEditingController();
    String valveType = 'DISTRIBUTION';
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Valve placement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GPS: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: valveType,
                decoration: const InputDecoration(labelText: 'Valve Type'),
                items: const [
                  DropdownMenuItem(value: 'MAIN', child: Text('MAIN')),
                  DropdownMenuItem(value: 'DISTRIBUTION', child: Text('DISTRIBUTION')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => valveType = value);
                },
              ),
              const SizedBox(height: 8),
              TextField(controller: ward, decoration: const InputDecoration(labelText: 'Ward ID')),
              const SizedBox(height: 8),
              TextField(controller: zone, decoration: const InputDecoration(labelText: 'Zone ID')),
              if (valveType == 'MAIN') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: oht,
                  decoration: const InputDecoration(
                    labelText: 'OHT ID',
                    hintText: 'e.g. OHT-01',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () {
                final w = ward.text.trim(), z = zone.text.trim();
                if (w.isEmpty || z.isEmpty) return;
                final o = oht.text.trim();
                if (valveType == 'MAIN' && o.isEmpty) return;
                Navigator.pop(context, {
                  'ward_id': w,
                  'zone_id': z,
                  'valve_type': valveType,
                  if (o.isNotEmpty) 'oht_id': o,
                });
              },
              child: const Text('REGISTER'),
            ),
          ],
        ),
      ),
    );
    ward.dispose();
    zone.dispose();
    oht.dispose();
    return result;
  }

  Future<void> _resolveToken(String token) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final operatorId = prefs.getString('municipal_operator_id');
      final accessToken = prefs.getString('municipal_access_token');
      if (operatorId == null || operatorId.trim().isEmpty || accessToken == null || accessToken.trim().isEmpty) {
        throw Exception('Operator session is not linked to this APK. Sign in as a municipal operator first.');
      }

      final preview = await http.get(
        Uri.parse('$serverBaseUrl/api/v1/municipal/valves/scan-preview/${Uri.encodeComponent(token)}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (preview.statusCode != 200) {
        dynamic detail;
        try { detail = jsonDecode(preview.body)['detail']; } catch (_) {}
        throw Exception(detail?.toString() ?? 'QR is invalid or already claimed');
      }
      final data = jsonDecode(preview.body) as Map<String, dynamic>;

      final placement = await _askPlacement();
      if (placement == null) {
        if (mounted) setState(() => _handled = false);
        _scanner.start();
        return;
      }

      final register = await http.post(
        Uri.parse('$serverBaseUrl/api/v1/municipal/valves/register-placement'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'registration_token': token,
          'ward_id': placement['ward_id'],
          'zone_id': placement['zone_id'],
          'valve_type': placement['valve_type'] ?? 'DISTRIBUTION',
          if (placement['oht_id'] != null) 'oht_id': placement['oht_id'],
          'latitude': widget.latitude,
          'longitude': widget.longitude,
        }),
      );
      if (register.statusCode != 200 && register.statusCode != 201) {
        throw Exception('Valve registration rejected (${register.statusCode})');
      }

      final rawSaved = jsonDecode(register.body) as Map<String, dynamic>;

      // Normalize the server's asset_bundle response to the existing
      // screen contract without changing the UI or registration flow.
      final assetBundle = rawSaved['asset_bundle'] is Map
          ? Map<String, dynamic>.from(rawSaved['asset_bundle'] as Map)
          : <String, dynamic>{};
      final saved = <String, dynamic>{
        ...rawSaved,
        if (assetBundle['valve'] is Map) 'valve': assetBundle['valve'],
        if (assetBundle['actuator'] is Map) 'actuator': assetBundle['actuator'],
        if (assetBundle['sim'] is Map) 'sim': assetBundle['sim'],
        if (assetBundle['aws_thing'] is Map) 'aws_thing': assetBundle['aws_thing'],
        if (assetBundle['registration_token'] is Map) 'registration_token': assetBundle['registration_token'],
        if (assetBundle['billing'] is Map) 'billing': assetBundle['billing'],
      };

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Valve Registered'),
          content: _registrationSummary(saved, data),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('DONE')),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'id': saved['valve_id']?.toString() ?? data['valve_id']?.toString() ?? '',
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'ward': saved['ward_id']?.toString() ?? '',
        'zone': saved['zone_id']?.toString() ?? '',
        'isGsm': data['transport_type']?.toString().toUpperCase() == 'GSM',
        'valveType': placement['valve_type'] ?? 'DISTRIBUTION',
        'ohtId': placement['oht_id'],
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _handled = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to register valve: $e')));
      _scanner.start();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Widget _registrationSummary(Map<String, dynamic> saved, Map<String, dynamic> preview) {
    final valve = Map<String, dynamic>.from(saved['valve'] ?? <String, dynamic>{});
    final placement = Map<String, dynamic>.from(saved['placement'] ?? <String, dynamic>{});
    final actuator = saved['actuator'] is Map ? Map<String, dynamic>.from(saved['actuator']) : null;
    final sim = saved['sim'] is Map ? Map<String, dynamic>.from(saved['sim']) : null;
    final aws = saved['aws_thing'] is Map ? Map<String, dynamic>.from(saved['aws_thing']) : null;
    String state(Map<String, dynamic>? x) => x == null ? 'PENDING' : (x['status']?.toString() ?? 'ACTIVE');
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Valve: ${valve['valve_id'] ?? saved['valve_id'] ?? preview['valve_id'] ?? ''}'),
      Text('Ward: ${placement['ward_id'] ?? saved['ward_id'] ?? ''}'),
      Text('Zone: ${placement['zone_id'] ?? saved['zone_id'] ?? ''}'),
      Text('GPS: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}'),
      const Divider(),
      Text('Actuator: ${actuator?['device_id'] ?? 'PENDING'}'),
      Text('IMEI: ${actuator?['imei'] ?? 'PENDING'}'),
      Text('Firmware: ${actuator?['firmware_version'] ?? 'PENDING'}'),
      const SizedBox(height: 6),
      Text('SIM: ${sim?['msisdn'] ?? 'PENDING'}'),
      Text('ICCID: ${sim?['iccid'] ?? 'PENDING'}'),
      Text('SIM status: ${state(sim)}'),
      const SizedBox(height: 6),
      Text('AWS Thing: ${aws?['thing_name'] ?? 'PENDING'}'),
      Text('AWS status: ${state(aws)}'),
    ]));
  }
  void _onDetect(BarcodeCapture capture) {
    if (_handled || _loading) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      _scanner.stop();
      _resolveToken(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Valve QR'),
        actions: [IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _scanner.toggleTorch())],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          Center(child: Container(width: 260, height: 260, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)))),
          Positioned(
            left: 24, right: 24, bottom: 70,
            child: Text(
              'Scan the actuator QR.\nGPS: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4)]),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
