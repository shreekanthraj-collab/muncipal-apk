import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

/// Operator login UI foundation.
/// Real authentication remains deferred until the backend authentication
/// contract is frozen. The current submit action only advances the UI flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.water_drop_outlined, size: 56,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('ORBI DRIVE', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 6),
                    const Text('Operator Login', textAlign: TextAlign.center),
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _userController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Operator ID / Phone / Email',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter your Operator ID'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _rememberMe,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Remember me'),
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('LOGIN'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password recovery service not connected yet.')),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                    const SizedBox(height: 28),
                    Text('Operator APK v1.0.0', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
