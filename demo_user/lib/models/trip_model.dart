class Trip {
  final String id;
  final String userId;
  final String userName;
  final Location pickupLocation;
  final Location dropoffLocation;
  final TripType tripType;
  final TransportDetails transportDetails;
  final double distance; // in kilometers
  final int estimatedDuration; // in minutes
  final double fare;
  final TripStatus status;
  final DateTime createdAt;
  final String? driverId;
  final String? driverName;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.tripType,
    required this.transportDetails,
    required this.distance,
    required this.estimatedDuration,
    required this.fare,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.acceptedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'tripType': tripType.toString().split('.').last,
      'transportDetails': transportDetails.toJson(),
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'fare': fare,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'driverId': driverId,
      'driverName': driverName,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Handle both old format (string pickupLocation) and new format (Map pickupLocation)
    Location pickupLocation;
    if (json['pickupLocation'] is String) {
      // Old format: pickupLocation is a string
      pickupLocation = Location(
        latitude: json['pickupLat']?.toDouble() ?? 0.0,
        longitude: json['pickupLng']?.toDouble() ?? 0.0,
        formattedAddress: json['pickupLocation'] as String,
        placeId: 'old_pickup_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      // New format: pickupLocation is a Map
      pickupLocation = Location.fromJson(json['pickupLocation']);
    }

    // Handle both old format (string dropoffLocation) and new format (Map dropoffLocation)
    Location dropoffLocation;
    if (json['dropoffLocation'] is String) {
      // Old format: dropoffLocation is a string
      dropoffLocation = Location(
        latitude: json['dropoffLat']?.toDouble() ?? 0.0,
        longitude: json['dropoffLng']?.toDouble() ?? 0.0,
        formattedAddress: json['dropoffLocation'] as String,
        placeId: 'old_dropoff_${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      // New format: dropoffLocation is a Map
      dropoffLocation = Location.fromJson(json['dropoffLocation']);
    }

    // Handle createdAt - could be Timestamp or milliseconds
    DateTime createdAt;
    if (json['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    } else {
      // Firestore Timestamp - convert to DateTime
      try {
        final timestamp = json['createdAt'];
        if (timestamp.runtimeType.toString() == '_DocumentTimestamp') {
          createdAt = timestamp.toDate();
        } else {
          // Fallback
          createdAt = DateTime.now();
        }
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    return Trip(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      tripType: json['tripType'] != null
          ? TripType.values.firstWhere(
              (e) => e.toString().split('.').last == json['tripType'],
            )
          : TripType.objectTransport,
      transportDetails: json['transportDetails'] != null
          ? TransportDetails.fromJson(json['transportDetails'])
          : TransportDetails(),
      distance: json['distance']?.toDouble() ?? 0.0,
      estimatedDuration: json['estimatedDuration'] ?? 0,
      fare: json['fare']?.toDouble() ?? 0.0,
      status: json['status'] != null
          ? TripStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
            )
          : TripStatus.requested,
      createdAt: createdAt,
      driverId: json['driverId'],
      driverName: json['driverName'],
      acceptedAt: json['acceptedAt'] != null
          ? (json['acceptedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['acceptedAt'])
              : json['acceptedAt'].toDate())
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
              : json['completedAt'].toDate())
          : null,
    );
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String placeId;

  Location({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.placeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'placeId': placeId,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      formattedAddress: json['formattedAddress'],
      placeId: json['placeId'],
    );
  }
}

enum TripType {
  objectTransport,
  peopleTransport,
}

class TransportDetails {
  // For Object Transport
  final ObjectType? objectType;
  final String? objectDescription;
  final double? weight; // in kg
  final double? length; // in cm
  final double? width;  // in cm
  final double? height; // in cm
  final bool? isFragile;
  final String? specialInstructions;
  
  // For People Transport
  final int? numberOfPassengers;
  final List<String>? passengerNames;

  TransportDetails({
    this.objectType,
    this.objectDescription,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.isFragile,
    this.specialInstructions,
    this.numberOfPassengers,
    this.passengerNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'objectType': objectType?.toString().split('.').last,
      'objectDescription': objectDescription,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'isFragile': isFragile,
      'specialInstructions': specialInstructions,
      'numberOfPassengers': numberOfPassengers,
      'passengerNames': passengerNames,
    };
  }

  factory TransportDetails.fromJson(Map<String, dynamic> json) {
    return TransportDetails(
      objectType: json['objectType'] != null
          ? ObjectType.values.firstWhere(
              (e) => e.toString().split('.').last == json['objectType'],
            )
          : null,
      objectDescription: json['objectDescription'],
      weight: json['weight']?.toDouble(),
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      isFragile: json['isFragile'],
      specialInstructions: json['specialInstructions'],
      numberOfPassengers: json['numberOfPassengers'],
      passengerNames: List<String>.from(json['passengerNames'] ?? []),
    );
  }
}

enum ObjectType {
  document,
  package,
  furniture,
  electronics,
  clothing,
  food,
  medical,
  other,
}

enum TripStatus {
  requested,
  accepted,
  driver_arrived,
  in_progress,
  completed,
  cancelled,
}