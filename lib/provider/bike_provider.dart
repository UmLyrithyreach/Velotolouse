import 'package:flutter/material.dart';
import 'package:velotolouse/data/repositories/bike/bike_abstract_repo.dart';
import 'package:velotolouse/model/bike/bike.dart';

import 'package:velotolouse/data/seed/bike_seed.dart';

class BikeProvider extends ChangeNotifier {
  // Repository injected via constructor (manual injection, no get_it)
  final BikeAbstractRepo _bikeRepository;

  // State variables
  List<Bike> _bikes = [];
  bool _isLoading = false;
  String? _error;

  // Getters for UI to read state (read-only access)
  List<Bike> get bikes => _bikes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BikeProvider(this._bikeRepository);

  // Fetch all bikes from repository
  Future<void> fetchAllBikes() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI to show loading

    try {
      // Call repository to get bikes
      _bikes = await _bikeRepository.getAllBikes();
      
      // seed bike
      if (_bikes.isEmpty) {
        await _bikeRepository.seedBikes(BikeSeed.bikes);
        _bikes = await _bikeRepository.getAllBikes();
      }
      
      _error = null;
    } catch (e) {
      // Store error message if something fails
      _error = 'Failed to fetch bikes: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is done
    }
  }

  // Get a single bike by ID
  Future<Bike?> fetchBikeById(String bikeId) async {
    try {
      return await _bikeRepository.getBike(bikeId);
    } catch (e) {
      _error = 'Failed to fetch bike: $e';
      print(_error);
      return null;
    }
  }

  // Update bike availability
  Future<void> updateBikeAvailability(String bikeId, bool status) async {
    try {
      // Call repository to update bike availability
      final updatedBike = await _bikeRepository.updateBikeAvailability(bikeId, status);

      // Update bike in local list if it exists
      if (updatedBike != null) {
        final index = _bikes.indexWhere((b) => b.bikeId == bikeId);
        if (index != -1) {
          _bikes[index] = updatedBike;
          notifyListeners();
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to update bike availability: $e';
      print(_error);
      rethrow;
    }
  }
}
