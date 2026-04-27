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

// Map ViewModel — handles bike fetching and filtering logic
class MapViewModel extends ChangeNotifier {
  // Repositories and ViewModels injected via constructor
  final BikeAbstractRepo _bikeRepository;
  final FirebaseBookingRepository _bookingRepository;
  final FirebaseTripRepository _tripRepository;

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

  MapViewModel(
    this._bikeRepository,
    this._bookingRepository,
    this._tripRepository, AuthViewModel read,
  );

  // Fetch all bikes from repository
  Future<void> fetchAllBikes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bikes = await _bikeRepository.getAllBikes();
      print('Fetched ${_bikes.length} bikes'); // Debug log
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch bikes: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
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
    return _bikes
        .where((bike) => bike.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter bikes by status
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
      final updatedBike =
          await _bikeRepository.updateBikeAvailability(bikeId, isAvailable);

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

  // Refresh bikes
  Future<void> refreshBikes() async {
    await fetchAllBikes();
  }

  // Clear action message
  void clearActionMessage() {
    _actionMessage = null;
    notifyListeners();
  }

  // Clear last end-trip result
  void clearLastEndTripResult() {
    _lastEndTripResult = null;
    notifyListeners();
  }

  // Consume one-time message
  String? consumeActionMessage() {
    final message = _actionMessage;
    _actionMessage = null;
    return message;
  }

  // Consume one-time end-trip result
  EndTripResult? consumeLastEndTripResult() {
    final result = _lastEndTripResult;
    _lastEndTripResult = null;
    return result;
  }

  // Decide whether the Book button should show
  bool canBookBike({
    required Bike bike,
    required AuthViewModel authViewModel,
  }) {
    final user = authViewModel.currentUser;
    final hasActiveBooking = user?.activeBookingId != null;
    final hasActiveTrip = user?.activeTripId != null;
    return !hasActiveBooking && !hasActiveTrip && bike.status == 'available';
  }

  // Decide whether the Start Ride button should show
  bool canStartRide(AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    final hasActiveBooking = user?.activeBookingId != null;
    final hasActiveTrip = user?.activeTripId != null;
    return hasActiveBooking && !hasActiveTrip;
  }

  // Decide whether the End Ride button should show
  bool canEndRide(AuthViewModel authViewModel) {
    final user = authViewModel.currentUser;
    return user?.activeTripId != null;
  }

  // Book a selected bike for the current user
  Future<void> bookBike({
    required Bike bike,
    required AuthViewModel authViewModel,
  }) async {
    final user = authViewModel.currentUser;
    if (user == null) {
      _actionMessage = 'Please login first';
      notifyListeners();
      return;
    }

    try {
      // Create booking
      final now = DateTime.now();
      final booking = Booking(
        id: now.microsecondsSinceEpoch.toString(),
        userId: user.id,
        bikeId: bike.bikeId,
        startTime: now,
        endTime: now,
        price: 0,
      );

      await _bookingRepository.createBooking(booking);

      // Update bike availability
      await updateBikeAvailability(bike.bikeId, false);

      // Update user state
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: booking.id,
        activeTripId: null,
      );

      await fetchAllBikes();

      _actionMessage = 'Bike booked successfully';
      notifyListeners();
    } catch (e) {
      _actionMessage = 'Booking failed: $e';
      notifyListeners();
    }
  }

  // Start a trip from the active booking
  Future<void> startRide({
    required Bike bike,
    required AuthViewModel authViewModel,
  }) async {
    final user = authViewModel.currentUser;
    final activeBookingId = user?.activeBookingId;
    if (user == null || activeBookingId == null) {
      _actionMessage = 'No active booking found';
      notifyListeners();
      return;
    }

    try {
      // Verify booking exists and matches bike
      final booking = await _bookingRepository.getBookingById(activeBookingId);
      if (booking == null || booking.bikeId != bike.bikeId) {
        _actionMessage = 'Please tap your booked bike to start';
        notifyListeners();
        return;
      }

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

      await _tripRepository.createTrip(trip);

      // Delete booking
      await _bookingRepository.deleteBooking(activeBookingId);

      // Update user state
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: null,
        activeTripId: trip.id,
      );

      _actionMessage = 'Ride started';
      notifyListeners();
    } catch (e) {
      _actionMessage = 'Failed to start ride: $e';
      notifyListeners();
    }
  }

  // End the active trip
  Future<void> endRide({
    required AuthViewModel authViewModel,
  }) async {
    final user = authViewModel.currentUser;
    final activeTripId = user?.activeTripId;
    if (user == null || activeTripId == null) {
      _actionMessage = 'No active ride found';
      notifyListeners();
      return;
    }

    try {
      // Fetch trip
      final trip = await _tripRepository.getTripById(activeTripId);
      if (trip == null) {
        _actionMessage = 'Unable to load active ride';
        notifyListeners();
        return;
      }

      // Find bike
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

      // Calculate distance
      double distanceKm = 0;
      try {
        final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final distanceMeters = Geolocator.distanceBetween(
          startBike.latitude,
          startBike.longitude,
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

      await _tripRepository.updateTrip(endedTrip);

      // Update bike availability
      await updateBikeAvailability(trip.bikeId, true);

      // Clear user state
      await authViewModel.updateCurrentUserRideState(
        activeBookingId: null,
        activeTripId: null,
      );

      await fetchAllBikes();

      _lastEndTripResult = EndTripResult(
        distanceKm: distanceKm,
        price: totalPrice,
      );
      _actionMessage = 'Ride completed';
      notifyListeners();
    } catch (e) {
      _actionMessage = 'Failed to end ride: $e';
      notifyListeners();
    }
  }
}
