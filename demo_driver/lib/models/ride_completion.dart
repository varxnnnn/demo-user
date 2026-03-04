/// Models for ride completion and rating system

class RideCompletionDetails {
  final String tripId;
  final String driverId;
  final String userId;
  final double baseFare;
  final double additionalCharges; // For damages, etc.
  final double discount;
  final double totalFare;
  final String paymentMethod; // 'cash', 'card', 'wallet'
  final bool paymentReceived;
  final DateTime completedAt;
  final String completionNotes;
  final String? proofPhotoUrl;

  RideCompletionDetails({
    required this.tripId,
    required this.driverId,
    required this.userId,
    required this.baseFare,
    this.additionalCharges = 0.0,
    this.discount = 0.0,
    required this.totalFare,
    required this.paymentMethod,
    required this.paymentReceived,
    required this.completedAt,
    this.completionNotes = '',
    this.proofPhotoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'driverId': driverId,
      'userId': userId,
      'baseFare': baseFare,
      'additionalCharges': additionalCharges,
      'discount': discount,
      'totalFare': totalFare,
      'paymentMethod': paymentMethod,
      'paymentReceived': paymentReceived,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'completionNotes': completionNotes,
      'proofPhotoUrl': proofPhotoUrl,
    };
  }

  factory RideCompletionDetails.fromJson(Map<String, dynamic> json) {
    return RideCompletionDetails(
      tripId: json['tripId'] ?? '',
      driverId: json['driverId'] ?? '',
      userId: json['userId'] ?? '',
      baseFare: (json['baseFare'] ?? 0).toDouble(),
      additionalCharges: (json['additionalCharges'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentReceived: json['paymentReceived'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : DateTime.now(),
      completionNotes: json['completionNotes'] ?? '',
      proofPhotoUrl: json['proofPhotoUrl'],
    );
  }
}

class Rating {
  final String id;
  final String rideId;
  final String ratedBy; // 'driver' or 'user'
  final String ratedUserId; // The person being rated
  final double rating; // 1-5 stars
  final String review;
  final List<String> tags; // 'cleanliness', 'professionalism', 'safety', etc.
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.rideId,
    required this.ratedBy,
    required this.ratedUserId,
    required this.rating,
    required this.review,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'ratedBy': ratedBy,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'review': review,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? '',
      rideId: json['rideId'] ?? '',
      ratedBy: json['ratedBy'] ?? '',
      ratedUserId: json['ratedUserId'] ?? '',
      rating: (json['rating'] ?? 3.0).toDouble(),
      review: json['review'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class TripReceipt {
  final String tripId;
  final String driverId;
  final String driverName;
  final String userId;
  final String userName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime startTime;
  final DateTime endTime;
  final double distance; // in km
  final double fare;
  final String paymentMethod;
  final List<String>? pooledUserIds; // For pooled rides
  final int? passengerCount;

  TripReceipt({
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.fare,
    required this.paymentMethod,
    this.pooledUserIds,
    this.passengerCount,
  });

  String getDuration() {
    final duration = endTime.difference(startTime);
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours h $remainingMinutes m';
    } else {
      return '$remainingMinutes m';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'driverId': driverId,
      'driverName': driverName,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'distance': distance,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'pooledUserIds': pooledUserIds,
      'passengerCount': passengerCount,
    };
  }

  factory TripReceipt.fromJson(Map<String, dynamic> json) {
    return TripReceipt(
      tripId: json['tripId'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      dropoffLocation: json['dropoffLocation'] ?? '',
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'])
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : DateTime.now(),
      distance: (json['distance'] ?? 0).toDouble(),
      fare: (json['fare'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'cash',
      pooledUserIds: json['pooledUserIds'] != null
          ? List<String>.from(json['pooledUserIds'])
          : null,
      passengerCount: json['passengerCount'],
    );
  }
}

class PooledRideGroup {
  final String poolingKey;
  final List<String> tripIds; // All trips in this pool
  final List<String> userIds; // All users in this pool
  final String driverId;
  final double baseFarePerRide; // Original individual fare
  final double poolDiscount; // Percentage discount for pooling (e.g., 20%)
  final Map<String, double> individualFares; // userId -> fare
  final List<String> pickupOrder; // Order to pick up users
  final List<String> dropoffOrder; // Order to drop off users
  final DateTime createdAt;
  final String status; // 'active', 'completed', 'cancelled'

  PooledRideGroup({
    required this.poolingKey,
    required this.tripIds,
    required this.userIds,
    required this.driverId,
    required this.baseFarePerRide,
    required this.poolDiscount,
    required this.individualFares,
    required this.pickupOrder,
    required this.dropoffOrder,
    required this.createdAt,
    this.status = 'active',
  });

  int get passengerCount => userIds.length;

  Map<String, dynamic> toJson() {
    return {
      'poolingKey': poolingKey,
      'tripIds': tripIds,
      'userIds': userIds,
      'driverId': driverId,
      'baseFarePerRide': baseFarePerRide,
      'poolDiscount': poolDiscount,
      'individualFares': individualFares,
      'pickupOrder': pickupOrder,
      'dropoffOrder': dropoffOrder,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory PooledRideGroup.fromJson(Map<String, dynamic> json) {
    return PooledRideGroup(
      poolingKey: json['poolingKey'] ?? '',
      tripIds: List<String>.from(json['tripIds'] ?? []),
      userIds: List<String>.from(json['userIds'] ?? []),
      driverId: json['driverId'] ?? '',
      baseFarePerRide: (json['baseFarePerRide'] ?? 0).toDouble(),
      poolDiscount: (json['poolDiscount'] ?? 0).toDouble(),
      individualFares: Map<String, double>.from(
        (json['individualFares'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
            ) ??
            {},
      ),
      pickupOrder: List<String>.from(json['pickupOrder'] ?? []),
      dropoffOrder: List<String>.from(json['dropoffOrder'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      status: json['status'] ?? 'active',
    );
  }
}
