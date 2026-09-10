import 'package:flutter/material.dart';

class ValveStatusCard extends StatelessWidget {
  final String status;
  final int requestedPosition;
  final int actualPosition;
  final Color statusColor;
  final bool connected;
  final int rssi;
  final String firmwareVersion;
  final double batteryVoltage;
  final bool batteryLowBypass;
  final bool overCurrent;
  final double overCurrentThresholdA;

  const ValveStatusCard({
    super.key,
    required this.status,
    required this.requestedPosition,
    required this.actualPosition,
    required this.statusColor,
    this.connected = false,
    this.rssi = 0,
    this.firmwareVersion = '—',
    this.batteryVoltage = 0,
    this.batteryLowBypass = false,
    this.overCurrent = false,
    this.overCurrentThresholdA = 0,
  });

  Widget _rssiBars() {
    final level = rssi >= -70 ? 3 : rssi >= -85 ? 2 : rssi >= -100 ? 1 : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 8.0 + index * 5,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index < level ? Colors.green : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _info(String label, String value, {Widget? trailing}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('VALVE STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(status, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(height: 22),
            Row(
              children: [
                _info('REQUESTED', '$requestedPosition%'),
                Container(width: 1, height: 45, color: Colors.grey.shade300),
                _info('ACTUAL', '$actualPosition%'),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _info('CONNECTION', connected ? 'ONLINE' : 'OFFLINE'),
                _info('RSSI', '', trailing: _rssiBars()),
                _info('FIRMWARE', firmwareVersion),
              ],
            ),
            if (batteryLowBypass || overCurrent) ...[
              const SizedBox(height: 14),
              if (batteryLowBypass)
                const ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.battery_alert, color: Colors.orange),
                  title: Text('LOW BATTERY BYPASS', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Valve safety bypass is active.'),
                ),
              if (overCurrent)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: const Text('OVER-CURRENT TRIP', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(overCurrentThresholdA > 0 ? 'Threshold ${overCurrentThresholdA.toStringAsFixed(2)} A' : 'Current protection active.'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
