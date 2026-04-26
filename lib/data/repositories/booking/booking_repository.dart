import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:velotolouse/data/dto/booking_dto.dart';
import 'package:velotolouse/data/firebase/firebase_config.dart';
import 'package:velotolouse/data/repositories/booking/booking_abstract_repo.dart';
import 'package:velotolouse/model/booking/booking.dart';

// Firebase Realtime Database implementation data fetching logic
class FirebaseBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getAllBookings() async {
    final uri = FirebaseConfig.buildUri('bookings.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }

      if (response.body == 'null') return [];

      final Map<String, dynamic> bookingsJson =
          jsonDecode(response.body) as Map<String, dynamic>;

      return bookingsJson.entries.map((entry) {
        final id = entry.key;
        final data = Map<String, dynamic>.from(entry.value as Map);

        // Convert date strings from Firebase into DateTime for the DTO
        data['startTime'] = DateTime.parse(data['startTime'] as String);
        data['endTime'] = DateTime.parse(data['endTime'] as String);

        return BookingDto.fromRtdb(id, data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    final uri = FirebaseConfig.buildUri('bookings/$bookingId.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load booking: ${response.statusCode}');
      }

      if (response.body == 'null') return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['startTime'] = DateTime.parse(data['startTime'] as String);
      data['endTime'] = DateTime.parse(data['endTime'] as String);

      return BookingDto.fromRtdb(bookingId, data);
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingsByUserId(String userId) async {
    try {
      final allBookings = await getAllBookings();
      return allBookings.where((booking) => booking.userId == userId).toList();
    } catch (e) {
      throw Exception('Error fetching bookings for user: $e');
    }
  }

  @override
  Future<void> createBooking(Booking booking) async {
    final uri = FirebaseConfig.buildUri('bookings/${booking.id}.json');

    try {
      final bookingData = BookingDto.toRtdb(booking);

      // Convert DateTime into string before jsonEncode
      bookingData['startTime'] = booking.startTime.toIso8601String();
      bookingData['endTime'] = booking.endTime.toIso8601String();

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final uri = FirebaseConfig.buildUri('bookings/${booking.id}.json');

    try {
      final bookingData = BookingDto.toRtdb(booking);
      bookingData['startTime'] = booking.startTime.toIso8601String();
      bookingData['endTime'] = booking.endTime.toIso8601String();

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating booking: $e');
    }
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    final uri = FirebaseConfig.buildUri('bookings/$bookingId.json');

    try {
      final response = await http.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting booking: $e');
    }
  }
}
