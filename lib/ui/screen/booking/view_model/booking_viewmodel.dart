import 'dart:async';
import 'package:flutter/material.dart';
import 'package:velotolouse/model/bike/bike.dart';
import 'package:velotolouse/provider/booking_provider.dart';
import 'package:velotolouse/provider/trip_provider.dart';
import 'package:velotolouse/provider/user_provider.dart';
import 'package:velotolouse/ui/screen/map/view_model/map_viewmodel.dart';

class BookingViewModel extends ChangeNotifier {
  // Dependencies injected via constructor (manual injection)
  final BookingProvider bookingProvider;
  final TripProvider tripProvider;
  final UserProvider userProvider;
  final MapViewModel mapViewModel;

  // State variables
  Bike? selectedBike;
  bool isPaymentCompleted = false;
  bool isRideActive = false;
  bool isBookingCreated = false;
  double currentDistanceKm = 0.0;
  String? errorMessage;
  Timer? distanceUpdateTimer;
  DateTime? rideStartTime;

  // Constructor with required dependencies
  BookingViewModel({
    required this.bookingProvider,
    required this.tripProvider,
    required this.userProvider,
    required this.mapViewModel,
  });

  // Getters for UI to read computed state
  bool get canStartRide => isPaymentCompleted && !isRideActive;
  bool get canEndRide => isRideActive;
  String get formattedDistance => currentDistanceKm.toStringAsFixed(2);

  // Initialize the booking screen with a selected bike
  Future<void> initializeWithBike(Bike bike) async {
    selectedBike = bike;
    isPaymentCompleted = false;
    isRideActive = false;
    isBookingCreated = false;
    currentDistanceKm = 0.0;
    errorMessage = null;
    notifyListeners();

    // Create a booking for this bike
    final user = userProvider.currentUser;
    if (user == null) {
      errorMessage = 'Please login first';
      notifyListeners();
      return;
    }

    // Create the booking
    final booking = await bookingProvider.bookBike(
      userId: user.id,
      bikeId: bike.bikeId,
    );

    if (booking == null) {
      errorMessage = bookingProvider.error ?? 'Failed to create booking';
      notifyListeners();
      return;
    }

    // Update bike availability
    await mapViewModel.updateBikeAvailability(bike.bikeId, false);

    // Update user state with active booking
    await userProvider.updateCurrentUserRideState(
      activeBookingId: booking.id,
      activeTripId: null,
    );

    isBookingCreated = true;
    notifyListeners();
  }

  // Proceed with KHQR payment (simulated for now)
  Future<void> proceedWithKHQR() async {
    // In real implementation, this would open KHQR app or web view
    // For now, just mark payment as completed
    isPaymentCompleted = true;
    notifyListeners();
  }

  // Start simulating distance for desktop testing
  void startDistanceSimulation() {
    rideStartTime = DateTime.now();
    currentDistanceKm = 0.0;

    // Update distance every 1 second for more responsive updates
    distanceUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        // Calculate elapsed time in seconds
        final elapsedSeconds =
            DateTime.now().difference(rideStartTime!).inSeconds.toDouble();

        // Simulate 15 km/h average cycling speed
        // 15 km/h = 15000 m/h = 250 m/min = 4.17 m/s
        currentDistanceKm = (elapsedSeconds / 3600) * 15;
        notifyListeners();
      },
    );
  }

  // Stop distance simulation
  void stopDistanceSimulation() {
    distanceUpdateTimer?.cancel();
    distanceUpdateTimer = null;
  }

  // Start a ride from the booking screen
  Future<void> startRide() async {
    final user = userProvider.currentUser;
    final activeBookingId = user?.activeBookingId;
    final bike = selectedBike;

    if (user == null) {
      errorMessage = 'Please login first';
      notifyListeners();
      return;
    }

    if (activeBookingId == null) {
      errorMessage = 'No active booking found';
      notifyListeners();
      return;
    }

    if (bike == null) {
      errorMessage = 'No bike selected';
      notifyListeners();
      return;
    }

    // Start the trip via TripProvider
    final trip = await tripProvider.startTrip(
      userId: user.id,
      bikeId: bike.bikeId,
    );

    if (trip == null) {
      errorMessage = tripProvider.error ?? 'Failed to start ride';
      notifyListeners();
      return;
    }

    // Delete the booking since ride has started
    await bookingProvider.deleteBooking(activeBookingId);

    // Update user state with active trip
    await userProvider.updateCurrentUserRideState(
      activeBookingId: null,
      activeTripId: trip.id,
    );

    // Start distance simulation for desktop testing
    isRideActive = true;
    startDistanceSimulation();
    errorMessage = null;
    notifyListeners();
  }

  // End the active ride
  Future<EndTripResult?> endRide() async {
    final user = userProvider.currentUser;
    final activeTripId = user?.activeTripId;
    final bike = selectedBike;

    if (user == null || activeTripId == null) {
      errorMessage = 'No active ride found';
      notifyListeners();
      return null;
    }

    if (bike == null) {
      errorMessage = 'No bike selected';
      notifyListeners();
      return null;
    }

    // Stop distance simulation
    stopDistanceSimulation();

    // Fetch the active trip
    final trip = await tripProvider.fetchTripById(activeTripId);
    if (trip == null) {
      errorMessage = 'Unable to load active ride';
      notifyListeners();
      return null;
    }

    // End the trip via TripProvider
    final result = await tripProvider.endTrip(
      tripId: trip.id,
      userId: trip.userId,
      bikeId: trip.bikeId,
      startTime: trip.startTime,
      startLatitude: bike.latitude,
      startLongitude: bike.longitude,
    );

    if (result == null) {
      errorMessage = tripProvider.error ?? 'Failed to end ride';
      notifyListeners();
      return null;
    }

    // Update bike availability to make it available again
    await mapViewModel.updateBikeAvailability(bike.bikeId, true);

    // Clear user's active trip
    await userProvider.updateCurrentUserRideState(
      activeBookingId: null,
      activeTripId: null,
    );

    // Reset ride state
    isRideActive = false;
    errorMessage = null;
    notifyListeners();

    return result;
  }

  @override
  void dispose() {
    stopDistanceSimulation();
    super.dispose();
  }
}
