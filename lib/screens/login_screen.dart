import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/server_api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  late final ServerApiService _server;
  bool _otpRequested = false;
  bool _loading = false;
  String? _error;
  String? _devOtp;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _server = ServerApiService(
      baseUrl: const String.fromEnvironment(
        'ORB_SERVER_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
    );
  }

  Future<void> requestOtp() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter the registered mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _devOtp = null;
    });
    try {
      final response = await _server.requestMunicipalOtp(phone: phone);
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _devOtp = response['debug_otp']?.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP requested.')),
      );
    } on ServerApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _serverError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to request OTP: ${e}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> verifyOtp() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _server.verifyMunicipalOtp(
        phone: phone,
        otp: otp,
      );
      final accessToken = response['access_token']?.toString();
      final operatorId = response['operator_id']?.toString();
      final organizationId = response['organization_id']?.toString();
      final serverRole = response['role']?.toString();
      if (accessToken == null || accessToken.isEmpty ||
          operatorId == null || operatorId.isEmpty ||
          organizationId == null || organizationId.isEmpty ||
          serverRole == null || serverRole.isEmpty) {
        throw const FormatException('Incomplete municipal session returned.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('municipal_access_token', accessToken);
      await prefs.setString('municipal_operator_id', operatorId);
      await prefs.setString('municipal_organization_id', organizationId);
      await prefs.setString('municipal_role', serverRole);
      await prefs.setString('municipal_phone', response['phone']?.toString() ?? phone);
      await prefs.setStringList('municipal_ward_ids', _stringList(response['ward_ids']));
      await prefs.setStringList('municipal_zone_ids', _stringList(response['zone_ids']));
      await prefs.setStringList('municipal_valve_ids', _stringList(response['valve_ids']));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ServerApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _serverError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to verify OTP: ${e}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }

  String _serverError(ServerApiException e) {
    final detail = e.body['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    return 'Server authentication failed (${e.statusCode}).';
  }

  Widget _operatorLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          decoration: const InputDecoration(
            labelText: 'Registered mobile number',
            hintText: '10-digit mobile number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_android),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        if (!_otpRequested)
          FilledButton.icon(
            onPressed: _loading ? null : requestOtp,
            icon: const Icon(Icons.sms),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('REQUEST OTP'),
            ),
          )
        else ...[
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Enter OTP',
              hintText: '6-digit OTP',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.password),
              counterText: '',
            ),
          ),
          if (_devOtp != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Development OTP: ${_devOtp}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : verifyOtp,
            icon: const Icon(Icons.verified_user),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('VERIFY OTP'),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : requestOtp,
            child: const Text('REQUEST OTP AGAIN'),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
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
              const Text('Monitor  •  Control  •  Manage'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Sign in with your registered municipal mobile number. Your role and access scope are assigned by the server.', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      _operatorLogin(),
                      const ListTile(
                        leading: Icon(Icons.phone_android),
                        title: Text('Phone / mobile change'),
                        subtitle: Text('Re-authentication is required if the app mobile number or phone changes.'),
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
