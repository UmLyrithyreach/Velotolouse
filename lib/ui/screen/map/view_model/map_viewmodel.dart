import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/bike/bike_abstract_repo.dart';
import 'package:velotolouse/model/bike/bike.dart';
import 'package:velotolouse/provider/booking_provider.dart';
import 'package:velotolouse/provider/trip_provider.dart';
import 'package:velotolouse/provider/user_provider.dart';

class MapViewModel extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final BikeAbstractRepo _bikeRepository;

  // State variables
  List<Bike> _bikes = [];
  bool _isLoading = false;
  String? _error;
  String? _actionMessage;
  EndTripResult? _lastEndTripResult;

  // Getters for UI to read state (read-only access)
  List<Bike> get bikes => _bikes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionMessage => _actionMessage;
  EndTripResult? get lastEndTripResult => _lastEndTripResult;

  MapViewModel(this._bikeRepository);

  // Fetch all bikes from repository
  Future<void> fetchAllBikes() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get bikes
      _bikes = await _bikeRepository.getAllBikes();
      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch bikes: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is done
    }
  }

  // Get a single bike by ID
  Future<Bike?> fetchBikeById(String bikeId) async {
    try {
      return await _bikeRepository.getBike(bikeId);
    } catch (e) {
      _error = 'Failed to fetch bike: $e';
      print(_error);
      notifyListeners();
      return null;
    }
  }

  // Filter bikes by name (search functionality)
  List<Bike> filterBikesByName(String query) {
    if (query.isEmpty) return _bikes;

    // Filter bikes where name contains the search query (case-insensitive)
    return _bikes
        .where((bike) => bike.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter bikes by status (available or unavailable)
  List<Bike> filterBikesByStatus(String status) {
    return _bikes.where((bike) => bike.status == status).toList();
  }

  // Get only available bikes
  List<Bike> getAvailableBikes() {
    return _bikes.where((bike) => bike.status == 'available').toList();
  }

  // Update bike availability
  Future<void> updateBikeAvailability(String bikeId, bool isAvailable) async {
    try {
      // Call repository to update bike availability
      final updatedBike =
          await _bikeRepository.updateBikeAvailability(bikeId, isAvailable);

      // Update bike in local list if it exists
      if (updatedBike != null) {
        final index = _bikes.indexWhere((b) => b.bikeId == bikeId);
        if (index != -1) {
          _bikes[index] = updatedBike;
          notifyListeners();
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to update bike availability: $e';
      print(_error);
      notifyListeners();
      rethrow;
    }
  }

  // Refresh bikes (re-fetch from repository)
  Future<void> refreshBikes() async {
    await fetchAllBikes();
  }

  // Clear the one-time action message after UI shows it.
  void clearActionMessage() {
    _actionMessage = null;
    notifyListeners();
  }

  // Clear last end-trip result after dialog is shown.
  void clearLastEndTripResult() {
    _lastEndTripResult = null;
    notifyListeners();
  }

  // Consume one-time message for UI feedback.
  String? consumeActionMessage() {
    final message = _actionMessage;
    _actionMessage = null;
    return message;
  }

  // Consume one-time end-trip result for UI dialog.
  EndTripResult? consumeLastEndTripResult() {
    final result = _lastEndTripResult;
    _lastEndTripResult = null;
    return result;
  }

  // Decide whether the Book button should show.
  bool canBookBike({
    required Bike bike,
    required UserProvider userProvider,
  }) {
    final user = userProvider.currentUser;
    final hasActiveBooking = user?.activeBookingId != null;
    final hasActiveTrip = user?.activeTripId != null;
    return !hasActiveBooking && !hasActiveTrip && bike.status == 'available';
  }

  // Decide whether the Start Ride button should show.
  bool canStartRide(UserProvider userProvider) {
    final user = userProvider.currentUser;
    final hasActiveBooking = user?.activeBookingId != null;
    final hasActiveTrip = user?.activeTripId != null;
    return hasActiveBooking && !hasActiveTrip;
  }

  // Decide whether the End Ride button should show.
  bool canEndRide(UserProvider userProvider) {
    final user = userProvider.currentUser;
    return user?.activeTripId != null;
  }

  // Book a selected bike for the current user.
  Future<void> bookBike({
    required Bike bike,
    required BookingProvider bookingProvider,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    if (user == null) {
      _actionMessage = 'Please login first';
      notifyListeners();
      return;
    }

    final booking = await bookingProvider.bookBike(
      userId: user.id,
      bikeId: bike.bikeId,
    );

    if (booking == null) {
      _actionMessage = bookingProvider.error ?? 'Booking failed';
      notifyListeners();
      return;
    }

    await updateBikeAvailability(bike.bikeId, false);
    await userProvider.updateCurrentUserRideState(
      activeBookingId: booking.id,
      activeTripId: null,
    );
    await fetchAllBikes();

    _actionMessage = 'Bike booked successfully';
    notifyListeners();
  }

  // Start a trip from the active booking.
  Future<void> startRide({
    required Bike bike,
    required BookingProvider bookingProvider,
    required TripProvider tripProvider,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    final activeBookingId = user?.activeBookingId;
    if (user == null || activeBookingId == null) {
      _actionMessage = 'No active booking found';
      notifyListeners();
      return;
    }

    final booking = await bookingProvider.fetchBookingById(activeBookingId);
    if (booking == null || booking.bikeId != bike.bikeId) {
      _actionMessage = 'Please tap your booked bike to start';
      notifyListeners();
      return;
    }

    final trip = await tripProvider.startTrip(
      userId: user.id,
      bikeId: bike.bikeId,
    );
    if (trip == null) {
      _actionMessage = tripProvider.error ?? 'Failed to start ride';
      notifyListeners();
      return;
    }

    await bookingProvider.deleteBooking(activeBookingId);
    await userProvider.updateCurrentUserRideState(
      activeBookingId: null,
      activeTripId: trip.id,
    );

    _actionMessage = 'Ride started';
    notifyListeners();
  }

  // End the active trip and store result for UI dialog.
  Future<void> endRide({
    required TripProvider tripProvider,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    final activeTripId = user?.activeTripId;
    if (user == null || activeTripId == null) {
      _actionMessage = 'No active ride found';
      notifyListeners();
      return;
    }

    final trip = await tripProvider.fetchTripById(activeTripId);
    if (trip == null) {
      _actionMessage = 'Unable to load active ride';
      notifyListeners();
      return;
    }

    Bike? startBike;
    for (final bike in _bikes) {
      if (bike.bikeId == trip.bikeId) {
        startBike = bike;
        break;
      }
    }

    if (startBike == null) {
      _actionMessage = 'Unable to find bike location';
      notifyListeners();
      return;
    }

    final result = await tripProvider.endTrip(
      tripId: trip.id,
      userId: trip.userId,
      bikeId: trip.bikeId,
      startTime: trip.startTime,
      startLatitude: startBike.latitude,
      startLongitude: startBike.longitude,
    );
    if (result == null) {
      _actionMessage = tripProvider.error ?? 'Failed to end ride';
      notifyListeners();
      return;
    }

    await updateBikeAvailability(trip.bikeId, true);
    await userProvider.updateCurrentUserRideState(
      activeBookingId: null,
      activeTripId: null,
    );
    await fetchAllBikes();

    _lastEndTripResult = result;
    _actionMessage = 'Ride completed';
    notifyListeners();
  }
}
