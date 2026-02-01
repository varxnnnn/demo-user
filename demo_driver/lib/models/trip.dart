class Trip {
  final String id;
  final String driverId;
  final String userId;
  final String userName;
  final String pickupLocation;
  final String dropoffLocation;
  final double fare;
  final String status; // requested, accepted, picked_up, completed, cancelled
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.driverId,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.fare,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'fare': fare,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'pickedUpAt': pickedUpAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      driverId: json['driverId'],
      userId: json['userId'],
      userName: json['userName'],
      pickupLocation: json['pickupLocation'],
      dropoffLocation: json['dropoffLocation'],
      fare: json['fare'],
      status: json['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['acceptedAt'])
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['pickedUpAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
    );
  }
}