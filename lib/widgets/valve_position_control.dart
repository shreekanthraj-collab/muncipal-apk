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

  Widget percentageButton(int position) {
    final selected = selectedPosition == position;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () => selectPosition(position),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor:
                  selected ? Colors.blue : Colors.transparent,
              foregroundColor: selected ? Colors.white : Colors.blue,
              side: BorderSide(
                color: selected ? Colors.blue : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '$position%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
              onChanged: (value) => selectPosition(value.round()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                percentageButton(0),
                percentageButton(25),
                percentageButton(50),
                percentageButton(75),
                percentageButton(100),
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