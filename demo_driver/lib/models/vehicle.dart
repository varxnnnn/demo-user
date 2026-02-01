class Vehicle {
  final String id;
  final String driverId;
  final String vehicleType;
  final String brand;
  final String model;
  final String registrationNumber;
  final String rcBookUrl;
  final String vehicleImageUrl;
  final bool isVerified;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.registrationNumber,
    required this.rcBookUrl,
    required this.vehicleImageUrl,
    required this.isVerified,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'registrationNumber': registrationNumber,
      'rcBookUrl': rcBookUrl,
      'vehicleImageUrl': vehicleImageUrl,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      driverId: json['driverId'],
      vehicleType: json['vehicleType'],
      brand: json['brand'],
      model: json['model'],
      registrationNumber: json['registrationNumber'],
      rcBookUrl: json['rcBookUrl'] ?? '',
      vehicleImageUrl: json['vehicleImageUrl'] ?? '',
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}