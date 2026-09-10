import 'package:flutter/material.dart';

class CurrentLimitsPanel extends StatelessWidget {
  final double minimumCurrentA;
  final double maximumCurrentA;
  final ValueChanged<double> onMinimumChanged;
  final ValueChanged<double> onMaximumChanged;
  final VoidCallback onSave;

  const CurrentLimitsPanel({
    super.key,
    required this.minimumCurrentA,
    required this.maximumCurrentA,
    required this.onMinimumChanged,
    required this.onMaximumChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CURRENT LIMITS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _field(
              label: 'MIN CURRENT (A)',
              value: minimumCurrentA,
              onChanged: onMinimumChanged,
            ),
            const SizedBox(height: 12),
            _field(
              label: 'MAX CURRENT (A)',
              value: maximumCurrentA,
              onChanged: onMaximumChanged,
            ),
            const SizedBox(height: 12),
            const Text(
              'Allowed range: 0.1 A to 8.0 A',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onSave,
              child: const Text('SAVE CURRENT LIMITS'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return TextFormField(
      initialValue: value.toStringAsFixed(1),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}
