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
  });

  // Create a ride request from a Map
  factory UserRideRequest.fromJson(Map<String, dynamic> json) {
    return UserRideRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      userRating: (json['userRating'] ?? 0.0).toDouble(),
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      offeredPrice: (json['offeredPrice'] ?? 0.0).toDouble(),
      urgency: json['urgency'] ?? 'medium',
      requestedAt: json['requestedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['requestedAt'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      driverId: json['driverId'],
      negotiatedPrice: json['negotiatedPrice']?.toDouble(),
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
    };
  }

  // Create a new ride request (for saving to database)
  UserRideRequest copyWith({
    String? status,
    String? driverId,
    double? negotiatedPrice,
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
    );
  }
}