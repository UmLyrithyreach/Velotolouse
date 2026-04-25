import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/user/user_abstract_repo.dart';
import 'package:velotolouse/model/user/user.dart';

class UserProvider extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final UserRepository _userRepository;

  // State variables
  List<User> _users = [];
  User? _currentUser; // Currently logged-in user
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider(this._userRepository);

  // Fetch all users from repository (one-time fetch)
  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get users
      _users = await _userRepository.getAllUsers();
      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch users: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is done
    }
  }

  // Get a single user by ID
  Future<User?> fetchUserById(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      _error = 'Failed to fetch user: $e';
      print(_error);
      return null;
    }
  }

  // Set current user (for login flow)
  Future<void> setCurrentUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch user from repository
      final user = await _userRepository.getUser(userId);
      _currentUser = user;
      _error = null;
    } catch (e) {
      _error = 'Failed to load user: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new user (registration)
  Future<void> createUser(User user) async {
    try {
      // Call repository to save user
      await _userRepository.createUser(user);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create user: $e';
      print(_error);
      rethrow;
    }
  }

  // Update existing user
  Future<void> updateUser(User user) async {
    try {
      // Call repository to update user
      await _userRepository.updateUser(user);

      // Update current user if it's the same
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user: $e';
      print(_error);
      rethrow;
    }
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      // Call repository to delete user
      await _userRepository.deleteUser(userId);

      // Clear current user if it's the same
      if (_currentUser?.id == userId) {
        _currentUser = null;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete user: $e';
      print(_error);
      rethrow;
    }
  }

  // Logout - clear current user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
