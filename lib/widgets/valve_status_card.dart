import 'package:flutter/material.dart';

class ValveStatusCard extends StatelessWidget {
  final String status;
  final int requestedPosition;
  final int actualPosition;
  final Color statusColor;
  final int? rssi;

  const ValveStatusCard({
    super.key,
    required this.status,
    required this.requestedPosition,
    required this.actualPosition,
    required this.statusColor,
    this.rssi,
  });

  int _rssiBars(int? value) {
    if (value == null) return 0;
    if (value >= -70) return 3;
    if (value >= -90) return 2;
    return 1;
  }

  Widget _rssiIndicator() {
    final bars = _rssiBars(rssi);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        final height = 8.0 + (index * 5.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 7,
            height: height,
            decoration: BoxDecoration(
              color: index < bars ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('VALVE STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('RSSI'),
              const SizedBox(width: 10),
              _rssiIndicator(),
            ]),
            const SizedBox(height: 25),
            Row(children: [
              Expanded(child: Column(children: [
                const Text('REQUESTED'),
                const SizedBox(height: 6),
                Text('$requestedPosition%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ])),
              Container(width: 1, height: 50, color: Colors.grey),
              Expanded(child: Column(children: [
                const Text('ACTUAL'),
                const SizedBox(height: 6),
                Text('$actualPosition%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ])),
            ]),
          ],
        ),
      ),
    );
  }
}
