class Vehicle {
  late String status;
  late String time;
  String timeOut = "";
  late String userRfId;
  late String vehiclePlate;

  Vehicle({
    required this.userRfId,
    required this.vehiclePlate,
    required this.status,
    required this.time,
  });
}
