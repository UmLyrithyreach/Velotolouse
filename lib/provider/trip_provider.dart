import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:velotolouse/core/const/priceConstant.dart';
import 'package:velotolouse/data/repositories/trip/trip_abstract_repo.dart';
import 'package:velotolouse/model/trip/trip.dart';

class EndTripResult {
  final double distanceKm;
  final double price;

  EndTripResult({
    required this.distanceKm,
    required this.price,
  });
}

class TripProvider extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final TripRepository _tripRepository;

  // State variables
  List<Trip> _trips = [];
  List<Trip> _userTrips = []; // Trips for a specific user
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  List<Trip> get trips => _trips;
  List<Trip> get userTrips => _userTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  TripProvider(this._tripRepository);

  // Fetch all trips from repository (one-time fetch)
  Future<void> fetchAllTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get trips
      _trips = await _tripRepository.getAllTrips();
      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch trips: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is done
    }
  }

  // Get a single trip by ID
  Future<Trip?> fetchTripById(String tripId) async {
    try {
      return await _tripRepository.getTripById(tripId);
    } catch (e) {
      _error = 'Failed to fetch trip: $e';
      print(_error);
      return null;
    }
  }

  // Fetch all trips for a specific user
  Future<void> fetchTripsByUserId(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call repository to get user's trips
      _userTrips = await _tripRepository.getTripsByUserId(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch user trips: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new trip
  Future<void> createTrip(Trip trip) async {
    try {
      // Call repository to save trip
      await _tripRepository.createTrip(trip);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create trip: $e';
      print(_error);
      rethrow;
    }
  }

  // Start a trip for a user and return the created trip.
  Future<Trip?> startTrip({
    required String userId,
    required String bikeId,
  }) async {
    try {
      final now = DateTime.now();
      final trip = Trip(
        id: now.microsecondsSinceEpoch.toString(),
        userId: userId,
        bikeId: bikeId,
        startTime: now,
        endTime: now,
        price: 0,
      );

      await createTrip(trip);
      return trip;
    } catch (e) {
      _error = 'Failed to start trip: $e';
      notifyListeners();
      return null;
    }
  }

  // End an active trip, calculate distance and price, then save it.
  Future<EndTripResult?> endTrip({
    required String tripId,
    required String userId,
    required String bikeId,
    required DateTime startTime,
    required double startLatitude,
    required double startLongitude,
  }) async {
    try {
      double distanceKm = 0;

      try {
        // Try to get current GPS position (triggers browser prompt on web).
        final currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final distanceMeters = Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          currentPosition.latitude,
          currentPosition.longitude,
        );
        distanceKm = distanceMeters / 1000;
      } catch (_) {
        // Location unavailable (permission denied, service off, web blocked).
        // Fall back to time-based distance estimate.
        final durationMinutes =
            DateTime.now().difference(startTime).inMinutes.toDouble();
        // Assume average cycling speed of 15 km/h
        distanceKm = (durationMinutes / 60) * 15;
      }

      final totalPrice = distanceKm * PriceConstant.pricePerKm;

      final endedTrip = Trip(
        id: tripId,
        userId: userId,
        bikeId: bikeId,
        startTime: startTime,
        endTime: DateTime.now(),
        price: totalPrice,
      );

      await updateTrip(endedTrip);

      return EndTripResult(
        distanceKm: distanceKm,
        price: totalPrice,
      );
    } catch (e) {
      _error = 'Failed to end trip: $e';
      notifyListeners();
      return null;
    }
  }

  // Update existing trip
  Future<void> updateTrip(Trip trip) async {
    try {
      // Call repository to update trip
      await _tripRepository.updateTrip(trip);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update trip: $e';
      print(_error);
      rethrow;
    }
  }

  // Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      // Call repository to delete trip
      await _tripRepository.deleteTrip(tripId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete trip: $e';
      print(_error);
      rethrow;
    }
  }
}
