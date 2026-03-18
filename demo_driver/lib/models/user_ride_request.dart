import 'package:cloud_firestore/cloud_firestore.dart';

class UserRideRequest {
  final String id;
  final String userId;
  final String userName;
  final double userRating;
  final String pickupLocation;
  final String dropoffLocation;
  final double distance;
  final double offeredPrice;
  final String urgency; // low, medium, high
  final DateTime requestedAt;
  final String status; // pending, accepted, rejected, negotiating, completed
  final String? driverId;
  final double? negotiatedPrice;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  UserRideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRating,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distance,
    required this.offeredPrice,
    required this.urgency,
    required this.requestedAt,
    this.status = 'pending',
    this.driverId,
    this.negotiatedPrice,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  // Create a ride request from a Map
  factory UserRideRequest.fromJson(Map<String, dynamic> json, {String? id}) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return UserRideRequest(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userRating: (json['userRating'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      offeredPrice: (json['offeredPrice'] ?? 0.0).toDouble(),
      urgency: json['urgency'] ?? 'medium',
      requestedAt: _parseDateTime(json['requestedAt']) ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      driverId: json['driverId'],
      negotiatedPrice: json['negotiatedPrice']?.toDouble(),
      pickupLat: json['pickupLat']?.toDouble(),
      pickupLng: json['pickupLng']?.toDouble(),
      dropoffLat: json['dropoffLat']?.toDouble(),
      dropoffLng: json['dropoffLng']?.toDouble(),
    );
  }

  // Convert ride request to a Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRating': userRating,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'distance': distance,
      'offeredPrice': offeredPrice,
      'urgency': urgency,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
      'status': status,
      'driverId': driverId,
      'negotiatedPrice': negotiatedPrice,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
    };
  }

  // Create a new ride request (for saving to database)
  UserRideRequest copyWith({
    String? status,
    String? driverId,
    double? negotiatedPrice,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
  }) {
    return UserRideRequest(
      id: this.id,
      userId: this.userId,
      userName: this.userName,
      userRating: this.userRating,
      pickupLocation: this.pickupLocation,
      dropoffLocation: this.dropoffLocation,
      distance: this.distance,
      offeredPrice: this.offeredPrice,
      urgency: this.urgency,
      requestedAt: this.requestedAt,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      negotiatedPrice: negotiatedPrice ?? this.negotiatedPrice,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
    );
  }
}