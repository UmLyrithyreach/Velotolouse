import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/model/bike/bike.dart';
import 'package:velotolouse/ui/screen/booking/view_model/booking_viewmodel.dart';
import 'package:velotolouse/ui/screen/booking/widgets/bike_info_card.dart';
import 'package:velotolouse/ui/screen/booking/widgets/payment_section.dart';
import 'package:velotolouse/ui/screen/booking/widgets/ride_tracker_widget.dart';
import 'package:velotolouse/ui/widgets/primary_button.dart';

class BookingScreen extends StatefulWidget {
  final Bike bike;

  const BookingScreen({super.key, required this.bike});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the ViewModel with the selected bike
    Future.microtask(() {
      context.read<BookingViewModel>().initializeWithBike(widget.bike);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the ViewModel for state changes
    final viewModel = context.watch<BookingViewModel>();

    // Show error dialog if there's an error
    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showErrorDialog(viewModel.errorMessage!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Bike'),
        // Automatic back button enabled
      ),
      body: viewModel.selectedBike == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Display bike information
                  BikeInfoCard(bike: viewModel.selectedBike!),

                  // Show loading while creating booking
                  if (!viewModel.isBookingCreated && viewModel.errorMessage == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creating booking...'),
                          ],
                        ),
                      ),
                    ),

                  // Show payment section if booking created but payment not completed
                  if (viewModel.isBookingCreated && !viewModel.isPaymentCompleted)
                    PaymentSection(
                      onKHQRPressed: () async {
                        await viewModel.proceedWithKHQR();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment completed'),
                            ),
                          );
                        }
                      },
                    ),

                  // Show ride tracker if ride is active
                  if (viewModel.isRideActive)
                    RideTrackerWidget(
                      formattedDistance: viewModel.formattedDistance,
                    ),

                  // Action buttons section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Start Ride button (shown when payment completed and ride not active)
                        if (viewModel.canStartRide)
                          PrimaryButton(
                            text: 'Start Ride',
                            onPressed: () async {
                              await viewModel.startRide();
                            },
                          ),

                        // End Ride button (shown when ride is active)
                        if (viewModel.canEndRide)
                          PrimaryButton(
                            text: 'End Ride',
                            onPressed: () async {
                              final result = await viewModel.endRide();
                              if (context.mounted && result != null) {
                                await _showRideCompletedDialog(
                                  result.distanceKm,
                                  result.price,
                                );
                                // Navigate back to map screen
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show ride completed dialog with distance and price
  Future<void> _showRideCompletedDialog(double distance, double price) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ride Completed'),
        content: Text(
          'Distance: ${distance.toStringAsFixed(2)} km\n'
          'Price: \$${price.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
