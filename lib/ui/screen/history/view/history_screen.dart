import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';
import 'package:velotolouse/ui/screen/history/view_model/history_viewmodel.dart';
import 'package:velotolouse/model/trip/trip.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch trips for the current user when the screen loads
    Future.microtask(() {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) {
        context.read<HistoryViewModel>().fetchTripsByUserId(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the trip provider so UI rebuilds when state changes
    final historyViewModel = context.watch<HistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
      ),
      body: _buildBody(historyViewModel),
    );
  }

  // Build the body based on loading/error/data state
  Widget _buildBody(HistoryViewModel historyViewModel) {
    // Show loading spinner while fetching
    if (historyViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if something went wrong
    if (historyViewModel.error != null) {
      return Center(
        child: Text(
          historyViewModel.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // Show message if no trips found
    if (historyViewModel.userTrips.isEmpty) {
      return const Center(
        child: Text(
          'No trips yet. Start riding!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Show list of trip cards
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyViewModel.userTrips.length,
      itemBuilder: (context, index) {
        final trip = historyViewModel.userTrips[index];
        return _buildTripCard(trip);
      },
    );
  }

  // Build a card for a single trip
  Widget _buildTripCard(Trip trip) {
    // Format dates for display
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Calculate trip duration in minutes
    final duration = trip.endTime.difference(trip.startTime);
    final minutes = duration.inMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(trip.startTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Trip price
                Text(
                  '\$${trip.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bike ID
            Text('Bike: ${trip.bikeId}'),
            const SizedBox(height: 4),

            // Time range and duration
            Text(
              '${timeFormat.format(trip.startTime)} - ${timeFormat.format(trip.endTime)} ($minutes min)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
