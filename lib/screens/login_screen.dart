import 'package:flutter/material.dart';

import '../services/server_api_service.dart';
import '../services/municipal_session.dart';
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
      final response = await _server.verifyMunicipalOtp(phone: phone, otp: otp);
      final session = MunicipalSession.fromJson(response);
      await MunicipalSessionStorage.save(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on ServerApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _serverError(e));
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Invalid municipal session: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to verify OTP: ${e}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  void forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Authentication will be sent to the registered mobile number. '
          'If the app mobile number or phone changes, re-authentication is required.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
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
                      const Text('Your role and access scope are loaded from the municipal server.', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      const Text(
                        'Municipal operator sign-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 18),
                      _operatorLogin(),
                      const ListTile(
                          leading: Icon(Icons.verified_user),
                          title: Text('Authentication Required'),
                          subtitle: Text('Authentication is required for the registered mobile number.'),
                        ),
                      ],
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
