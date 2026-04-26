import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:velotolouse/data/dto/trip_dto.dart';
import 'package:velotolouse/data/firebase/firebase_config.dart';
import 'package:velotolouse/data/repositories/trip/trip_abstract_repo.dart';
import 'package:velotolouse/model/trip/trip.dart';

// Firebase Realtime Database implementation data getting logic
class FirebaseTripRepository implements TripRepository {
  @override
  Future<List<Trip>> getAllTrips() async {
    final uri = FirebaseConfig.buildUri('trips.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load trips: ${response.statusCode}');
      }

      if (response.body == 'null') return [];

      final Map<String, dynamic> tripsJson =
          jsonDecode(response.body) as Map<String, dynamic>;

      return tripsJson.entries.map((entry) {
        final id = entry.key;
        final data = Map<String, dynamic>.from(entry.value as Map);

        // Convert date strings from Firebase into DateTime for the DTO
        data['startTime'] = DateTime.parse(data['startTime'] as String);
        data['endTime'] = DateTime.parse(data['endTime'] as String);

        return TripDto.fromRtdb(id, data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching trips: $e');
    }
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    final uri = FirebaseConfig.buildUri('trips/$tripId.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load trip: ${response.statusCode}');
      }

      if (response.body == 'null') return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['startTime'] = DateTime.parse(data['startTime'] as String);
      data['endTime'] = DateTime.parse(data['endTime'] as String);

      return TripDto.fromRtdb(tripId, data);
    } catch (e) {
      throw Exception('Error fetching trip: $e');
    }
  }

  @override
  Future<List<Trip>> getTripsByUserId(String userId) async {
    try {
      final allTrips = await getAllTrips();
      return allTrips.where((trip) => trip.userId == userId).toList();
    } catch (e) {
      throw Exception('Error fetching trips for user: $e');
    }
  }

  @override
  Future<void> createTrip(Trip trip) async {
    final uri = FirebaseConfig.buildUri('trips/${trip.id}.json');

    try {
      final tripData = TripDto.toRtdb(trip);

      // Convert DateTime into string before jsonEncode
      tripData['startTime'] = trip.startTime.toIso8601String();
      tripData['endTime'] = trip.endTime.toIso8601String();

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tripData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final uri = FirebaseConfig.buildUri('trips/${trip.id}.json');

    try {
      final tripData = TripDto.toRtdb(trip);
      tripData['startTime'] = trip.startTime.toIso8601String();
      tripData['endTime'] = trip.endTime.toIso8601String();

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(tripData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating trip: $e');
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final uri = FirebaseConfig.buildUri('trips/$tripId.json');

    try {
      final response = await http.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting trip: $e');
    }
  }
}
