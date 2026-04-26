import 'package:velotolouse/model/trip/trip.dart';

class TripDto {
  static Trip fromRtdb(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,
      userId: map['userId'],
      bikeId: map['bikeId'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      price: map['price'],
    );
  }

  static Map<String, dynamic> toRtdb(Trip trip) {
    return {
      'userId': trip.userId,
      'bikeId': trip.bikeId,
      'startTime': trip.startTime,
      'endTime': trip.endTime,
      'price': trip.price,
    };
  }
}