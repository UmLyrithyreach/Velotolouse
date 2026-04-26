
import 'package:velotolouse/model/bike/bike.dart';

class BikeDto{
  static Bike fromRtdb(String id ,Map<String, dynamic> map){
    return Bike(
      bikeId: id,
      name: map['name'],
      status: map['status'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  static Map<String, dynamic> toRtdb(Bike bike){
    return {
      'name': bike.name,
      'status': bike.status,
      'latitude': bike.latitude,
      'longitude': bike.longitude,
    };
  }
}