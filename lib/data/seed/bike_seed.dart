import 'package:velotolouse/model/bike/bike.dart';

class BikeSeed {
  static final List<Bike> bikes = [
    Bike(
      bikeId: 'bike_001',
      name: 'My Bike01',
      status: 'available',
      latitude: 11.5564,
      longitude: 104.9282, // Central Market
    ),
    Bike(
      bikeId: 'bike_002',
      name: 'My Brike02',
      status: 'available',
      latitude: 11.5645,
      longitude: 104.9351, // Riverside
    ),
    Bike(
      bikeId: 'bike_003',
      name: 'My Bike03',
      status: 'available',
      latitude: 11.5512,
      longitude: 104.9250, // BKK1
    ),
    Bike(
      bikeId: 'bike_004',
      name: 'My Bike04',
      status: 'available',
      latitude: 11.5494,
      longitude: 104.9176, // Tuol Sleng
    ),
    Bike(
      bikeId: 'bike_005',
      name: 'My Bike05',
      status: 'available',
      latitude: 11.5760,
      longitude: 104.9230, // Wat Phnom
    ),
  ];
}
