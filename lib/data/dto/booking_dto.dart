import 'package:velotolouse/model/booking/booking.dart';

class BookingDto{
  static Booking fromRtdb(String id ,Map<String, dynamic> map){
    return Booking(
      id: id,
      userId: map['userId'],
      bikeId: map['bikeId'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      price: map['price'],
    );
  }

  static Map<String, dynamic> toRtdb(Booking booking){
    return {
      'userId': booking.userId,
      'bikeId': booking.bikeId,
      'startTime': booking.startTime,
      'endTime': booking.endTime,
      'price': booking.price,
    };
  }
}