import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/booking/booking_abstract_repo.dart';
import 'package:velotolouse/model/booking/booking.dart';

class BookingProvider extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final BookingRepository _bookingRepository;

  // State variables
  List<Booking> _bookings = [];
  List<Booking> _userBookings = []; // Bookings for a specific user
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  List<Booking> get bookings => _bookings;
  List<Booking> get userBookings => _userBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookingProvider(this._bookingRepository);

  // Fetch all bookings from repository (one-time fetch)
  Future<void> fetchAllBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get bookings
      _bookings = await _bookingRepository.getAllBookings();
      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch bookings: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is done
    }
  }

  // Get a single booking by ID
  Future<Booking?> fetchBookingById(String bookingId) async {
    try {
      return await _bookingRepository.getBookingById(bookingId);
    } catch (e) {
      _error = 'Failed to fetch booking: $e';
      print(_error);
      return null;
    }
  }

  // Fetch all bookings for a specific user
  Future<void> fetchBookingsByUserId(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call repository to get user's bookings
      _userBookings = await _bookingRepository.getBookingsByUserId(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch user bookings: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new booking
  Future<void> createBooking(Booking booking) async {
    try {
      // Call repository to save booking
      await _bookingRepository.createBooking(booking);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create booking: $e';
      print(_error);
      rethrow;
    }
  }

  // Update existing booking
  Future<void> updateBooking(Booking booking) async {
    try {
      // Call repository to update booking
      await _bookingRepository.updateBooking(booking);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update booking: $e';
      print(_error);
      rethrow;
    }
  }

  // Delete a booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      // Call repository to delete booking
      await _bookingRepository.deleteBooking(bookingId);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete booking: $e';
      print(_error);
      rethrow;
    }
  }
}
