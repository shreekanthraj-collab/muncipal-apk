import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/server_api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'Agent / Operator';
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  late final ServerApiService _server;
  bool _otpRequested = false;
  bool _loading = false;
  String? _error;
  String? _devOtp;
  bool _biometricEnabled = false;
  bool _hasSavedSession = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    passwordController.dispose();
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
    _loadSavedSessionState();
  }

  Future<void> _loadSavedSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await _secureStorage.read(key: 'municipal_access_token');
    if (!mounted) return;
    setState(() {
      _biometricEnabled = prefs.getBool('municipal_biometric_enabled') ?? false;
      _hasSavedSession = token != null && token.isNotEmpty &&
          (prefs.getString('municipal_operator_id')?.isNotEmpty ?? false);
    });
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _secureStorage.read(key: 'municipal_access_token');
      final operatorId = prefs.getString('municipal_operator_id');
      if (!_biometricEnabled || token == null || token.isEmpty || operatorId == null || operatorId.isEmpty) {
        throw Exception('No saved biometric session. Sign in with OTP.');
      }
      final available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!available) throw Exception('Biometric authentication is unavailable on this device.');
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your municipal operator session',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return;
      _server.bearerToken = token;
      final session = await _server.validateMunicipalSession();
      if (session['valid'] != true || session['operator_id']?.toString() != operatorId) {
        throw const FormatException('Server session validation failed. Sign in with OTP.');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on ServerApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _secureStorage.delete(key: 'municipal_access_token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('municipal_access_token');
        await prefs.remove('municipal_operator_id');
        await prefs.setBool('municipal_biometric_enabled', false);
        if (mounted) setState(() { _biometricEnabled = false; _hasSavedSession = false; });
      }
      if (mounted) setState(() => _error = _serverError(e));
    } catch (e) {
      if (mounted) setState(() => _error = 'Biometric unlock failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _offerBiometricEnrollment() async {
    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable fingerprint login?'),
        content: const Text('Use this device\'s biometric unlock for future sign-ins. The server will still validate your session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NOT NOW')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ENABLE')),
        ],
      ),
    ) ?? false;
    if (!enable) return false;
    try {
      final supported = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!supported) throw Exception('This device does not support biometric authentication.');
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm fingerprint login setup',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('municipal_biometric_enabled', true);
      if (mounted) setState(() { _biometricEnabled = true; _hasSavedSession = true; });
      return true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fingerprint setup unavailable: $e')));
      return false;
    }
  }

  Future<void> login() async {
    // Provision an existing municipal session for server communication.
    // This keeps the existing login UI and navigation unchanged.
    const accessToken = String.fromEnvironment('ORB_MUNICIPAL_ACCESS_TOKEN');
    const operatorId = String.fromEnvironment('ORB_MUNICIPAL_OPERATOR_ID');

    if (accessToken.isNotEmpty && operatorId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await _secureStorage.write(key: 'municipal_access_token', value: accessToken);
      await prefs.setString('municipal_operator_id', operatorId);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      if (accessToken == null || accessToken.isEmpty ||
          operatorId == null || operatorId.isEmpty) {
        throw const FormatException('Incomplete municipal session returned.');
      }
      final prefs = await SharedPreferences.getInstance();
      await _secureStorage.write(key: 'municipal_access_token', value: accessToken);
      await prefs.remove('municipal_access_token');
      await prefs.setString('municipal_operator_id', operatorId);
      await _offerBiometricEnrollment();
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
        if (_biometricEnabled && _hasSavedSession) ...[
          FilledButton.icon(
            onPressed: _loading ? null : _unlockWithBiometrics,
            icon: const Icon(Icons.fingerprint),
            label: const Padding(padding: EdgeInsets.all(12), child: Text('BIOMETRIC UNLOCK')),
          ),
          const SizedBox(height: 8),
        ],
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
                      const Text('Select your role to continue', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
                          ButtonSegment(value: 'Agent / Operator', label: Text('Agent / Operator'), icon: Icon(Icons.groups)),
                        ],
                        selected: {role},
                        onSelectionChanged: (value) => setState(() => role = value.first),
                      ),
                      const SizedBox(height: 18),
                      if (role == 'Agent / Operator')
                        _operatorLogin()
                      else ...[
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: forgotPassword, child: const Text('Forgot Password?')),
                        ),
                        FilledButton(
                          onPressed: _loading ? null : login,
                          child: const Padding(padding: EdgeInsets.all(12), child: Text('LOGIN')),
                        ),
                        const SizedBox(height: 14),
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
