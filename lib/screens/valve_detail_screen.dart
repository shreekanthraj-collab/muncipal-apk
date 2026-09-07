import 'package:flutter/material.dart';
import '../widgets/command_execution_status.dart';

class ValveDetailScreen extends StatefulWidget {
  const ValveDetailScreen({super.key, required this.valveId});
  final String valveId;
  @override
  State<ValveDetailScreen> createState() => _ValveDetailScreenState();
}

class _ValveDetailScreenState extends State<ValveDetailScreen> {
  String? _command;
  CommandExecutionState? _state;

  void _requestCommand(String command) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirm $command'),
        content: Text('Send $command command to ${widget.valveId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() { _command = command; _state = CommandExecutionState.sending; });
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _state == CommandExecutionState.sending ||
        _state == CommandExecutionState.accepted || _state == CommandExecutionState.executing;
    return Scaffold(
      appBar: AppBar(title: Text(widget.valveId)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(leading: Icon(Icons.circle_outlined), title: Text('STATUS'), subtitle: Text('No live device data connected yet.'))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('CONTROL', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: active ? null : () => _requestCommand('OPEN'), icon: const Icon(Icons.arrow_upward), label: const Text('OPEN'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(onPressed: active ? null : () => _requestCommand('CLOSE'), icon: const Icon(Icons.arrow_downward), label: const Text('CLOSE'))),
          ]),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: active ? null : () => _requestCommand('STOP'), icon: const Icon(Icons.stop_circle_outlined), label: const Text('STOP')),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(onPressed: active ? null : () => _requestCommand('EMERGENCY STOP'), icon: const Icon(Icons.warning_amber_outlined), label: const Text('EMERGENCY STOP')),
        ]))),
        if (_command != null && _state != null) ...[
          const SizedBox(height: 12),
          CommandExecutionStatus(command: _command!, state: _state!),
        ],
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.health_and_safety_outlined), title: Text('HEALTH'), subtitle: Text('Health telemetry will be connected through the backend.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.schedule_outlined), title: Text('SCHEDULE'), subtitle: Text('Schedule management will be added after the API contract is frozen.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.history), title: Text('EVENTS'), subtitle: Text('Read-only event history will be connected to the backend.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.build_outlined), title: Text('MAINTENANCE'), subtitle: Text('Maintenance records will be connected later.'))),
      ]),
    );
  }
}
