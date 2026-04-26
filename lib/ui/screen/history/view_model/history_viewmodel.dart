import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velotolouse/data/repositories/trip/trip_abstract_repo.dart';
import 'package:velotolouse/model/trip/trip.dart';

class HistoryViewModel extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final TripRepository _tripRepository;

  // State variables
  List<Trip> _userTrips = []; // Trips for a specific user
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  List<Trip> get userTrips => _userTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HistoryViewModel(this._tripRepository);

  // Fetch all trips for a specific user
  Future<void> fetchTripsByUserId(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get user's trips
      _userTrips = await _tripRepository.getTripsByUserId(userId);

      // Sort trips by start time (most recent first)
      _userTrips.sort((a, b) => b.startTime.compareTo(a.startTime));

      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch trip history: $e';
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
      notifyListeners();
      return null;
    }
  }

  // Format date for display (e.g., "Jan 15, 2024")
  String formatDate(DateTime date) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return dateFormat.format(date);
  }

  // Format time for display (e.g., "14:30")
  String formatTime(DateTime time) {
    final timeFormat = DateFormat('HH:mm');
    return timeFormat.format(time);
  }

  // Calculate trip duration in minutes
  int calculateDurationMinutes(Trip trip) {
    final duration = trip.endTime.difference(trip.startTime);
    return duration.inMinutes;
  }

  // Format trip duration as a readable string (e.g., "45 min" or "1h 30min")
  String formatDuration(Trip trip) {
    final minutes = calculateDurationMinutes(trip);

    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${remainingMinutes}min';
    }
  }

  // Format price for display (e.g., "$12.50")
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  // Get total amount spent by user (sum of all trip prices)
  double getTotalSpent() {
    return _userTrips.fold(0.0, (sum, trip) => sum + trip.price);
  }

  // Get total number of trips
  int getTotalTrips() {
    return _userTrips.length;
  }

  // Get total time spent riding (in minutes)
  int getTotalRidingMinutes() {
    return _userTrips.fold(
        0, (sum, trip) => sum + calculateDurationMinutes(trip));
  }

  // Filter trips by date range
  List<Trip> filterTripsByDateRange(DateTime startDate, DateTime endDate) {
    return _userTrips.where((trip) {
      return trip.startTime.isAfter(startDate) &&
          trip.startTime.isBefore(endDate);
    }).toList();
  }

  // Refresh trips (re-fetch from repository)
  Future<void> refreshTrips(String userId) async {
    await fetchTripsByUserId(userId);
  }
}
