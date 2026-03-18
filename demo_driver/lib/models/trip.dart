import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Trip.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Trip(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      pickupLat: (json['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (json['pickupLng'] ?? 0.0).toDouble(),
      dropoffLat: (json['dropoffLat'] ?? 0.0).toDouble(),
      dropoffLng: (json['dropoffLng'] ?? 0.0).toDouble(),
      fare: (json['fare'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'requested',
      createdAt: _parseDateTime(json['createdAt']),
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
      estimatedArrivalTime: json['estimatedArrivalTime'],
      acceptedAt: _parseDateTime(json['acceptedAt']),
      driverArrivedAt: _parseDateTime(json['driverArrivedAt']),
      startedAt: _parseDateTime(json['startedAt']),
      completedAt: _parseDateTime(json['completedAt']),
      cancelledAt: _parseDateTime(json['cancelledAt']),
    );
  }
}