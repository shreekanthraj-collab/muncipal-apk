import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool otpSent = false;
  bool loading = false;
  String role = 'Admin';

  static const serverBaseUrl = String.fromEnvironment(
    'ORB_SERVER_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> requestOtp() async {
    final phone = phoneController.text.trim();
    if (phone.length < 10) {
      _error('Enter the registered operator phone number.');
      return;
    }
    setState(() => loading = true);
    try {
      final r = await http.post(
        Uri.parse('$serverBaseUrl/api/v1/municipal/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (r.statusCode != 200) {
        throw Exception('Phone is not an active municipal operator.');
      }
      setState(() => otpSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to the registered operator phone.')),
        );
      }
    } catch (e) {
      _error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyOtp() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      _error('Enter the 6-digit OTP.');
      return;
    }
    setState(() => loading = true);
    try {
      final r = await http.post(
        Uri.parse('$serverBaseUrl/api/v1/municipal/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );
      if (r.statusCode != 200) {
        throw Exception('Invalid or expired OTP.');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('municipal_access_token', data['access_token'].toString());
      await prefs.setString('municipal_operator_id', data['operator_id'].toString());
      await prefs.setString('municipal_organization_id', data['organization_id'].toString());
      await prefs.setString('municipal_operator_phone', data['phone'].toString());
      await prefs.setString('municipal_operator_role', data['role'].toString());
      await prefs.setStringList('municipal_ward_ids', (data['ward_ids'] as List? ?? const []).map((e) => e.toString()).toList());
      await prefs.setStringList('municipal_zone_ids', (data['zone_ids'] as List? ?? const []).map((e) => e.toString()).toList());
      await prefs.setStringList('municipal_valve_ids', (data['valve_ids'] as List? ?? const []).map((e) => e.toString()).toList());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            children: [
              const Icon(Icons.water_drop, size: 72, color: Colors.blue),
              const SizedBox(height: 8),
              const Text('Smart Valve Management', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const Text('Municipal SCADA Operator Access'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Operator Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 18),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Registered operator phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!otpSent)
                        FilledButton(
                          onPressed: loading ? null : requestOtp,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(loading ? 'REQUESTING OTP…' : 'SEND OTP'),
                          ),
                        )
                      else ...[
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-digit OTP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.password),
                          ),
                        ),
                        FilledButton(
                          onPressed: loading ? null : verifyOtp,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(loading ? 'VERIFYING…' : 'VERIFY & LOGIN'),
                          ),
                        ),
                        TextButton(
                          onPressed: loading ? null : requestOtp,
                          child: const Text('Resend OTP'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const ListTile(
                        leading: Icon(Icons.verified_user),
                        title: Text('Server authenticated'),
                        subtitle: Text('Your role, ward and zone permissions come from ORB-DRIVE-SERVER.'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
