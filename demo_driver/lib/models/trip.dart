class Trip {
  final String id;
  final String userId;
  final String userName;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double fare;
  final String status; // requested, accepted, driver_arrived, in_progress, completed, cancelled
  final DateTime? createdAt;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final int? estimatedArrivalTime; // in minutes
  final DateTime? acceptedAt;
  final DateTime? driverArrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  Trip({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.fare,
    required this.status,
    this.createdAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.estimatedArrivalTime,
    this.acceptedAt,
    this.driverArrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'fare': fare,
      'status': status,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'estimatedArrivalTime': estimatedArrivalTime,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'driverArrivedAt': driverArrivedAt?.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      pickupLocation: json['pickupLocation'],
      dropoffLocation: json['dropoffLocation'],
      pickupLat: json['pickupLat']?.toDouble() ?? 0.0,
      pickupLng: json['pickupLng']?.toDouble() ?? 0.0,
      dropoffLat: json['dropoffLat']?.toDouble() ?? 0.0,
      dropoffLng: json['dropoffLng']?.toDouble() ?? 0.0,
      fare: json['fare']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'requested',
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
      estimatedArrivalTime: json['estimatedArrivalTime'],
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['acceptedAt'])
          : null,
      driverArrivedAt: json['driverArrivedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['driverArrivedAt'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['cancelledAt'])
          : null,
    );
  }
}