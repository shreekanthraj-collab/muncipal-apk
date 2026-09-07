import 'package:flutter/material.dart';

class ValveDetailScreen extends StatefulWidget {
  const ValveDetailScreen({super.key, required this.valveId});

  final String valveId;

  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  String? _pendingCommand;

  void _requestCommand(String command) {
    setState(() => _pendingCommand = command);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $command'),
        content: Text('Send $command command to ${widget.valveId}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _pendingCommand = null);
            },
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _pendingCommand = null);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(content: Text('$command command UI ready; backend not connected.')),
              );
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _pendingCommand != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.valveId)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.circle_outlined),
              title: Text('STATUS'),
              subtitle: Text('No live device data connected yet.'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('CONTROL', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : () => _requestCommand('OPEN'),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('OPEN'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: busy ? null : () => _requestCommand('CLOSE'),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('CLOSE'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _requestCommand('STOP'),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('STOP'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : () => _requestCommand('EMERGENCY STOP'),
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: const Text('EMERGENCY STOP'),
                  ),
                  if (_pendingCommand != null) ...[
                    const SizedBox(height: 12),
                    Text('Preparing $_pendingCommand…', textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.health_and_safety_outlined),
              title: Text('HEALTH'),
              subtitle: Text('Health telemetry will be connected through the backend.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('SCHEDULE'),
              subtitle: Text('Schedule management will be added after the API contract is frozen.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('EVENTS'),
              subtitle: Text('Read-only event history will be connected to the backend.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.build_outlined),
              title: Text('MAINTENANCE'),
              subtitle: Text('Maintenance records will be connected later.'),
            ),
          ),
        ],
      ),
    );
  }
}
