import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:velotolouse/core/const/priceConstant.dart';
import 'package:velotolouse/data/repositories/bike/bike_abstract_repo.dart';
import 'package:velotolouse/data/repositories/booking/booking_repository.dart';
import 'package:velotolouse/data/repositories/trip/trip_repository.dart';
import 'package:velotolouse/model/bike/bike.dart';
import 'package:velotolouse/model/booking/booking.dart';
import 'package:velotolouse/model/trip/trip.dart';
import 'package:velotolouse/model/trip/end_trip_result.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';

// BookingViewModel — handles booking screen business logic
class BookingViewModel extends ChangeNotifier {
  // Dependencies injected via constructor (manual injection)
  final FirebaseBookingRepository bookingRepository;
  final FirebaseTripRepository tripRepository;
  final BikeAbstractRepo bikeRepository;
  final AuthViewModel authViewModel;

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
    required this.bookingRepository,
    required this.tripRepository,
    required this.bikeRepository,
    required this.authViewModel,
  });

  // Getters for UI to read computed state
  bool get canStartRide => isPaymentCompleted && !isRideActive;
  bool get canEndRide => isRideActive;
  String get formattedDistance => currentDistanceKm.toStringAsFixed(2);

  // Initialize the booking screen with a selected bike (synchronous, no booking creation)
  Future<void> initializeWithBike(Bike bike) async {
    selectedBike = bike;
    isPaymentCompleted = false;
    isRideActive = false;
    isBookingCreated = true; // Skip to payment screen immediately
    currentDistanceKm = 0.0;
    errorMessage = null;
    notifyListeners();
  }

  // Proceed with KHQR payment and create booking
  Future<void> proceedWithKHQR() async {
    final user = authViewModel.currentUser;
    final bike = selectedBike;

    if (user == null || bike == null) {
      errorMessage = 'Please login first';
      notifyListeners();
      return;
    }

    try {
      // Create the booking when user proceeds with payment
      final now = DateTime.now();
      final booking = Booking(
        id: now.microsecondsSinceEpoch.toString(),
        userId: user.id,
        bikeId: bike.bikeId,
        startTime: now,
        endTime: now,
        price: 0,
      );

      await bookingRepository.createBooking(booking);

      // Update user state with active booking
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: booking.id,
        activeTripId: null,
      );

      // Update bike availability in background (fire and forget)
      bikeRepository.updateBikeAvailability(bike.bikeId, false).catchError((e) {
        print('Failed to update bike availability: $e');
        return null; // Return null on error to satisfy the return type
      });

      // Mark payment as completed
      isPaymentCompleted = true;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to create booking: $e';
      print('Booking error: $e');
      notifyListeners();
    }
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
    final user = authViewModel.currentUser;
    final activeBookingId = user?.activeBookingId;
    final bike = selectedBike;

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

    try {
      // Create trip
      final now = DateTime.now();
      final trip = Trip(
        id: now.microsecondsSinceEpoch.toString(),
        userId: user.id,
        bikeId: bike.bikeId,
        startTime: now,
        endTime: now,
        price: 0,
      );

      await tripRepository.createTrip(trip);

      // Delete the booking since ride has started
      await bookingRepository.deleteBooking(activeBookingId);

      // Update user state with active trip
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: null,
        activeTripId: trip.id,
      );

      // Start distance simulation for desktop testing
      isRideActive = true;
      startDistanceSimulation();
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to start ride: $e';
      notifyListeners();
    }
  }

  // End the active ride
  Future<EndTripResult?> endRide() async {
    final user = authViewModel.currentUser;
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

    try {
      // Fetch the active trip
      final trip = await tripRepository.getTripById(activeTripId);
      if (trip == null) {
        errorMessage = 'Unable to load active ride';
        notifyListeners();
        return null;
      }

      // Calculate distance
      double distanceKm = 0;
      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final distanceMeters = Geolocator.distanceBetween(
          bike.latitude,
          bike.longitude,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        distanceKm = distanceMeters / 1000;
      } catch (_) {
        // Fallback to time-based calculation
        final durationMinutes =
            DateTime.now().difference(trip.startTime).inMinutes.toDouble();
        distanceKm = (durationMinutes / 60) * 15;
      }

      final totalPrice = distanceKm * PriceConstant.pricePerKm;

      // Update trip
      final endedTrip = Trip(
        id: trip.id,
        userId: trip.userId,
        bikeId: trip.bikeId,
        startTime: trip.startTime,
        endTime: DateTime.now(),
        price: totalPrice,
      );

      await tripRepository.updateTrip(endedTrip);

      // Update bike availability to make it available again
      await bikeRepository.updateBikeAvailability(bike.bikeId, true);

      // Clear user's active trip
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: null,
        activeTripId: null,
      );

      // Reset ride state
      isRideActive = false;
      errorMessage = null;
      notifyListeners();

      return EndTripResult(
        distanceKm: distanceKm,
        price: totalPrice,
      );
    } catch (e) {
      errorMessage = 'Failed to end ride: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    stopDistanceSimulation();
    super.dispose();
  }
}
