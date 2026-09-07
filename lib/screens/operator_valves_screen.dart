import 'package:flutter/material.dart';

/// Operator valve-list entry point. Live valve data will be connected through
/// the frozen backend contract; this screen does not fabricate device state.
class OperatorValvesScreen extends StatelessWidget {
  const OperatorValvesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valves')),
      body: const Center(
        child: Text('Assigned valve data will appear here after API integration.'),
      ),
    );
  }
}
