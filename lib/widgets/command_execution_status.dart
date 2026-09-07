import 'package:flutter/material.dart';

enum CommandExecutionState { sending, accepted, executing, completed, failed, timeout }

class CommandExecutionStatus extends StatelessWidget {
  const CommandExecutionStatus({
    super.key,
    required this.command,
    required this.state,
  });

  final String command;
  final CommandExecutionState state;

  String get label => switch (state) {
        CommandExecutionState.sending => 'SENDING',
        CommandExecutionState.accepted => 'ACCEPTED',
        CommandExecutionState.executing => 'EXECUTING',
        CommandExecutionState.completed => 'COMPLETED',
        CommandExecutionState.failed => 'FAILED',
        CommandExecutionState.timeout => 'TIMEOUT',
      };

  bool get active => state == CommandExecutionState.sending ||
      state == CommandExecutionState.accepted ||
      state == CommandExecutionState.executing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COMMAND STATUS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Command: $command'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: active ? null : 1),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_description),
          ],
        ),
      ),
    );
  }

  String get _description => switch (state) {
        CommandExecutionState.sending => 'Command is being submitted.',
        CommandExecutionState.accepted => 'Command was accepted for processing.',
        CommandExecutionState.executing => 'Device execution is in progress.',
        CommandExecutionState.completed => 'Command completed successfully.',
        CommandExecutionState.failed => 'Command failed. Check the event details.',
        CommandExecutionState.timeout => 'No final response was received before timeout.',
      };
}
