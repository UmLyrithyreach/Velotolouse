class Trip {
  String id;
  String userId;
  String bikeId;
  DateTime startTime;
  DateTime endTime;
  double price;

  Trip({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.startTime,
    required this.endTime,
    required this.price,
  });

  @override
  String toString() {
    return "Trip(id: $id, userId: $userId, bikeId: $bikeId, startTime: $startTime, endTime: $endTime, price: $price)";
  }
}
