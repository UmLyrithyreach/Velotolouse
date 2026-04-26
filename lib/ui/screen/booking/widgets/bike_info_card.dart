import 'package:flutter/material.dart';
import 'package:velotolouse/model/bike/bike.dart';

class BikeInfoCard extends StatelessWidget {
  final Bike bike;

  const BikeInfoCard({super.key, required this.bike});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike name (bold, large)
            Text(
              bike.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Bike ID
            Text(
              'ID: ${bike.bikeId}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Status badge with conditional color
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bike.status == 'available' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bike.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
