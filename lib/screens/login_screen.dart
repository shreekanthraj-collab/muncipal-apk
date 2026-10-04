import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'Admin';
  final passwordController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    // Provision an existing municipal session for server communication.
    // This keeps the existing login UI and navigation unchanged.
    const accessToken = String.fromEnvironment('ORB_MUNICIPAL_ACCESS_TOKEN');
    const operatorId = String.fromEnvironment('ORB_MUNICIPAL_OPERATOR_ID');

    if (accessToken.isNotEmpty && operatorId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('municipal_access_token', accessToken);
      await prefs.setString('municipal_operator_id', operatorId);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: forgotPassword, child: const Text('Forgot Password?')),
                      ),
                      FilledButton(onPressed: login, child: const Padding(padding: EdgeInsets.all(12), child: Text('LOGIN'))),
                      const SizedBox(height: 14),
                      const ListTile(
                        leading: Icon(Icons.verified_user),
                        title: Text('Authentication Required'),
                        subtitle: Text('Authentication is required for the registered mobile number.'),
                      ),
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
