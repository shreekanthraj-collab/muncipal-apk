import 'package:flutter/material.dart';

class AddValveQrScreen extends StatefulWidget {
  const AddValveQrScreen({super.key});

  @override
  State<AddValveQrScreen> createState() => _AddValveQrScreenState();
}

class _AddValveQrScreenState extends State<AddValveQrScreen> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submitToken() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan or enter the valve registration token.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token captured. Server resolve will be connected next.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Valve')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner, size: 96),
            const SizedBox(height: 20),
            const Text(
              'Scan the QR code on the Orb Drive actuator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitToken,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN VALVE QR'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera scanning will be connected next. A registration token can be entered below for API testing.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Registration token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _submitToken,
              child: const Text('TEST TOKEN'),
            ),
          ],
        ),
      ),
    );
  }
}
