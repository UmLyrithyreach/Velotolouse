import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:velotolouse/data/dto/bike_dto.dart';
import 'package:velotolouse/data/firebase/firebase_config.dart';
import 'package:velotolouse/data/repositories/bike/bike_abstract_repo.dart';
import 'package:velotolouse/model/bike/bike.dart';

// Firebase Realtime Database implementation using HTTP REST (consistent with other repos)
class BikeRepositoryFirebase implements BikeAbstractRepo {
  @override
  Future<List<Bike>> getAllBikes() async {
    final uri = FirebaseConfig.buildUri('bikes.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load bikes: ${response.statusCode}');
      }

      if (response.body == 'null') return [];

      final Map<String, dynamic> bikesJson =
          jsonDecode(response.body) as Map<String, dynamic>;

      return bikesJson.entries.map((entry) {
        final id = entry.key; // id comes first (key)
        final data = Map<String, dynamic>.from(entry.value as Map);
        return BikeDto.fromFireStore(id, data); // fixed: was (e.value, e.key)
      }).toList();
    } catch (e) {
      throw Exception('Error fetching bikes: $e');
    }
  }

  @override
  Future<Bike?> getBike(String bikeId) async { // fixed: was missing 'async' and body
    final uri = FirebaseConfig.buildUri('bikes/$bikeId.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load bike: ${response.statusCode}');
      }

      if (response.body == 'null') return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BikeDto.fromFireStore(bikeId, data);
    } catch (e) {
      throw Exception('Error fetching bike: $e');
    }
  }

  @override
  Future<Bike?> updateBikeAvailability(String bikeId, bool status) async {
    final uri = FirebaseConfig.buildUri('bikes/$bikeId.json');

    try {
      // Convert bool to status string that matches the Bike model
      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status ? 'available' : 'unavailable'}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update bike availability: ${response.statusCode}');
      }

      // Fetch and return the updated bike
      return await getBike(bikeId);
    } catch (e) {
      throw Exception('Error updating bike availability: $e');
    }
  }

  @override
  Stream<List<Bike>> watchBikes() {
    // watchBikes is not used by BikeProvider — HTTP REST does not support streaming
    throw UnimplementedError('watchBikes is not supported with HTTP REST');
  }
}
