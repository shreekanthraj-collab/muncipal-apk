import 'package:flutter/material.dart';

import '../models/valve_command.dart';

typedef CommandSender = Future<void> Function(ValveCommand command);

class GatewayCommandPanel extends StatelessWidget {
  final String valveId;
  final CommandSender sendCommand;

  const GatewayCommandPanel({
    super.key,
    required this.valveId,
    required this.sendCommand,
  });

  Widget _button({
    required BuildContext context,
    required String label,
    required String command,
    int value = 0,
    IconData? icon,
    bool destructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await sendCommand(
              ValveCommand(
                valveId: valveId,
                command: command,
                value: value,
              ),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label command sent')),
            );
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label failed: $error')),
            );
          }
        },
        icon: Icon(icon ?? Icons.tune),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: destructive
            ? OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'GATEWAY COMMANDS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _button(
              context: context,
              label: 'OPEN',
              command: 'OPEN',
              icon: Icons.lock_open,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CLOSE',
              command: 'CLOSE',
              icon: Icons.lock,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'STOP',
              command: 'STOP',
              icon: Icons.stop_circle_outlined,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'GET STATUS',
              command: 'GET_STATUS',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CLEAR FAULT',
              command: 'CLEAR_FAULT',
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET TURNS',
              command: 'SET_TURNS',
              icon: Icons.rotate_right,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET CURRENT',
              command: 'SET_CURRENT',
              icon: Icons.electric_bolt,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET DISENGAGE CURRENT',
              command: 'SET_DISENGAGE_CURRENT',
              icon: Icons.power_off,
            ),
            const SizedBox(height: 14),
            const Text(
              'CALIBRATION',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CALIBRATE',
              command: 'CALIBRATE',
              icon: Icons.settings,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CAL SET',
              command: 'CAL_SET',
              icon: Icons.save,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CAL ABORT',
              command: 'CAL_ABORT',
              icon: Icons.cancel_outlined,
              destructive: true,
            ),
            const SizedBox(height: 14),
            const Text(
              'SCHEDULE / SYSTEM',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET SCHEDULE',
              command: 'SET_SCHEDULE',
              icon: Icons.schedule,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'CLEAR SCHEDULE',
              command: 'CLR_SCHEDULE',
              icon: Icons.delete_outline,
              destructive: true,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'GET SCHEDULE',
              command: 'GET_SCHEDULE',
              icon: Icons.event_note,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET CHANNEL',
              command: 'SET_CHANNEL',
              icon: Icons.settings_input_antenna,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'VOLTAGE BYPASS',
              command: 'VOLTAGE_BYPASS',
              icon: Icons.battery_alert,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'VOLTAGE CANCEL',
              command: 'VOLTAGE_CANCEL',
              icon: Icons.battery_unknown,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'SET TIME',
              command: 'SET_TIME',
              icon: Icons.access_time,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'REBIND OWNER',
              command: 'REBIND_OWNER',
              icon: Icons.link,
              destructive: true,
            ),
            const SizedBox(height: 8),
            _button(
              context: context,
              label: 'ENTER EOL',
              command: 'ENTER_EOL',
              icon: Icons.factory_outlined,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}
