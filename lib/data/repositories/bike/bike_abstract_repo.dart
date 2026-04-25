import 'package:velotolouse/model/bike/bike.dart';

abstract class BikeAbstractRepo {
  Future<List<Bike>> getAllBikes();
  Future<Bike?> getBike(String bikeId);
  Future<Bike?> updateBikeAvailability(String bikeId, bool status);
  Stream<List<Bike>> watchBikes();
}