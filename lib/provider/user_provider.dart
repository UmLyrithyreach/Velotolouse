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
  
  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading indicator

    try {
      // 1. Fetch all users from repository
      final users = await _userRepository.getAllUsers();
      
      // 2. Find a user that matches the email and password
      // We use collection methods to find the match. 
      // This will throw a StateError if no match is found.
      final user = users.firstWhere(
        (u) => u.email == email && u.password == password,
      );
      
      // 3. Set the current user and clear any errors
      _currentUser = user;
      _error = null;
      return true; // Login successful
    } catch (e) {
      // If firstWhere fails to find a user, it throws an error
      _error = 'Invalid email or password';
      print(_error);
      return false; // Login failed
    } finally {
      // 4. Stop loading and update UI
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<bool> register(String name, String email, String password) async {
    // Basic validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading indicator

    try {
      // 1. Fetch all users to check if email already exists
      final users = await _userRepository.getAllUsers();
      final emailExists = users.any((u) => u.email == email);
      
      if (emailExists) {
        _error = 'Email is already in use';
        return false;
      }

      // 2. Create a new User object
      // Using timestamp as a simple unique ID string
      final String newId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = User(
        id: newId,
        name: name,
        email: email,
        password: password,
      );
      
      // 3. Save the new user using the repository
      await _userRepository.createUser(newUser);
      
      // 4. Automatically log in the user after successful registration
      _currentUser = newUser;
      _error = null;
      return true; // Registration successful
    } catch (e) {
      _error = 'Registration failed: $e';
      print(_error);
      return false; // Registration failed
    } finally {
      // 5. Stop loading and update UI
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout - clear current user
  void logout() {
    _currentUser = null;
    notifyListeners(); // Notify UI to update state
  }

  // Update active booking/trip IDs for the current user.
  Future<void> updateCurrentUserRideState({
    String? activeBookingId,
    String? activeTripId,
  }) async {
    final user = _currentUser;
    if (user == null) return;

    final updatedUser = User(
      id: user.id,
      name: user.name,
      email: user.email,
      password: user.password,
      activeBookingId: activeBookingId,
      activeTripId: activeTripId,
    );

    await updateUser(updatedUser);
  }
}
