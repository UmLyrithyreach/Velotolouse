import 'package:flutter/material.dart';

class RideTrackerWidget extends StatelessWidget {
  final String formattedDistance;

  const RideTrackerWidget({
    super.key,
    required this.formattedDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Section title
            const Text(
              'Ride in Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Distance value (large, bold)
            Text(
              formattedDistance,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            // Unit label
            const Text(
              'km',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
