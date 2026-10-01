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
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Valve placement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GPS: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            TextField(controller: ward, decoration: const InputDecoration(labelText: 'Ward ID')),
            const SizedBox(height: 8),
            TextField(controller: zone, decoration: const InputDecoration(labelText: 'Zone ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              final w = ward.text.trim(), z = zone.text.trim();
              if (w.isEmpty || z.isEmpty) return;
              Navigator.pop(context, {'ward_id': w, 'zone_id': z});
            },
            child: const Text('REGISTER'),
          ),
        ],
      ),
    );
    ward.dispose(); zone.dispose();
    return result;
  }

  Future<void> _resolveToken(String token) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final operatorId = prefs.getString('municipal_operator_id');
      if (operatorId == null || operatorId.trim().isEmpty) {
        throw Exception('Operator session is not linked to this APK. Sign in as a municipal operator first.');
      }

      final response = await http.post(
        Uri.parse('$serverBaseUrl/api/v1/installation/resolve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'registration_token': token}),
      );
      if (response.statusCode != 200) throw Exception('Server rejected QR (${response.statusCode})');
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final placement = await _askPlacement();
      if (placement == null) {
        if (mounted) setState(() => _handled = false);
        _scanner.start();
        return;
      }

      final register = await http.post(
        Uri.parse('$serverBaseUrl/api/v1/municipal/valves/register-placement'),
        headers: {'Content-Type': 'application/json', 'X-Operator-Id': operatorId},
        body: jsonEncode({
          'registration_token': token,
          'ward_id': placement['ward_id'],
          'zone_id': placement['zone_id'],
          'latitude': widget.latitude,
          'longitude': widget.longitude,
        }),
      );
      if (register.statusCode != 200 && register.statusCode != 201) {
        throw Exception('Valve registration rejected (${register.statusCode})');
      }

      final saved = jsonDecode(register.body) as Map<String, dynamic>;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Valve Registered'),
          content: Text(
            'Valve: ${saved['valve_id'] ?? data['valve_id'] ?? ''}\n'
            'Ward: ${saved['ward_id'] ?? ''}\n'
            'Zone: ${saved['zone_id'] ?? ''}\n'
            'GPS: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
          ),
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
        'valveType': 'DISTRIBUTION',
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
