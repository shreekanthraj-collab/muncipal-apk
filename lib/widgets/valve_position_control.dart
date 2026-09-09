import 'package:flutter/material.dart';

class ValvePositionControl extends StatelessWidget {
  final int selectedPosition;
  final ValueChanged<int> selectPosition;
  final VoidCallback setValve;
  final VoidCallback stopValve;

  const ValvePositionControl({
    super.key,
    required this.selectedPosition,
    required this.selectPosition,
    required this.setValve,
    required this.stopValve,
  });

  Widget _positionButton(int position) {
    final selected = selectedPosition == position;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: () => selectPosition(position),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            side: BorderSide(
              width: selected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            '$position%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
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
            const Text(
              'VALVE OPENING',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
              label: '$selectedPosition%',
              onChanged: (value) =>
                  selectPosition(value.round()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _positionButton(0),
                _positionButton(25),
                _positionButton(50),
                _positionButton(75),
                _positionButton(100),
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
