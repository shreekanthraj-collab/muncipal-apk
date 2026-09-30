import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class AddValveQrScreen extends StatefulWidget {
  const AddValveQrScreen({super.key});

  @override
  State<AddValveQrScreen> createState() => _AddValveQrScreenState();
}

class _AddValveQrScreenState extends State<AddValveQrScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _handled = false;
  bool _loading = false;
  static const serverBaseUrl = String.fromEnvironment('ORB_SERVER_URL', defaultValue: 'http://10.0.2.2:8000');

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _resolveToken(String token) async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(serverBaseUrl + '/api/v1/installation/resolve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'registration_token': token}),
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        throw Exception('Server rejected QR (' + response.statusCode.toString() + ')');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      final customerId = await _askForId('Customer ID');
      if (customerId == null) return;
      final siteId = await _askForId('Site ID');
      if (siteId == null) return;
      await _confirmInstallation(token, customerId, siteId);
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Valve Found'),
          content: Text(
            'Valve: ' + (data['valve_id'] ?? '').toString() + '\n'
            'Actuator: ' + (data['device_id'] ?? 'Not linked').toString() + '\n'
            'Transport: ' + (data['transport_type'] ?? '').toString() + '\n'
            'Status: ' + (data['installation_status'] ?? '').toString(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUE')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _handled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to register valve: ' + e.toString())),
      );
      _scanner.start();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askForId(String title) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('CONTINUE')),
        ],
      ),
    );
    controller.dispose();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _confirmInstallation(String token, String customerId, String siteId) async {
    final response = await http.post(
      Uri.parse(serverBaseUrl + '/api/v1/installation/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'registration_token': token,
        'customer_id': customerId,
        'site_id': siteId,
      }),
    );
    if (!mounted) return;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Installation confirmation failed (' + response.statusCode.toString() + ')');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Valve installed and activated successfully.')),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scanner.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Text(
              'Place the Orb Drive actuator QR code inside the frame.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
