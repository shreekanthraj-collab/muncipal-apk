import 'package:flutter/material.dart';

class ValvePositionControl extends StatelessWidget {
  final int selectedPosition;
  final ValueChanged<int> selectPosition;
  final Widget Function(int position) positionButton;
  final VoidCallback setValve;
  final VoidCallback stopValve;

  const ValvePositionControl({
    super.key,
    required this.selectedPosition,
    required this.selectPosition,
    required this.positionButton,
    required this.setValve,
    required this.stopValve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'VALVE OPENING',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              '$selectedPosition%',
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Slider(
              value: selectedPosition.toDouble(),
              min: 0,
              max: 100,
              divisions: 4,
              label: '%',
              onChanged: (value) => selectPosition(value.round()),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                positionButton(0),
                positionButton(25),
                positionButton(50),
                positionButton(75),
                positionButton(100),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: setValve,
                child: Text(
                  'SET VALVE TO $selectedPosition%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: stopValve,
                child: const Text(
                  'STOP VALVE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
