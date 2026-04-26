class Bike {
  final String bikeId;
  final String name;
  final String status;
  final double latitude;
  final double longitude;

  Bike({
    required this.bikeId,
    required this.name,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return "Bike(bikeId: $bikeId, name: $name, status: $status, latitude: $latitude, longitude: $longitude)";
  }
}
