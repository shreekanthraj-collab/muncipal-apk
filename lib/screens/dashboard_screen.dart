import 'package:flutter/material.dart';

/// Operator dashboard shell. Data/API integration is intentionally deferred
/// until the backend contract is frozen.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ORBI DRIVE'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Operator Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _SummaryCard(label: 'TOTAL', value: '—')),
              SizedBox(width: 8),
              Expanded(child: _SummaryCard(label: 'ONLINE', value: '—')),
              SizedBox(width: 8),
              Expanded(child: _SummaryCard(label: 'FAULT', value: '—')),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionCard(
            title: 'Recent Alerts',
            icon: Icons.notifications_none,
            message: 'No live alert data connected yet.',
          ),
          const SizedBox(height: 12),
          const _SectionCard(
            title: 'Recent Activity',
            icon: Icons.history,
            message: 'No live event data connected yet.',
          ),
          const SizedBox(height: 12),
          const _SectionCard(
            title: 'Valves',
            icon: Icons.water_drop_outlined,
            message: 'Valve list integration is the next navigation step.',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: 'Valves'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Alerts'),
        ],
        onDestinationSelected: (_) {},
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.message});
  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
