import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:velotolouse/data/dto/user_dto.dart';
import 'package:velotolouse/data/firebase/firebase_config.dart';
import 'package:velotolouse/data/repositories/user/user_abstract_repo.dart';
import 'package:velotolouse/model/user/user.dart';

// Firebase Realtime Database implementation data getting logic
class FirebaseUserRepository implements UserRepository {
  @override
  Future<List<User>> getAllUsers() async {
    final uri = FirebaseConfig.buildUri('users.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load users: ${response.statusCode}');
      }

      if (response.body == 'null') return [];

      final Map<String, dynamic> usersJson =
          jsonDecode(response.body) as Map<String, dynamic>;

      return usersJson.entries.map((entry) {
        final id = entry.key;
        final data = Map<String, dynamic>.from(entry.value as Map);
        return UserDto.fromFirestore(id, data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    final uri = FirebaseConfig.buildUri('users/$userId.json');

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load user: ${response.statusCode}');
      }

      if (response.body == 'null') return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserDto.fromFirestore(userId, data);
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  @override
  Future<void> createUser(User user) async {
    final uri = FirebaseConfig.buildUri('users/${user.id}.json');

    try {
      final userData = UserDto.toFirestore(user);

      // Keep optional fields when writing to Firebase
      userData['activeBookingId'] = user.activeBookingId;
      userData['activeTripId'] = user.activeTripId;

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    final uri = FirebaseConfig.buildUri('users/${user.id}.json');

    try {
      final userData = UserDto.toFirestore(user);
      userData['activeBookingId'] = user.activeBookingId;
      userData['activeTripId'] = user.activeTripId;

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    final uri = FirebaseConfig.buildUri('users/$userId.json');

    try {
      final response = await http.delete(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  @override
  Future<User?> getUser(String userId) {
    return getUserById(userId);
  }
}
