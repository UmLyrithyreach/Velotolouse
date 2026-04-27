import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/user/user_abstract_repo.dart';
import 'package:velotolouse/model/user/user.dart';

class AuthViewModel extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final UserRepository _userRepository;

  // State variables
  User? _currentUser; // Currently logged-in user
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthViewModel(this._userRepository);

  // Login — validates credentials and sets current user
  Future<bool> login(String email, String password) async {
    // Clear previous error
    _error = null;

    // Validate input fields
    if (email.isEmpty || password.isEmpty) {
      _error = 'Email and password cannot be empty';
      notifyListeners();
      return false;
    }

    // Basic email format validation
    if (!email.contains('@')) {
      _error = 'Please enter a valid email';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners(); // Notify UI to show loading

    try {
      // Fetch all users from repository
      final users = await _userRepository.getAllUsers();

      // Find user with matching email and password
      final user = users.firstWhere(
        (u) => u.email == email && u.password == password,
        orElse: () => throw Exception('Invalid email or password'),
      );

      // Set current user if found
      _currentUser = user;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Store error message if login fails
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register — creates a new user account
  Future<bool> register(String name, String email, String password) async {
    // Clear previous error
    _error = null;

    // Validate input fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'All fields are required';
      notifyListeners();
      return false;
    }

    // Basic email format validation
    if (!email.contains('@')) {
      _error = 'Please enter a valid email';
      notifyListeners();
      return false;
    }

    // Password length validation
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners(); // Notify UI to show loading

    try {
      // Check if email already exists
      final users = await _userRepository.getAllUsers();
      final emailExists = users.any((u) => u.email == email);

      if (emailExists) {
        throw Exception('Email already registered');
      }

      // Generate a unique ID for the new user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create new user object
      final newUser = User(
        id: userId,
        name: name,
        email: email,
        password: password,
        activeBookingId: null,
        activeTripId: null,
      );

      // Save user to repository
      await _userRepository.createUser(newUser);

      // Set as current user
      _currentUser = newUser;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Store error message if registration fails
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout — clear current user
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
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

    await updateCurrentUser(updatedUser);
  }

  // Update current user (for updating active booking/trip)
  Future<void> updateCurrentUser(User user) async {
    try {
      // Call repository to update user
      await _userRepository.updateUser(user);

      // Update current user in memory
      _currentUser = user;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user: $e';
      notifyListeners();
      rethrow;
    }
  }
}
