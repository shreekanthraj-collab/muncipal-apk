import 'package:flutter/material.dart';

class ValveStatusCard extends StatelessWidget {
  final String status;
  final int requestedPosition;
  final int actualPosition;
  final Color statusColor;
  final VoidCallback onRequestStatus;

  const ValveStatusCard({
    super.key,
    required this.status,
    required this.requestedPosition,
    required this.actualPosition,
    required this.statusColor,
    required this.onRequestStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'VALVE STATUS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 125,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onRequestStatus,
                    child: const Text(
                      'REQUEST\nSTATUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('REQUESTED'),
                      const SizedBox(height: 6),
                      Text(
                        '$requestedPosition%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.grey),
                Expanded(
                  child: Column(
                    children: [
                      const Text('ACTUAL'),
                      const SizedBox(height: 6),
                      Text(
                        '$actualPosition%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
