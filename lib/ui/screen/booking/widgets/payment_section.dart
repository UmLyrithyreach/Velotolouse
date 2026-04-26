import 'package:flutter/material.dart';
import 'package:velotolouse/ui/widgets/primary_button.dart';

class PaymentSection extends StatelessWidget {
  final VoidCallback onKHQRPressed;

  const PaymentSection({
    super.key,
    required this.onKHQRPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section title
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // KHQR payment button
            PrimaryButton(
              text: 'Proceed with KHQR',
              onPressed: onKHQRPressed,
            ),
          ],
        ),
      ),
    );
  }
}
