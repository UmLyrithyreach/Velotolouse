import 'package:velotolouse/model/user/user.dart';

abstract class UserRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getUser(String userId);
  Future<User?> getUserById(String userId);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String userId);
}