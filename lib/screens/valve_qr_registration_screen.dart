import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ValveQrRegistrationScreen extends StatefulWidget {
  const ValveQrRegistrationScreen({super.key});
  @override State<ValveQrRegistrationScreen> createState() => _ValveQrRegistrationScreenState();
}
class _ValveQrRegistrationScreenState extends State<ValveQrRegistrationScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  final TextEditingController _ward = TextEditingController();
  final TextEditingController _zone = TextEditingController();
  bool _busy = false;
  String _message = 'Scan the actuator installation QR';

  @override void dispose() { _scanner.dispose(); _ward.dispose(); _zone.dispose(); super.dispose(); }

  Future<void> _register(String token) async {
    if (_busy) return;
    final ward = _ward.text.trim(), zone = _zone.text.trim();
    if (ward.isEmpty || zone.isEmpty) { setState(() => _message = 'Enter Ward and Zone before scanning.'); return; }
    setState(() { _busy = true; _message = 'Getting phone location...'; });
    await _scanner.stop();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        throw Exception('Location permission is required for valve placement.');
      }
      final position = await Geolocator.getCurrentPosition();
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('municipal_access_token');
      if (accessToken == null || accessToken.isEmpty) throw Exception('Municipal operator session not found. Login again.');
      final baseUrl = prefs.getString('orb_server_base_url') ?? 'http://10.0.2.2:8000';
      final response = await http.post(
        Uri.parse('\$baseUrl/api/v1/municipal/valves/register-placement'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer \$accessToken'},
        body: jsonEncode({'registration_token': token, 'ward_id': ward, 'zone_id': zone, 'latitude': position.latitude, 'longitude': position.longitude}),
      );
      final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(body is Map && body['detail'] != null ? body['detail'].toString() : 'Server registration failed (\${response.statusCode})');
      }
      if (!mounted) return;
      setState(() => _message = 'Valve \${body['valve_id'] ?? ''} registered successfully.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valve registered on municipal map')));
    } catch (e) {
      if (mounted) { setState(() => _message = e.toString().replaceFirst('Exception: ', '')); await _scanner.start(); }
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Register Valve by QR')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16,16,16,8), child: Row(children: [
        Expanded(child: TextField(controller: _ward, decoration: const InputDecoration(labelText: 'Ward ID', border: OutlineInputBorder()))),
        const SizedBox(width: 10),
        Expanded(child: TextField(controller: _zone, decoration: const InputDecoration(labelText: 'Zone ID', border: OutlineInputBorder()))),
      ])),
      Padding(padding: const EdgeInsets.all(16), child: Text(_message, textAlign: TextAlign.center)),
      Expanded(child: MobileScanner(controller: _scanner, onDetect: (capture) {
        final code = capture.barcodes.firstOrNull?.rawValue?.trim();
        if (code != null && code.isNotEmpty) _register(code);
      })),
      Padding(padding: const EdgeInsets.all(16), child: FilledButton.icon(
        onPressed: _busy ? null : () => _scanner.start(),
        icon: const Icon(Icons.qr_code_scanner), label: const Text('SCAN QR'),
      )),
    ]),
  );
}
