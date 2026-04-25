import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/trip/trip_abstract_repo.dart';
import 'package:velotolouse/model/trip/trip.dart';

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
